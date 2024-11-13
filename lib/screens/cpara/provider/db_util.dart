import 'dart:convert';

import 'package:cpims_mobile/constants.dart' as consts;
import 'package:cpims_mobile/constants_prod.dart';
import 'package:cpims_mobile/screens/cpara/cpara_util.dart';
import 'package:cpims_mobile/screens/cpara/model/db_model.dart';
import 'package:cpims_mobile/utils/app_form_metadata.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../../../providers/db_provider.dart';
import '../model/cpara_model.dart';
import '../model/sub_ovc_child.dart';
import '../widgets/cpara_stable_widget.dart';

// Code for creating unapproved CPARA tables
Future<void> createUnapprovedCparaTables(Database db, int version) async {
  // Creating table to store unapproved CPARA form
  await db.execute('''
    CREATE TABLE IF NOT EXISTS UnapprovedCPARA(
      id TEXT PRIMARY KEY,
      date_of_event TEXT,
      message TEXT,
      ovc_id TEXT
    )
    ''');

  // Creating table to store answers of the form
  await db.execute('''
    CREATE TABLE IF NOT EXISTS UnapprovedCPARAAnswers(
      id INTEGER PRIMARY KEY,
      question_code TEXT,
      answer_id TEXT,
      ovc_cpims_id TEXT,
      form_id INTEGER,
      FOREIGN KEY (form_id) REFERENCES UnapprovedCPARA(id)
    )
    ''');
}

Future<List<CPARADatabase>> getUnsyncedForms(Database db) async {
  try {
    List<CPARADatabase> forms = [];
    List<Map<String, dynamic>> formsFetchResult = await db.rawQuery(
        "SELECT id FROM Form WHERE id IN (SELECT formID FROM HouseholdAnswer) AND form_date_synced IS NULL");
    for (var i in formsFetchResult) {
      var form = await getFormFromDB(i['id'], db);

      forms.add(form);
    }
    return forms;
  } catch (err) {
    throw ("Could Not Get Unsynced Forms ${err.toString()}");
  }
}

Future<int> getUnsyncedCparaFormsCount(Database db) async {
  try {
    List<Map<String, dynamic>> countResult = await db.rawQuery(
        "SELECT COUNT(id) AS count FROM Form WHERE form_date_synced IS NULL");

    if (countResult.isNotEmpty) {
      int count = countResult[0]['count'];
      return count;
    } else {
      return 0; // Return 0 if there are no unsynced forms
    }
  } catch (err) {
    throw ("Could Not Get Unsynced Forms Count: ${err.toString()}");
  }
}

Future<CPARADatabase> getFormFromDB(int formID, Database? db) async {
  try {
    CPARADatabase form = CPARADatabase();
    List<Map<String, dynamic>> fetchResult1 = await db!.rawQuery(
        "SELECT formID, householdid, date, questionid, answer, form.uuid, is_rejected "
        "FROM HouseholdAnswer "
        "INNER JOIN Form ON Form.id = HouseholdAnswer.formID "
        "WHERE formID =  $formID");

    var isRejected = fetchResult1[0]['is_rejected'] == 1 ? true : false;
    var uuid = fetchResult1[0]['uuid'];
    form.cparaFormId = "$uuid";
    form.isRejected = isRejected;
    var ovcpmisID = fetchResult1[0]['houseHoldID'];
    form.ovcCpimsId = ovcpmisID;
    if (kDebugMode) {
      print("OVCPMIS ID from many: $ovcpmisID");
    }
    var dateOfEvent2 = fetchResult1[0]['date'];
    form.dateOfEvent = dateOfEvent2;
    if (kDebugMode) {
      print("Date of event from many: $dateOfEvent2");
    }
    List<CPARADatabaseQuestions> questions = [];
    for (var i in fetchResult1) {
      questions.add(CPARADatabaseQuestions(
          questionCode: i['questionID'], answerId: i['answer'] ?? ""));
    }
    form.questions = questions;
    if (kDebugMode) {
      print("Questions from many: $questions");
    }

    // Get children questions
    List<Map<String, dynamic>> fetchResult2 = await db.rawQuery(
        "SELECT questionid, answer, childid FROM ChildAnswer WHERE formid = ?",
        [formID]);
    List<CPARAChildQuestions> childQuestions = [];
    for (var i in fetchResult2) {
      childQuestions.add(CPARAChildQuestions.fromJsonLocal(i));
    }

    form.childQuestions = childQuestions;
    AppFormMetaData appFormMetaData =
        await LocalDb.instance.getAppFormMetaData(uuid);
    form.appFormMetaData = appFormMetaData;
    var listOfOvcSub =
        await fetchAndPostToServerOvcSubpopulationDataNew(formId: "$formID");
    form.listOfSubOvcs = listOfOvcSub;
    return form;
  } catch (err) {
    throw ("Could Not Get Form From DB ${err.toString()}");
  }
}

