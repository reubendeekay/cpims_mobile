import 'dart:convert';

import 'package:cpims_mobile/Models/caseplan_form_model.dart';
import 'package:cpims_mobile/constants_prod.dart';
import 'package:cpims_mobile/providers/db_provider.dart';
import 'package:cpims_mobile/screens/cpara/model/db_model.dart';
import 'package:cpims_mobile/screens/cpara/provider/db_util.dart';
import 'package:cpims_mobile/services/form_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../constants.dart';
import '../providers/connection_provider.dart';

abstract class SyncUpstream {
  Future<void> submitCparaToUpstream();

  Future<void> postCasePlansToServer();

  Future<void> postFormOneToServer();

  Future<void> syncHRSFormData();

  Future<void> syncHMFFormData();

  Future<void> syncGraduationFormData();

  Future<void> updateFormCasePlanDateSync(int formId, Database db);

  Future<bool> syncWorkflows();
}

class SyncUpstreamImpl implements SyncUpstream {
  final BuildContext context;

  Dio dio = Dio();

  SyncUpstreamImpl({required this.context});

  @override
  Future<void> submitCparaToUpstream() async {
    var prefs = await SharedPreferences.getInstance();
    var accessToken = prefs.getString('access');

    if (accessToken == null) {
      throw Exception("Bearer token is null");
    }

    String bearerAuth = "Bearer $accessToken";

    Database database = await LocalDb.instance.database;
    List<CPARADatabase> cparaFormsInDb = await getUnsyncedForms(database);

    for (CPARADatabase cparaForm in cparaFormsInDb) {
      try {
        await singleCparaFormSubmission(
            cparaForm: cparaForm, authorization: bearerAuth);
        updateFormDateSynced(cparaForm.cparaFormId, database);
      } catch (e) {
        debugPrint(
            "Cpara form with ovs cpims id : ${cparaForm.ovcCpimsId} failed submission to upstream");
        continue;
      }
    }
  }

  @override
  Future<void> postCasePlansToServer() async {
    List<Map<String, dynamic>> caseplanFromDbData =
        await CasePlanService.getAllCasePlans();
    List<CasePlanModel> caseplanFromDb =
        caseplanFromDbData.map((map) => CasePlanModel.fromJson(map)).toList();

    var prefs = await SharedPreferences.getInstance();
    var accessToken = prefs.getString('access');

    if (accessToken == null) {
      throw Exception("Bearer token is null");
    }

    String bearerAuth = "Bearer $accessToken";
    dio.interceptors.add(LogInterceptor());
    Database db = await LocalDb.instance.database;

    for (var caseplan in caseplanFromDb) {
      var payload = caseplan.toJson();
      try {
        const cptEndpoint = "mobile/cpt/";
        var response = await dio.post("$cpimsProdApiUrl$cptEndpoint",
            data: payload,
            options: Options(headers: {"Authorization": bearerAuth}));

        if (response.statusCode == 201) {
          updateFormCasePlanDateSync(caseplan.id!, db);
          debugPrint("Data posted  successfully to server is $payload");
        } else if (response.statusCode == 403) {
          throw Exception("Session expired");
        }
      } catch (e) {
        debugPrint("Failed to post caseplan to server: $e");
      }
    }
  }

  @override
  Future<void> postFormOneToServer() async {
    var prefs = await SharedPreferences.getInstance();
    var accessToken = prefs.getString('access');

    if (accessToken == null) {
      throw Exception("Bearer token is null");
    }

    List<Map<String, String>> formsList = [
      {'formType': 'form1a', 'endpoint': 'F1A'},
      {'formType': 'form1b', 'endpoint': 'F1B'},
    ];

    try {
      for (var formType in formsList) {
        List<dynamic> forms = await Form1Service.getAllForms(
          formType['formType']!,
        );

        for (var formData in forms) {
          var response = await Form1Service.postFormRemote(
            formData,
            formType['endpoint'] ?? '',
            accessToken,
          );
          if (response.statusCode == 201) {
            debugPrint("Data to sync is $formData");
            await Form1Service.updateFormLocalDateSync(
              formType['formType']!,
              formData.localId,
            );
          } else if (response.statusCode == 403) {
            throw Exception("Session expired");
          } else {
            debugPrint(
                "Failed to sync ${formType['formType']} and error is ${response.data}");
          }
        }
      }
    } catch (e) {
      debugPrint("Failed to sync form1 data: $e");
    }
  }

