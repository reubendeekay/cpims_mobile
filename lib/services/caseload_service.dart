import 'package:cpims_mobile/Models/case_load_model.dart';
import 'package:cpims_mobile/constants.dart' as consts;
import 'package:cpims_mobile/constants_prod.dart';
import 'package:cpims_mobile/providers/db_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/auth_provider.dart';

class CaseLoadService {
  static const String _caseLoadLastSavePrefKey = 'caseload_last_save';

  static Future<void> saveCaseLoadLastSave(int timestamp) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(_caseLoadLastSavePrefKey, timestamp);
  }

  static Future<int> getCaseLoadLastSave() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getInt(_caseLoadLastSavePrefKey) ?? 0;
  }

  Future<void> fetchCaseLoadData({
    required BuildContext context,
    required String deviceID,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final int caseloadLastSave = await CaseLoadService.getCaseLoadLastSave();
    final int currentTimestamp = DateTime.now().millisecondsSinceEpoch;
    final int diff = currentTimestamp - caseloadLastSave;

    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SpinKitFadingCircle(
                  itemBuilder: (BuildContext context, int index) {
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        color: index.isEven ? Colors.red : Colors.green,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16), // Add some spacing
                const Text(
                  "Setting up your device. Please be patient...",
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      );
    }
    if (diff < 1000 * 3600 * 24 * 30) {
      // Todo: 30 days = 1000 * 3600 * 24 * 30 milliseconds
      print("CaseLoadService not sync");
      Navigator.of(context).pop();
      return;
    }
    print("CaseLoadService sync");

    final dio = Dio();
    final options = BaseOptions(
      baseUrl: cpimsProdApiUrl,
      headers: {
        'Authorization': 'Bearer ${preferences.getString('access')}',
      },
    );
    dio.options = options;
    dio.interceptors.add(LogInterceptor());

    try {
      final Response response =
          await dio.get('api/caseload', queryParameters: {'deviceID': deviceID});

      int statusCode = response.statusCode ?? 0;

      if (statusCode == 200) {
        final List<CaseLoadModel> caseLoadModelList = (response.data as List)
            .map((json) => CaseLoadModel.fromJson(json))
            .toList();

        if (kDebugMode) {
          print("CaseLoadService count: ${caseLoadModelList.length}");
        }
        await LocalDb.instance.deleteAllCaseLoad();
        // Insert the list of CaseLoadModel instances in a single batch
        await LocalDb.instance.insertMultipleCaseLoad(caseLoadModelList);

        final int timestamp = DateTime.now().millisecondsSinceEpoch;
        await CaseLoadService.saveCaseLoadLastSave(timestamp);
        await preferences.setBool("hasUserSetup", true);
      } else if (statusCode >= 251 && statusCode <= 256) {
        if (context.mounted) {
          errorSnackBar(context, 'Not authorized to view this resource');
        }
        await LocalDb.instance.deleteDb();
        await AuthProvider.setAppLock(true);
        return;
      } else {
        if (kDebugMode) {
          print("We have an issue");
          await preferences.setBool("hasUserSetup", false);
        }
        if (context.mounted) {
          await preferences.setBool("hasUserSetup", false);
        }
      }
    } catch (e) {
      await preferences.setBool("hasUserSetup", false);
      if (context.mounted) {
        errorSnackBar(context, e.toString());
      }
    } finally {
      Navigator.of(context).pop(); // Dismiss the loading indicator
    }
  }

  Future<void> updateCaseLoadData({
    required BuildContext context,
    required String deviceID,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final dio = Dio();
    final options = BaseOptions(
      baseUrl: cpimsProdApiUrl,
      headers: {
        'Authorization': 'Bearer ${preferences.getString('access')}',
      },
    );
    dio.options = options;
    dio.interceptors.add(LogInterceptor());

    try {
      final Response response = await dio
          .get('caseload', queryParameters: {'deviceID': deviceID});

      if (response.statusCode == 200) {
        final List<CaseLoadModel> caseLoadModelList = (response.data as List)
            .map((json) => CaseLoadModel.fromJson(json))
            .toList();

        if (kDebugMode) {
          print("CaseLoadService count: ${caseLoadModelList.length}");
        }

        // Update the list of CaseLoadModel instances in a single batch
        await LocalDb.instance.updateMultipleCaseLoad(caseLoadModelList);
      } else {
        if (kDebugMode) {
          print("We have an issue");
        }
      }
    } catch (e) {
      if (context.mounted) {
        errorSnackBar(context, e.toString());
      }
    }
  }
}