Future<void> purgeForm(int formID, Database db) async {
  try {
    // Delete householdanswers
    await db
        .rawDelete("DELETE FROM HouseholdAnswer WHERE formID = ?", [formID]);

    // Delete childanswers
    await db.rawDelete("DELETE FROM ChildAnswer WHERE formID = ?", [formID]);

    // Form
    await db.rawDelete("DELETE FROM Form WHERE id = ?", [formID]);
  } catch (err) {
    if (kDebugMode) {
      print(err);
    }
  }
}

//update form date time for sync
Future<void> updateFormDateSynced(String formID, Database db) async {
  try {
    DateTime now = DateTime.now();
    await db.rawUpdate("UPDATE Form SET form_date_synced = ? WHERE uuid = ?",
        [now.toUtc().toIso8601String(), formID]);
  } catch (err) {
    debugPrint("Error updating date_synced: $err");
  }
}

// Returns the number of CPARA forms
Future<int> getCountOfForms(Database? db) async {
  try {
    // Run query to get count of unique forms
    List<Map<String, dynamic>> fetchResults =
        await db!.rawQuery("SELECT COUNT(*) total FROM Form");
    // Return value
    int total = fetchResults[0]['total'];
    return total;
  } catch (err) {
    debugPrint(err.toString());
    throw ("Could Not Get Count ${err.toString()}");
  }
}

