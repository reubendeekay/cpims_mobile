import 'package:cpims_mobile/Models/caseplan_form_model.dart';
import 'package:cpims_mobile/Models/unapproved_caseplan_form_model.dart';
import 'package:cpims_mobile/constants_prod.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../constants.dart';
import '../screens/cpara/model/cpara_model.dart';

class UnapprovedCptProvider {
  Future<void> createTable(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS unapproved_cpt (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        form_uuid TEXT NOT NULL,
        ovc_cpims_id TEXT NOT NULL,
        date_of_event TEXT NOT NULL,
        form_date_synced TEXT NULL,
        message TEXT NOT NULL
      )
    ''');
  }

  Future<void> insertUnapprovedCasePlanData(
      Database db, UnapprovedCasePlanModel unapprovedCasePlan) async {
    try {
      // Check if data already exists
      final existingData = await db.query(
        "unapproved_cpt",
        where: 'form_uuid = ?',
        whereArgs: [unapprovedCasePlan.formUuid],
      );

      // If data does not exist, insert it
      if (existingData.isEmpty) {
        // insert data into table
        await db.transaction((txn) async {
          final unapprovedCasePlanId = await txn.insert(
            "unapproved_cpt",
            {
              "form_uuid": unapprovedCasePlan.formUuid,
              "ovc_cpims_id": unapprovedCasePlan.ovcCpimsId,
              "date_of_event": unapprovedCasePlan.dateOfEvent,
              "form_date_synced": null,
              "message": unapprovedCasePlan.message,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );

          for (var service in unapprovedCasePlan.services) {
            final serviceIdList = service.serviceIds.join(',');
            final responsibleIdList = service.responsibleIds.join(',');

            await txn.insert("case_plan_services", {
              'unapproved_form_id': unapprovedCasePlanId,
              'domain_id': service.domainId,
              'goal_id': service.goalId,
              'gap_id': service.gapId,
              'priority_id': service.priorityId,
              'results_id': service.resultsId,
              'reason_id': service.reasonId,
              'completion_date': service.completionDate ?? '',
              'service_ids': serviceIdList,
              'responsible_ids': responsibleIdList,
            });
          }
        });
        //update upstream that form has been cached locally
        var prefs = await SharedPreferences.getInstance();
        var accessToken = prefs.getString('access');
        String bearerAuth = "Bearer $accessToken";
        var response = await dio.post(
          "${cpimsProdApiUrl}mobile/record_saved",
          options: Options(headers: {"Authorization": bearerAuth}),
          data: {
            "record_id": unapprovedCasePlan.formUuid,
            "saved": 1,
            "form_type": "cpt"
          },
        );
        if (response.statusCode == 200) {
          if (kDebugMode) {
            print('Record saved successfully');
          }
        } else {
          if (kDebugMode) {
            print('Record not saved');
          }
        }
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error inserting unapproved case plan: $e');
      }
      if (kDebugMode) {
        print('Stack trace: $stackTrace');
      }
    }
  }

  // function to get all unapproved caseplan data
  Future<List<UnapprovedCasePlanModel>> getAllUnapprovedCasePlanData(
      Database db) async {
    try {
      final res = await db.rawQuery('''
  SELECT * FROM unapproved_cpt
''');

      List<UnapprovedCasePlanModel> unapprovedCasePlanList = [];

      for (var result in res) {
        final unapprovedCasePlanId = result['id'];

        final serviceRes = await db.rawQuery('''
      SELECT * FROM case_plan_services WHERE unapproved_form_id = $unapprovedCasePlanId
    ''');

        List<CasePlanServiceModel> serviceList = [];
        for (var service in serviceRes) {
          serviceList.add(CasePlanServiceModel(
            domainId: service['domain_id'] as String? ?? '',
            serviceIds: (service['service_ids'] as String?)?.split(',') ?? [],
            goalId: service['goal_id'] as String? ?? '',
            gapId: service['gap_id'] as String? ?? '',
            priorityId: service['priority_id'] as String? ?? '',
            responsibleIds:
                (service['responsible_ids'] as String?)?.split(',') ?? [],
            resultsId: service['results_id'] as String? ?? '',
            reasonId: service['reason_id'] as String? ?? '',
            completionDate: service['completion_date'] as String? ?? '',
          ));
        }

        unapprovedCasePlanList.add(UnapprovedCasePlanModel(
          caregiverCpimsId: result['caregiver_cpims_id'] as String? ?? '',
          id: result['id'] as int? ?? 0,
          formUuid: result['form_uuid'] as String? ?? '',
          ovcCpimsId: result['ovc_cpims_id'] as String? ?? '',
          dateOfEvent: result['date_of_event'] as String? ?? '',
          services: serviceList,
          message: result['message'] as String? ?? '',
        ));
      }
      return unapprovedCasePlanList;
    } catch (e) {
      if (kDebugMode) {
        print('Error retrieving unapproved plans: $e');
      }
      return [];
    }
  }

// function to delete unapproved caseplan data
  Future<bool> deleteUnapprovedCasePlanData(Database db, int id) async {
    try {
      int deletedRows1 =
          await db.delete('unapproved_cpt', where: 'id = ?', whereArgs: [id]);
      int deletedRows2 = await db.delete('case_plan_services',
          where: 'unapproved_form_id = ?', whereArgs: [id]);
      return deletedRows1 > 0 && deletedRows2 > 0;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting case plan: $e');
      }
      return false;
    }
  }

  Future<bool> deleteUnapprovedCasePlanDataByUuid(
      Database db, String uuid) async {
    try {
      final formQuery = await db.query(
        'unapproved_cpt',
        where: 'ovc_cpims_id = ?',
        whereArgs: [uuid],
      );

      if (formQuery.isEmpty) {
        return false;
      }

      final formId = formQuery.first['id'];

      // Delete the form using the ID
      int deletedRows1 = await db
          .delete('unapproved_cpt', where: 'id = ?', whereArgs: [formId]);
      int deletedRows2 = await db.delete('case_plan_services',
          where: 'unapproved_form_id = ?', whereArgs: [formId]);
      return deletedRows1 > 0 && deletedRows2 > 0;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting case plan: $e');
      }
      return false;
    }
  }
}
