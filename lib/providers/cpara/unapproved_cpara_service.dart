import 'package:cpims_mobile/constants_prod.dart';
import 'package:cpims_mobile/providers/cpara/read_unapproved_cpara_from_db.dart';
import 'package:cpims_mobile/providers/cpara/unapproved_cpara_database.dart';
import 'package:cpims_mobile/screens/cpara/model/cpara_question_ids.dart';
import 'package:cpims_mobile/screens/cpara/model/ovc_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../constants.dart';
import '../db_provider.dart';

var dio = Dio();

class UnapprovedCparaService {
  static Future<void> storeInDB(Database db, UnapprovedCparaModel model) async {
    try {
      Map<String, dynamic> json = {};
      List questions = [];

      // Get questions from health
      // Convert health to JSON
      var healthJSON = model.health.toJSON();
      // Remove health children
      var healtChildren = healthJSON.remove('children');

      // Get questions from detail
      var detailJSON = model.detail.toJSON();

      // Get questions from ovc subpopulation
      for (CparaOvcChild child
          in model.ovcSubPopulations.childrenQuestions ?? []) {
        var subpopulationquestions = _cparaovcchildtojson(child, model.uuid);
        questions.addAll(subpopulationquestions);
      }

      // Get questions from safe
      var safeJSON = model.safe.toJSON();
      List<Map<String, dynamic>> safeChildren = safeJSON.remove('children');

      // Get questions from schooled
      var schooledJSON = model.schooled.toJSON();

      // Get questions from stable
      var stableJSON = model.stable.toJSON();

      json.addAll(healthJSON);
      json.addAll(detailJSON);
      json.addAll(safeJSON);
      json.addAll(schooledJSON);
      json.addAll(stableJSON);

      // Loop through keys of JSON and and add to questions list
      json.forEach((key, value) {
        questions.add({
          "question_code": key,
          "answer_id": value,
          "ovc_cpims_id": model.cpmis_id,
          "form_id": model.uuid
        });
      });

      /// Add health children
      for (Map i in healtChildren) {
        // getting data for each child

        i.forEach((key, value) {
          if (key != "id") {
            questions.add({
              "question_code": key,
              "answer_id": value,
              "ovc_cpims_id": i['id'],
              "form_id": model.uuid
            });
          }
        });
      }

      /// Add safe children
      for (Map i in safeChildren) {
        // getting data for each child
        i.forEach((key, value) {
          if (key != "id") {
            questions.add({
              "question_code": key,
              "answer_id": value,
              "ovc_cpims_id": i['id'],
              "form_id": model.uuid
            });
          }
        });
      }

      // Add CPARA form
      if (model.uuid == "") {
        var uuid = const Uuid();
        var formID = uuid.v4();
        model.uuid = formID;
      }
      db.insert("UnapprovedCPARA", {
        "id": model.uuid,
        "date_of_event": model.detail.dateOfAssessment,
        "message": model.message,
        "ovc_id": model.cpmis_id,
      });

      // Add questions to DB
      var batch = db.batch();
      for (Map question in questions) {
        batch.insert("UnapprovedCPARAAnswers", {
          "question_code": question['question_code'],
          "answer_id": question['answer_id'],
          "ovc_cpims_id": question['ovc_cpims_id'],
          "form_id": model.uuid
        });
      }
      await batch.commit(noResult: true);
    } catch (err) {
      debugPrint(err.toString());
      throw (cannot_store_unapproved_cpara);
    }
  }

  static deleteUnapprovedCparaForm(String formID) async {
    try {
      var db = await LocalDb.instance.database;

      // Delete CPARA table
      db.rawQuery("DELETE FROM UnapprovedCPARA WHERE id = ?", [formID]);

      // Delete entries for unapproved table
      db.rawQuery(
          "DELETE FROM UnapprovedCPARAAnswers WHERE form_id = ? ", [formID]);
    } catch (err) {
      if (kDebugMode) {
        print(err.toString());
      }
      throw "Could Not Delete Unapproved CPARA";
    }
  }

