import 'dart:convert';
import 'package:cpims_mobile/Models/unapproved_caseplan_form_model.dart';
import 'package:cpims_mobile/Models/unapproved_form_1_model.dart';
import 'package:cpims_mobile/providers/cpara/unapproved_cpara_database.dart';
import 'package:cpims_mobile/providers/cpara/unapproved_cpara_service.dart';
import 'package:cpims_mobile/screens/cpara/cpara_util.dart';
import 'package:cpims_mobile/screens/cpara/model/unnaproved_cpara_database_model.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import '../providers/db_provider.dart';

// import '../screens/cpara/widgets/cpara_details_widget.dart';
import '../providers/unapproved_cpt_provider.dart';
import 'api_service.dart';

const String _formType1A = "form1a";
const String _formType1B = "form1b";

var dio = Dio();

class UnapprovedDataService {
  static Future<void> fetchRemoteUnapprovedData(access) async {
    var endpoints = [
      "mobile/unaccepted_records/F1A/",
      "mobile/unaccepted_records/F1B/",
      "mobile/unaccepted_records/cpt/",
      "mobile/unaccepted_records/cpara/",
      "mobile/unaccepted_records/hmf/",
      "mobile/unaccepted_records/hrs/",
    ];

    List<Future<void>> futures = endpoints.map((endpoint) async {
      final db = LocalDb.instance;
      var response = await ApiService().getSecureData(endpoint, access);
      final List<dynamic> jsonData = json.decode(response.body);

      if (endpoint == endpoints[0]) {
        for (var map in jsonData) {
          final unapprovedForm1A = UnapprovedForm1DataModel.fromJson(map);
          db.insertUnapprovedForm1Data(_formType1A, unapprovedForm1A,
              unapprovedForm1A.appFormMetaData, unapprovedForm1A.formUuid);
        }
      } else if (endpoint == endpoints[1]) {
        for (var map in jsonData) {
          final unapprovedForm1B = UnapprovedForm1DataModel.fromJson(map);
          db.insertUnapprovedForm1Data(_formType1B, unapprovedForm1B,
              unapprovedForm1B.appFormMetaData, unapprovedForm1B.formUuid);
        }
      } else if (endpoint == endpoints[2]) {
        for (var map in jsonData) {
          print("Unapproved CPT Data: $map");
          final unapprovedCptData = UnapprovedCasePlanModel.fromJson(map);
          final unapprovedCpt = UnapprovedCptProvider();
          var localdb = await db.database;
          unapprovedCpt.insertUnapprovedCasePlanData(
              localdb, unapprovedCptData);
        }
      } else if (endpoint == endpoints[3]) {
        var info = await fetchRemoteUnapprovedCparaData(baseUrl: endpoint);
        List<UnapprovedCparaDatabase> listOfUnaprovedCparas =
            listOfUnapprovedCparas(remoteData: info);
        // Expects a map i.e decoded JSON
        for (UnapprovedCparaDatabase unapprovedCpara in listOfUnaprovedCparas) {
          UnapprovedCparaModel model =
              fetchUnaprovedCpara(cparaDatabase: unapprovedCpara);

          // Insert UnapprovedCparaModel
          var localDB = await db.database;

          // Check if form has already been stored in db
          var fetchResult = await localDB.rawQuery(
              "SELECT * FROM UnapprovedCPARA WHERE id = ?", [model.uuid]);

          if (fetchResult == null || fetchResult.isEmpty) {
            try {
              await UnapprovedCparaService.storeInDB(
                localDB,
                model,
              );
            } catch (e) {
              UnapprovedCparaService.informUpstreamOfStoredUnapproved(
                  model.uuid, false);
            }
          }
          // Tell Upstream that I have stored the form
          UnapprovedCparaService.informUpstreamOfStoredUnapproved(
              model.uuid, true);
        }
      } else if (endpoint == endpoints[4]) {
        //   //fetch unapproved hmf
      } else if (endpoint == endpoints[5]) {
        //fetch unapproved hrs
      }
      return;
    }).toList();

    await Future.wait(futures);
    return;
  }

  static Future<List<UnapprovedForm1DataModel>>
      fetchLocalUnapprovedForm1AData() async {
    final db = LocalDb.instance;
    List<Map<String, dynamic>> maps =
        await db.queryAllUnapprovedForm1Rows(_formType1A);
    List<UnapprovedForm1DataModel> unapprovedForm1Data = [];
    for (var map in maps) {
      unapprovedForm1Data.add(UnapprovedForm1DataModel.fromJsonUnApproved(map));
    }
    return unapprovedForm1Data;
  }

  static Future<List<UnapprovedForm1DataModel>>
      fetchLocalUnapprovedForm1BData() async {
    final db = LocalDb.instance;
    List<Map<String, dynamic>> maps =
        await db.queryAllUnapprovedForm1Rows(_formType1B);
    List<UnapprovedForm1DataModel> unapprovedForm1Data = [];
    for (var map in maps) {
      unapprovedForm1Data.add(UnapprovedForm1DataModel.fromJsonUnApproved(map));
    }
    return unapprovedForm1Data;
  }

  static Future<List<UnapprovedCparaDatabase>>
      fetchLocalUnapprovedCparaData() async {
    final db = LocalDb.instance;
    return await UnapprovedDataService.fetchLocalUnapprovedCparaData();
  }

  static Future<dynamic> fetchRemoteUnapprovedCparaData({
    required String baseUrl,
  }) async {
    var prefs = await SharedPreferences.getInstance();
    var accessToken = prefs.getString('access');
    String bearerAuth = "Bearer $accessToken";
    var response = await dio.get("$cpimsApiUrl$baseUrl",
        options: Options(headers: {"Authorization": bearerAuth}));

    if (response.statusCode == 200) {
      return response.data;
    } else {
      throw ("Could not fetch unapproved cparas");
    }
  }

  static Future<List<UnapprovedCasePlanModel>>
      fetchLocalUnapprovedCasePlanData() async {
    final db = LocalDb.instance;
    final unapprovedCpt = UnapprovedCptProvider();
    var localdb = await db.database;
    List<UnapprovedCasePlanModel> unapprovedCptList =
        await unapprovedCpt.getAllUnapprovedCasePlanData(localdb);
    return unapprovedCptList;
  }

  static Future<bool> deleteUnapprovedForm1(int id) async {
    final db = LocalDb.instance;
    return await db.deleteUnApprovedForm1Data(id);
  }

  static Future<bool> deleteUnapprovedCpt(int id) async {
    final db = LocalDb.instance;
    final unapprovedCpt = UnapprovedCptProvider();
    var localdb = await db.database;
    return await unapprovedCpt.deleteUnapprovedCasePlanData(localdb, id);
  }
}