  @override
  Future<void> syncHRSFormData() async {
    var prefs = await SharedPreferences.getInstance();
    var bearerToken = prefs.getString('access');

    if (bearerToken == null) {
      throw Exception("Bearer token is null");
    }
    final db = LocalDb.instance;
    try {
      final queryResults = await db.fetchHRSFormData();
      dio.options.headers['Authorization'] = 'Bearer $bearerToken';
      dio.interceptors.add(LogInterceptor());

      // Submit data
      for (final formData in queryResults) {
        debugPrint("The form data is ${jsonEncode(formData)}");
        try {
          final response =
              await dio.post('${cpimsProdApiUrl}mobile/hrs/', data: formData);
          if (kDebugMode) {
            print(response.toString());
          }

          if (response.statusCode == 201) {
            await db.updateHRSData(formData['uuid']);
          }
        } catch (error) {
          // Handle the error, you may want to retry or log it
          if (kDebugMode) {
            print(error);
          }
        }
      }
    } catch (e) {
      // Handle the error, you may want to retry or log it
      if (kDebugMode) {
        print(e);
      }
    }
  }

  @override
  Future<void> syncHMFFormData() async {
    var prefs = await SharedPreferences.getInstance();
    var bearerToken = prefs.getString('access');

    if (bearerToken == null) {
      throw Exception("Bearer token is null");
    }
    final db = LocalDb.instance;
    try {
      final queryResults = await db.fetchHMFFormData();
      dio.options.headers['Authorization'] = 'Bearer $bearerToken';
      dio.interceptors.add(LogInterceptor());

      // Submit data
      for (final formData in queryResults) {
        debugPrint("The hmf form data is ${jsonEncode(formData)}");
        try {
          final response =
              await dio.post('${cpimsProdApiUrl}mobile/hmf/', data: formData);
          if (kDebugMode) {
            print(response.toString());
          }

          if (response.statusCode == 201) {
            await db.updateHMFData(formData['uuid']);
          }
        } catch (error) {
          // Handle the error, you may want to retry or log it
          if (kDebugMode) {
            print(error);
          }
        }
      }
    } catch (e) {
      // Handle the error, you may want to retry or log it
      if (kDebugMode) {
        print(e);
      }
    }
  }

  @override
  Future<void> syncGraduationFormData() async {
    var prefs = await SharedPreferences.getInstance();
    var bearerToken = prefs.getString('access');

    if (bearerToken == null) {
      throw Exception("Bearer token is null");
    }

    final db = LocalDb.instance;
    try {
      final queryResults = await db.fetchGraduationMonitoringData();
      dio.options.headers['Authorization'] = 'Bearer $bearerToken';
      dio.interceptors.add(LogInterceptor());

      // Submit data
      for (final formData in queryResults) {
        debugPrint("The graduation data is ${jsonEncode(formData)}");
        try {
          final response = await dio
              .post('${cpimsProdApiUrl}mobile/grad_monitor/', data: formData);
          if (kDebugMode) {
            print(response.toString());
          }

          if (response.statusCode == 201) {
            await db.updateGraduationData(formData['uuid']);
          }
        } catch (error) {
          if (kDebugMode) {
            print(error);
          }
        }
      }
    } catch (e) {
      // Handle the error, you may want to retry or log it
      if (kDebugMode) {
        print(e);
      }
    }
  }

  @override
  Future<void> updateFormCasePlanDateSync(int formId, Database db) async {
    db = await LocalDb.instance.database;
    try {
      final queryResults = await db.query(
        casePlanTable,
        where: '${CasePlan.id} = ?',
        whereArgs: [formId],
      );

      if (queryResults.isNotEmpty) {
        final caseplanData = queryResults.first[CasePlan.id] as int;
        await db.update(
          casePlanTable,
          {
            'form_date_synced': DateTime.now().toString(),
          },
          where: '${CasePlan.id} = ?',
          whereArgs: [caseplanData],
        );
      }
    } catch (e) {
      debugPrint("Error updating caseplan data: $e");
    }
  }

  @override
  Future<bool> syncWorkflows() async {
    try {
      final isConnected =
          await Provider.of<ConnectivityProvider>(context, listen: false)
              .checkInternetConnection();
      final db = LocalDb.instance;
      if (isConnected) {
        // sync all records upstream
        await Future.wait([
          submitCparaToUpstream(),
          postCasePlansToServer(),
          postFormOneToServer(),
          syncHRSFormData(),
          syncHMFFormData(),
          syncGraduationFormData(),
        ]);

        // purge the database
        await db.clearAllTables();

        return true;
      } else {
        throw Exception("No internet connection");
      }
    } catch (e) {
      debugPrint("Error syncing workflows: $e");
      return false;
    }
  }
}