  static Future<List<UnapprovedCparaModel>> getUnapprovedFromDB() async {
    var unapprovedForms = await fetchUnapprovedCparaForms();
    List<UnapprovedCparaModel> formsToBeReturned = [];

    for (Map i in unapprovedForms) {
      var id = i['id'] ?? "";
      var message = i['message'] ?? "";
      var ovcId = i['ovc_id'] ?? "";
      var dateOfEvent = i['date_of_event'] ?? "";
      formsToBeReturned
          .add(await getUnaprovedCparaFromDb(id, message, ovcId, dateOfEvent));
    }
    return formsToBeReturned;
  }

  static List _cparaovcchildtojson(CparaOvcChild child, String formId) {
    // For each question return entry
    var entries = [];
    var baseJSON = {"ovc_cpims_id": child.ovcId, "form_id": formId};

    if (child.question1 != null && child.question1?.isNotEmpty == true) {
      var question1 = baseJSON;
      question1.addAll({"question_code": CparaRemoteQuestionIds.ovcQuestion1});
      question1.addAll({"answer_id": child.question1});
      entries.add(question1);
    }

    if (child.question2 != null && child.question2?.isNotEmpty == true) {
      var question2 = {"ovc_cpims_id": child.ovcId, "form_id": formId};
      question2.addAll({"question_code": CparaRemoteQuestionIds.ovcQuestion2});
      question2.addAll({"answer_id": child.question2});
      entries.add(question2);
    }

    if (child.question3 != null && child.question3?.isNotEmpty == true) {
      var question3 = {"ovc_cpims_id": child.ovcId, "form_id": formId};
      question3.addAll({"question_code": CparaRemoteQuestionIds.ovcQuestion3});
      question3.addAll({"answer_id": child.question3});
      entries.add(question3);
    }

    if (child.question4 != null && child.question4?.isNotEmpty == true) {
      var question4 = {"ovc_cpims_id": child.ovcId, "form_id": formId};
      question4.addAll({"question_code": CparaRemoteQuestionIds.ovcQuestion4});
      question4.addAll({"answer_id": child.question4});
      entries.add(question4);
    }

    if (child.question5 != null && child.question5?.isNotEmpty == true) {
      var question5 = {"ovc_cpims_id": child.ovcId, "form_id": formId};
      question5.addAll({"question_code": CparaRemoteQuestionIds.ovcQuestion5});
      question5.addAll({"answer_id": child.question5});
      entries.add(question5);
    }

    if (child.question6 != null && child.question6?.isNotEmpty == true) {
      var question6 = {"ovc_cpims_id": child.ovcId, "form_id": formId};
      question6.addAll({"question_code": CparaRemoteQuestionIds.ovcQuestion6});
      question6.addAll({"answer_id": child.question6});
      entries.add(question6);
    }

    if (child.question7 != null && child.question7?.isNotEmpty == true) {
      var question7 = {"ovc_cpims_id": child.ovcId, "form_id": formId};
      question7.addAll({"question_code": CparaRemoteQuestionIds.ovcQuestion7});
      question7.addAll({"answer_id": child.question7});
      entries.add(question7);
    }

    if (child.question8 != null && child.question8?.isNotEmpty == true) {
      var question8 = {"ovc_cpims_id": child.ovcId, "form_id": formId};
      question8.addAll({"question_code": CparaRemoteQuestionIds.ovcQuestion8});
      question8.addAll({"answer_id": child.question8});
      entries.add(question8);
    }

    return entries;
  }

  static void informUpstreamOfStoredUnapproved(
      String formID, bool saved, String formType) async {
    try {
      var baseUrl = "mobile/record_saved";

      var prefs = await SharedPreferences.getInstance();
      var accessToken = prefs.getString('access');
      String bearerAuth = "Bearer $accessToken";
      var responseData = {};

      if (saved == true) {
        responseData = {"record_id": formID, "saved": 1, "form_type": formType};
      } else {
        responseData = {"record_id": formID, "saved": 0, "form_type": formType};
      }

      var response = await dio.post("$cpimsProdApiUrl$baseUrl",
          data: responseData,
          options: Options(headers: {"Authorization": bearerAuth}));
    } catch (err) {
      debugPrint(err.toString());
      // throw "Could Not Inform Upstream of Stored Unapproved";
    }
  }
}

final unapprovedcparaserviceconstructor = UnapprovedCparaService();