// submit to upstream
Future<void> submitCparaToUpstream() async {
  var prefs = await SharedPreferences.getInstance();
  var accessToken = prefs.getString('access');
  String bearerAuth = "Bearer $accessToken";

  Database database = await LocalDb.instance.database;
  List<CPARADatabase> cparaFormsInDb = await getUnsyncedForms(database);

  int totalForms = cparaFormsInDb.length;
  int successfullySubmittedForms = 0;

  for (CPARADatabase cparaForm in cparaFormsInDb) {
    try {
      await singleCparaFormSubmission(
          cparaForm: cparaForm, authorization: bearerAuth);
      updateFormDateSynced(cparaForm.cparaFormId, database);

      successfullySubmittedForms++;

      if (successfullySubmittedForms == totalForms) {
        Get.snackbar(
          "Success",
          "CPARA Forms synced successfully",
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      debugPrint(
          "Cpara form with ovs cpims id : ${cparaForm.ovcCpimsId} failed submission to upstream");
      continue;
    }
  }
}

Future<void> singleCparaFormSubmission(
    {required CPARADatabase cparaForm, required String authorization}) async {
  // Get signature from payload
  Database db = await LocalDb.instance.database;
  var fetchResult = await db.rawQuery(
      "SELECT signature FROM Form WHERE uuid = ?", [cparaForm.cparaFormId]);
  var signature = (fetchResult[0]['signature'] ?? []) as Uint8List;
  var encodedBlob = base64Encode(signature);
  // var uint8Signature = Uint
  // var blobSignature = ByteData.sublistView(signature);

// household questions
  final houseHoldQuestions = [];
  for (int i = 0; i < cparaForm.questions.length; i++) {
    final questionCode = convertQuestionIdsStandardFormat(text: cparaForm.questions[i].questionCode);
    String answerId;

    // Check if the question is PCPA or DDOA
    if (questionCode == "qd1" || questionCode == "qd3") {
      // For date fields, use the original answerId without conversion
      answerId = cparaForm.questions[i].answerId;
    } else {
      // For other questions, use the convertOptionStandardFormat
      answerId = convertOptionStandardFormat(text: cparaForm.questions[i].answerId);
    }

    houseHoldQuestions.add({
      "question_code": questionCode,
      "answer_id": answerId,
    });

    debugPrint("Monday Household ${cparaForm.questions[i].questionCode} - $answerId");
  }

  // child questions
  final individualQuestions = [];
  for (int i = 0; i < cparaForm.childQuestions.length; i++) {
    individualQuestions.add({
      "ovc_cpims_id": cparaForm.childQuestions[i].ovcCpimsId,
      "question_code": convertQuestionIdsStandardFormat(
          text: cparaForm.childQuestions[i].questionCode),
      "answer_id": convertOptionStandardFormat(
          text: cparaForm.childQuestions[i].answerId),
    });
    debugPrint("Child ${cparaForm.childQuestions[i].ovcCpimsId}: "
        "${cparaForm.childQuestions[i].questionCode} - ${cparaForm.childQuestions[i].answerId}");
  }

  // scores value
  String b1 = benchMarkOneScoreFromDb(cparaDatabase: cparaForm);
  String b2 = benchMarkTwoScoreFromDb(cparaDatabase: cparaForm);
  String b3 = benchMarkThreeScoreFromDb(cparaDatabase: cparaForm);
  String b4 = benchMarkFourScoreFromDb(cparaDatabase: cparaForm);
  String b5 = benchMarkFiveScoreFromDb(cparaDatabase: cparaForm);
  String b6 = benchMarkSixScoreFromDb(cparaDatabase: cparaForm);
  String b7 = benchMarkSevenScoreFromDb(cparaDatabase: cparaForm);
  String b8 = benchMarkEightScoreFromDb(cparaDatabase: cparaForm);
  String b9 = benchMarkNineScoreFromDb(cparaDatabase: cparaForm);
  List<String> scores = [b1, b2, b3, b4, b5, b6, b7, b8, b9];

  final scoreList = [];
  for (int i = 0; i < scores.length; i++) {
    scoreList.add({
      "b${i + 1}": "${scoreConversion(text: scores[i])}",
    });
  }
  var cparaMapData = {};

  // Only adds form id to json if cpara form is rejected
  if (cparaForm.isRejected == true) {
    cparaMapData = {
      "id": cparaForm.cparaFormId,
      "ovc_cpims_id": cparaForm.ovcCpimsId,
      "date_of_event": cparaForm.dateOfEvent,
      "questions": houseHoldQuestions,
      "individual_questions": individualQuestions,
      "scores": scoreList,
      "app_form_metadata": cparaForm.appFormMetaData.toJson(),
      "sub_population":
          List<dynamic>.from(cparaForm.listOfSubOvcs.map((x) => x.toJson())),
      "device_id": await getDeviceId(),
      "signature": encodedBlob,
    };
  } else {
    cparaMapData = {
      "ovc_cpims_id": cparaForm.ovcCpimsId,
      "date_of_event": cparaForm.dateOfEvent,
      "questions": houseHoldQuestions,
      "individual_questions": individualQuestions,
      "scores": scoreList,
      "app_form_metadata": cparaForm.appFormMetaData.toJson(),
      "sub_population":
          List<dynamic>.from(cparaForm.listOfSubOvcs.map((x) => x.toJson())),
      "device_id": await getDeviceId(),
      "signature": encodedBlob,
    };
  }

  debugPrint(json.encode(cparaMapData));

  dio.interceptors.add(LogInterceptor());
  const cparaUrl = "mobile/cpara/";
  var response = await dio.post("$cpimsProdApiUrl$cparaUrl",
      data: cparaMapData,
      options: Options(
          contentType: 'application/json',
          headers: {"Authorization": authorization}));

  if (response.statusCode == 403) {
    Get.dialog(
      AlertDialog(
        title: const Text("Session Expired"),
        content: const Text("Your session has expired. Please log in again"),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  } else if (response.statusCode != 201) {
    throw ("Submission to upstream failed");
  }

  if (kDebugMode) {
    print("Data sent to server was $cparaMapData");
  }
}

Future<List<Map<String, dynamic>>> fetchQuestionsForOvc(
    String ovcCpimsId, String dateOfEvent) async {
  final db = await LocalDb.instance.database;
  const sql =
      "SELECT * FROM ovcsubpopulation WHERE cpims_id = ? AND date_of_event = ? AND form_date_synced IS NULL";
  List<Map<String, dynamic>> result =
      await db.rawQuery(sql, [ovcCpimsId, dateOfEvent]);
  return result;
}

Future<List<SubOvcChild>> fetchAndPostToServerOvcSubpopulationDataNew(
    {required String formId}) async {
  // var prefs = await SharedPreferences.getInstance();
  // var accessToken = prefs.getString('access');
  // String bearerAuth = "Bearer $accessToken";
  Database database = await LocalDb.instance.database;
  List result = await fetchOvcSubPopulationData(formId: formId);
  int totalForms = result.length;
  int successfullySubmittedForms = 0;
  List<SubOvcChild> childSub = [];

  for (var row in result) {
    var ovcCpimsId = row['cpims_id'];
    var criteria = row['criteria'];
    // var dateOfEvent = row['date_of_event'];
    childSub.add(
        SubOvcChild(cpimsId: ovcCpimsId, answer: "AYES", questionId: criteria));
  }
  return childSub;
}

Future<List> fetchOvcSubPopulationData({required String formId}) async {
  final db = await LocalDb.instance.database;
  // const sql =
  //     "SELECT DISTINCT cpims_id, date_of_event FROM ovcsubpopulation WHERE form_date_synced IS NULL";
  const sql =
      "SELECT cpims_id, date_of_event, criteria FROM ovcsubpopulation WHERE form_date_synced IS NULL AND uuid = ? ";
  var result = await db.rawQuery(sql, [formId]);
  return result;
}
//
// Future<List<Map<String, dynamic>>> fetchOvcSubPopulationData() async {
//   final db = await LocalDb.instance.database;
//   const sql = "SELECT * FROM ovcsubpopulation WHERE form_date_synced IS NULL";
//   List<Map<String, dynamic>> result = await db.rawQuery(sql);
//   return result;
// }

Future<void> updateOvcSubpopulationDateSynced(
    String? ovcId, Database db) async {
  if (ovcId != null) {
    try {
      // Get the current date and time
      DateTime now = DateTime.now();
      await db.rawUpdate(
          "UPDATE ovcsubpopulation SET form_date_synced = ? WHERE cpims_id = ?",
          [now.toUtc().toIso8601String(), ovcId]);
    } catch (err) {
      debugPrint("Error updating date_synced: $err");
    }
  }
}

Future<Response> ovcSubPopulationPostOvcToServer(
    Map<String, dynamic> data, String bearerAuth) async {
  const cparaUrl = "mobile/cpara/";
  dio.interceptors.add(LogInterceptor());
  try {
    final response = await dio.post(
      "$cpimsProdApiUrl$cparaUrl",
      data: data,
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Authorization': bearerAuth,
        },
      ),
    );
    return response;
  } catch (e) {
    throw ("Failed to post data to server: ${e.toString()}");
  }
}
