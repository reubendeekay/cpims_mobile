// ignore_for_file: depend_on_referenced_packages
import 'dart:async';
import 'dart:convert';

import 'package:cpims_mobile/Models/case_load_model.dart';
import 'package:cpims_mobile/Models/form_metadata_model.dart';
import 'package:cpims_mobile/Models/statistic_model.dart';
import 'package:cpims_mobile/constants_prod.dart';
import 'package:cpims_mobile/providers/unapproved_cpt_provider.dart';
import 'package:cpims_mobile/Models/unapproved_form_1_model.dart';
import 'package:cpims_mobile/providers/cpara/unapproved_cpara_service.dart';
import 'package:cpims_mobile/screens/cpara/model/cpara_model.dart';
import 'package:cpims_mobile/screens/cpara/model/ovc_model.dart';
import 'package:cpims_mobile/screens/cpara/provider/db_util.dart';
import 'package:cpims_mobile/screens/cpara/widgets/ovc_sub_population_form.dart';
import 'package:cpims_mobile/screens/forms/graduation_monitoring/model/graduation_monitoring_form_model.dart';
import 'package:cpims_mobile/screens/forms/hiv_management/models/hiv_management_form_model.dart';
import 'package:cpims_mobile/utils/app_form_metadata.dart';
import 'package:cpims_mobile/utils/strings.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
import '../Models/caseplan_form_model.dart';
import '../constants.dart' as consts;
import '../screens/forms/form1a/new/form_one_a.dart';
import '../screens/forms/hiv_assessment/unapproved/hiv_risk_assessment_form_model.dart';
import '../services/metadata_service.dart';

String idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
String textType = 'TEXT NOT NULL';
String textTypeNull = 'TEXT NULL';
String defaultTime = 'DATETIME DEFAULT CURRENT_TIMESTAMP';
String intType = 'INTEGER';
String intTypeNull = 'INTEGER NULL';
String unique = 'UNIQUE';

class LocalDb {
  static const String _databaseName = 'children_ovc4.db';
  static final LocalDb instance = LocalDb._init();
  static Database? _database;

  LocalDb._init();

  Future<Database> get database async {
    // If database exists, return database
    if (_database != null) return _database!;

    // If database don't exists, create one
    _database = await _initDB(_databaseName);

    return _database!;
  }

  Future<void> deleteDb() async {
    databaseFactory.deleteDatabase(_databaseName);
    _database = null;
  }

  List<String> migrationScripts = [
    '''
        CREATE TABLE IF NOT EXISTS $metadataTable(
          ${FormMetadata.columnId} $idType,
          ${FormMetadata.columnItemId} $textType,
          ${FormMetadata.columnFieldName} $textType,
          ${FormMetadata.columnItemDescription} $textType,
          ${FormMetadata.columnItemSubCategory} $textType,
          ${FormMetadata.columnTheOrder} $textType
        );
      '''
  ];

//create database and child table

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 2, onCreate: _createTables,
        onUpgrade: (Database db, int oldVersion, int newVersion) async {
      debugPrint("onUpgrade: Migration");
      for (var i = oldVersion - 1; i <= newVersion - 2; i++) {
        await db.execute(migrationScripts[i]);
      }
    });
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $caseloadTable (
        ${OvcFields.id} $idType,
        ${OvcFields.cboID} $textType $unique,
        ${OvcFields.ovcFirstName} $textType,
        ${OvcFields.ovcSurname} $textType,
        ${OvcFields.registationDate} $textType,
        ${OvcFields.dateOfBirth} $textType,
        ${OvcFields.age} $intTypeNull,
        ${OvcFields.caregiverNames} $textType,
        ${OvcFields.sex} $textType,
        ${OvcFields.caregiverCpimsId} $textType,
        ${OvcFields.chvCpimsId} $textType,
        ${OvcFields.ovchivstatus} $textType,
        ${OvcFields.benchMarks} $textType,
        ${OvcFields.benchMarksScore} $intType,
        ${OvcFields.benchMarksPathWay} $textType,
        ${OvcFields.hhGaps} $textType
      )
    ''');

    await db.execute('''
      CREATE TABLE $statisticsTable (
        ${SummaryFields.id} $idType,
        ${SummaryFields.children} $textType,
        ${SummaryFields.caregivers} $textType,
        ${SummaryFields.government} $textType,
        ${SummaryFields.ngo} $textType,
        ${SummaryFields.caseRecords} $textType,
        ${SummaryFields.pendingCases} $textType,
        ${SummaryFields.orgUnits} $textType,
        ${SummaryFields.workforceMembers} $textType,
        ${SummaryFields.household} $textType,
        ${SummaryFields.childrenAll} $textType,
        ${SummaryFields.ovcSummary} $textType,
        ${SummaryFields.ovcRegs} $textType,
        ${SummaryFields.caseRegs} $textType,
        ${SummaryFields.caseCats} $textType,
        ${SummaryFields.criteria} $textType,
        ${SummaryFields.orgUnit} $textType,
        ${SummaryFields.orgUnitId} $textType,
        ${SummaryFields.details} $textType
      )
''');

    await db.execute('''
      CREATE TABLE $casePlanTable (
        ${CasePlan.id} $idType,
        ${CasePlan.ovcCpimsId} $textType,
        ${CasePlan.dateOfEvent} $textType,
        ${CasePlan.formDateSynced} $textTypeNull,
        ${CasePlan.uuid} $textType,
        ${CasePlan.caregiverId} $textType
      )
      ''');

    await db.execute('''
        CREATE TABLE $casePlanServicesTable (
          ${CasePlanServices.id} $idType,
          ${CasePlanServices.formId} $intTypeNull,
          ${CasePlanServices.unapprovedFormId} $intTypeNull,
          ${CasePlanServices.domainId} $textType,
          ${CasePlanServices.goalId} $textType,
          ${CasePlanServices.priorityId} $textType,
          ${CasePlanServices.gapId} $textType,
          ${CasePlanServices.serviceIds} $textType,
          ${CasePlanServices.resultsId} $textType,
          ${CasePlanServices.reasonId} $textTypeNull,
          ${CasePlanServices.completionDate} $textTypeNull,
          ${CasePlanServices.responsibleIds} $textType,
          FOREIGN KEY (${CasePlanServices.formId}) REFERENCES $casePlanTable(${CasePlan.id})
        )
        ''');

    await db.execute('''
        CREATE TABLE IF NOT EXISTS $metadataTable(
          ${FormMetadata.columnId} $idType,
          ${FormMetadata.columnItemId} $textType,
          ${FormMetadata.columnFieldName} $textType,
          ${FormMetadata.columnItemDescription} $textType,
          ${FormMetadata.columnItemSubCategory} $textType,
          ${FormMetadata.columnTheOrder} $textType
        );
      ''');

    await db.execute('''
        CREATE TABLE $unapprovedForm1Table (
          ${Form1.localId} $idType,
          ${Form1.id} $textType,
          ${Form1.ovcCpimsId} $textType,
          ${Form1.dateOfEvent} $textType,
          ${Form1.formType} $textType,
          ${Form1.message} $textType
        )
        ''');

    await db.execute('''
        CREATE TABLE $form1Table (
          ${Form1.localId} $idType,
          ${Form1.id} $textType,
          ${Form1.ovcCpimsId} $textType,
          ${Form1.dateOfEvent} $textType,
          ${Form1.formType} $textType,
          ${Form1.formDateSynced} $textTypeNull,
          ${Form1.caregiverId} $textType
        )
        ''');

    // created_at DATETIME DEFAULT CURRENT_TIMESTAMP,

    await db.execute('''
  CREATE TABLE $form1ServicesTable (
    ${Form1Services.id} $idType,
    ${Form1Services.formId} $intTypeNull,
    ${Form1Services.domainId} $textType,
    ${Form1Services.serviceId} $textType,
    ${Form1Services.unapprovedFormId} $intTypeNull,
    ${Form1Services.message} $textTypeNull
  )
''');

    await db.execute('''
      CREATE TABLE $form1CriticalEventsTable (
        ${Form1CriticalEvents.id} $idType,
        ${Form1CriticalEvents.formId} $intTypeNull,
        ${Form1CriticalEvents.eventId} $textType,
        ${Form1CriticalEvents.eventDate} $textType,
        ${Form1CriticalEvents.unapprovedFormId} $intTypeNull,
        ${Form1CriticalEvents.message} $textTypeNull
        )
      ''');

    await creatingCparaTables(db, version);
    await createOvcSubPopulation(db, version);
    await createAppMetaDataTable(db, version);
    await createHRSForms(db, version);
    await createUnapprovedCparaTables(db, version);
    await createHMFForms(db, version);
    await createGraduationMonitoringTable(db, version);
    final unapprovedCptDb = UnapprovedCptProvider();
    await unapprovedCptDb.createTable(db, version);
  }

  Future<void> createAppMetaDataTable(Database db, int version) async {
    try {
      await db.execute('''
     CREATE TABLE app_form_metadata (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        form_id TEXT,
        location_lat TEXT,
        location_long TEXT,
        start_of_interview TEXT,
        end_of_interview TEXT,
        form_type TEXT,
        device_id TEXT
      )
    ''');
    } catch (err) {
      debugPrint(err.toString());
    }
  }

  Future<void> insertCaseLoad(CaseLoadModel caseLoadModel) async {
    try {
      final db = await instance.database;

      await db.insert(caseloadTable, caseLoadModel.toJson(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      debugPrint("Error inserting caseload data: $e");
    }
  }

  Future<void> insertMultipleCaseLoad(
      List<CaseLoadModel> caseLoadModelList) async {
    try {
      final db = await instance.database;

      // Use a batch to insert all the data at once
      final batch = db.batch();

      for (final caseLoadModel in caseLoadModelList) {
        batch.insert(
          caseloadTable,
          caseLoadModel.toMap(), // Convert the model to a map
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      // Commit the batch to insert all the data in a single transaction
      await batch.commit(noResult: true);
    } catch (e) {
      debugPrint("Error inserting caseload data: $e");
    }
  }

  Future<void> updateMultipleCaseLoad(
      List<CaseLoadModel> caseLoadModelList) async {
    /**
     * There was an alternative approach to syncing caseloads. We will leave the commented ode here in case there is need to switch back to this approach.
     * This approach goes like so:
     * -> sync data upstream -> get all caseloads from the server -> upsert all caseloads into the local db -> delete all caseloads not in the fetched data
     * For now we will only leave the upsert without the delete functionality
     * await db.transaction((txn) async {
        // Step 1: Create a temporary table to store the fetched IDs
        await txn.execute('''
        CREATE TEMPORARY TABLE temp_caseload_ids (
        ovc_cpims_id TEXT PRIMARY KEY
        )
        ''');

        // Step 2: Insert fetched IDs into the temporary table and upsert data
        final batch = txn.batch();
        for (final caseLoad in caseLoadModelList) {
        batch.insert(
        'temp_caseload_ids',
        {'ovc_cpims_id': caseLoad.cpimsId},
        conflictAlgorithm: ConflictAlgorithm.ignore,
        );
        batch.insert(
        caseloadTable,
        caseLoad.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
        );
        }
        await batch.commit(noResult: true);

        // Step 3: Delete records not in the fetched data
        await txn.delete(
        caseloadTable,
        where:
        'ovc_cpims_id NOT IN (SELECT ovc_cpims_id FROM temp_caseload_ids)',
        );

        // Step 4: Drop the temporary table
        await txn.execute('DROP TABLE temp_caseload_ids');
        });
     * */
    try {
      final db = await instance.database;

      // Use a batch to update all the data at once
      final batch = db.batch();

      for (final caseLoadModel in caseLoadModelList) {
        batch.insert(
          caseloadTable,
          caseLoadModel.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      // Commit the batch to update all the data in a single transaction
      await batch.commit(noResult: true);
    } catch (e) {
      debugPrint('Error updating caseload data: $e');
    }
  }

  //delete all caseload data
  Future<void> deleteAllCaseLoad() async {
    try {
      final db = await instance.database;
      await db.delete(caseloadTable);
    } catch (e) {
      debugPrint("Error deleting caseload data: $e");
    }
  }

  Future<void> insertStatistics(SummaryDataModel summaryModel) async {
    final db = await instance.database;

    await db.insert(statisticsTable, summaryModel.toJson());
  }

  Future<List<CaseLoadModel>> retrieveCaseLoads() async {
    final db = await instance.database;
    final result = await db.query(caseloadTable);
    return result.map((json) => CaseLoadModel.fromJson(json)).toList();
  }

  Future<List<SummaryDataModel>> retrieveStatistics() async {
    final db = await instance.database;
    final result = await db.query(statisticsTable);
    return result.map((json) => SummaryDataModel.fromJson(json)).toList();
  }

  Future<void> creatingCparaTables(Database db, int version) async {
    await createCparaForms(db, version);
    try {
      debugPrint("Creating Cpara tables");
      await db.execute(
          "CREATE TABLE IF NOT EXISTS HouseholdAnswer(formID INTEGER, id INTEGER PRIMARY KEY, houseHoldID TEXT, questionID TEXT, answer TEXT, FOREIGN KEY (formID) REFERENCES Form(id));");

      await db.execute(
          "CREATE TABLE IF NOT EXISTS ChildAnswer(formID INTEGER, id INTEGER PRIMARY KEY, childID TEXT, questionid TEXT, answer TEXT, FOREIGN KEY (formID) REFERENCES Form(id));");
    } catch (err) {
      debugPrint("Error creating Cpara tables: $err");
    }
  }

  Future<void> insertCparaData(
      {required CparaModel cparaModelDB,
      required String ovcId,
      required String startTime,
      required Uint8List signature,
      required bool isRejected,
      required String careProviderId,
      required String caregiverCpimsId}) async {
    try {
      final db = await instance.database;
      var idForm = 0;
      String selectedDate = cparaModelDB.detail.dateOfAssessment ??
          DateFormat('yyyy-MM-dd').format(DateTime.now());

      if (isRejected == true) {
        // Create form
        await insertAppFormMetaData(
          cparaModelDB.uuid,
          startTime,
          'cpara',
        );
        var formUUID = await cparaModelDB.createForm(db, selectedDate,
            cparaModelDB.uuid, signature, isRejected, caregiverCpimsId);
        var formData = await cparaModelDB.getLatestFormID(db);
        var formDate = formData.formDate;
        var formDateString = formDate.toString().split(' ')[0];
        var formID = formData.formID;
        await cparaModelDB.addHouseholdFilledQuestionsToDB(
            db, selectedDate, ovcId, formID);
        // await insertAppFormMetaData(cparaModelDB.uuid, startTime, 'cpara');
        handleSubmit(
            selectedDate: selectedDate,
            formId: cparaModelDB.uuid,
            ovcSub: cparaModelDB.ovcSubPopulations);

        // Delete previous entries of unapproved
        await UnapprovedCparaService.deleteUnapprovedCparaForm(
            cparaModelDB.uuid);
      } else {
        String formUUID = const Uuid().v4();
        // Create form
        await insertAppFormMetaData(
          formUUID,
          startTime,
          'cpara',
        );
        // Create form
        cparaModelDB
            .createForm(db, selectedDate, formUUID, signature, isRejected,
                caregiverCpimsId)
            .then((formUUID) {
          // Get formID
          cparaModelDB.getLatestFormID(db).then((formData) {
            var formDate = formData.formDate;
            var formDateString = formDate.toString().split(' ')[0];
            var formID = formData.formID;
            idForm = formID;
            cparaModelDB
                .addHouseholdFilledQuestionsToDB(
                    db, formDateString, ovcId, formID)
                .then((value) => handleSubmit(
                    selectedDate: selectedDate,
                    formId: "$formID",
                    ovcSub: cparaModelDB.ovcSubPopulations));
          });
        });
      }
    } catch (e) {
      rethrow;
    }
  }

  void handleSubmit(
      {required String selectedDate,
      required String formId,
      required CparaOvcSubPopulation ovcSub}) async {
    final localDb = LocalDb.instance;
    List<CparaOvcChild> listOfOvcChild = ovcSub.childrenQuestions ?? [];

    try {
      for (var child in listOfOvcChild) {
        List<CheckboxQuestion> selectedQuestions = [];
        if (child.answer1 ?? false) {
          selectedQuestions.add(CheckboxQuestion(
              question: "question",
              id: 0,
              questionID: child.question1 ?? "double",
              isChecked: child.answer1 ?? false));
        }

        if (child.answer2 ?? false) {
          selectedQuestions.add(CheckboxQuestion(
              question: "question",
              id: 0,
              questionID: child.question2 ?? "AGYW",
              isChecked: child.answer2 ?? false));
        }

        if (child.answer3 ?? false) {
          selectedQuestions.add(CheckboxQuestion(
              question: "question",
              id: 0,
              questionID: child.question3 ?? "HEI",
              isChecked: child.answer3 ?? false));
        }

        if (child.answer4 ?? false) {
          selectedQuestions.add(CheckboxQuestion(
              question: "question",
              id: 0,
              questionID: child.question4 ?? "FSW",
              isChecked: child.answer4 ?? false));
        }

        if (child.answer5 ?? false) {
          selectedQuestions.add(CheckboxQuestion(
              question: "question",
              id: 0,
              questionID: child.question5 ?? "PLHIV",
              isChecked: child.answer5 ?? false));
        }

        if (child.answer6 ?? false) {
          selectedQuestions.add(CheckboxQuestion(
              question: "question",
              id: 0,
              questionID: child.question6 ?? "CLHIV",
              isChecked: child.answer6 ?? false));
        }

        if (child.answer7 ?? false) {
          selectedQuestions.add(CheckboxQuestion(
              question: "question",
              id: 0,
              questionID: child.question7 ?? "SVAC",
              isChecked: child.answer7 ?? false));
        }

        if (child.answer8 ?? false) {
          selectedQuestions.add(CheckboxQuestion(
              question: "question",
              id: 0,
              questionID: child.question8 ?? "AHIV",
              isChecked: child.answer8 ?? false));
        }

        // String uuid = const Uuid().v4();
        // String? dateOfAssessment = selectedDate != null
        //     ? DateFormat('yyyy-MM-dd').format(selectedDate)
        //     : null;
        await localDb.insertOvcSubpopulationData(
            formId, "${child.ovcId}", selectedDate, selectedQuestions);
      }
      // if(mounted) {
      //   Navigator.pop(context);
      // }
    } catch (error) {
      throw ("Error Occurred");
      // if (currentContext.mounted) {
      //   showDialog(
      //     context: currentContext, // Use the local context
      //     builder: (context) => AlertDialog(
      //       title: const Text('Error'),
      //       content: Text('An error occurred: $error'),
      //       actions: [
      //         TextButton(
      //           onPressed: () {
      //             Get.back(); // Close the dialog
      //           },
      //           child: const Text('OK'),
      //         ),
      //       ],
      //     ),
      //   );
      // }
    }
  }

  Future<void> createOvcSubPopulation(Database db, int version) async {
    try {
      await db.execute('''
      CREATE TABLE $ovcsubpopulation (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid TEXT,
        cpims_id TEXT,
        criteria TEXT,
        date_of_event TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        form_date_synced TEXT NULL
      )
    ''');
    } catch (err) {
      debugPrint(err.toString());
    }
  }

  Future<void> createCparaForms(Database db, int version) async {
    try {
      await db.execute('''
      CREATE TABLE $cparaForms (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        form_id INTEGER,
        date TEXT,
        uuid TEXT,
        form_date_synced TEXT NULL,
        is_rejected INTEGER DEFAULT 0,
        signature BLOB,
        caregiver_cpims_id TEXT
      )
    ''');
    } catch (err) {
      debugPrint(err.toString());
    }
  }

  Future<void> createHRSForms(Database db, int version) async {
    // Define the table name

    // Define the table schema with all the fields
    const String createTableQuery = '''
    CREATE TABLE $HRSForms (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      ovc_cpims_id TEXT,
      caregiver_cpims_id TEXT,
      HIV_RA_1A TEXT,
      HIV_RS_01 TEXT,
      HIV_RS_02 TEXT,
      HIV_RS_03 TEXT,
      HIV_RS_04 TEXT,
      HIV_RS_05 TEXT,
      HIV_RS_06 TEXT,
      HIV_RS_09 TEXT,
      HIV_RS_06A TEXT,
      HIV_RS_07 TEXT,
      HIV_RS_08 TEXT,
      HIV_RS_10 TEXT,
      HIV_RS_10A TEXT,
      HIV_RS_10B TEXT,
      HIV_RS_11 TEXT,
      HIV_RS_14 TEXT,
      HIV_RS_15 TEXT,
      HIV_RS_16 TEXT,
      HIV_RS_17 TEXT,
      HIV_RS_18 TEXT,
      HIV_RS_18A TEXT,
      HIV_RS_18B TEXT,
      HIV_RS_21 TEXT,
      HIV_RS_22 TEXT,
      HIV_RS_23 TEXT,
      HIV_RS_24 TEXT,
      HIV_RA_3Q6 TEXT,
      uuid TEXT,
      form_date_synced TEXT NULL,
      message TEXT NULL,
      rejected BOOLEAN,
       created_at DATETIME DEFAULT CURRENT_TIMESTAMP 
    )
  ''';

    try {
      await db.execute(createTableQuery);
    } catch (e) {
      print('Error creating table: $e');
    }
  }

  Future<bool> insertHRSData(
    String? cpmisId,
    String? caregiverCpimsId,
    RiskAssessmentFormModel assessment,
    String? uuid,
    String? startOfInterview,
    String? formType,
    bool? isRejected,
  ) async {
    try {
      final db = await instance.database;
      await insertAppFormMetaData(uuid, startOfInterview, formType);
      await db.insert(
        HRSForms,
        {
          'ovc_cpims_id': cpmisId,
          'caregiver_cpims_id': caregiverCpimsId,
          'HIV_RA_1A': assessment.dateOfAssessment,
          'HIV_RS_01': assessment.statusOfChild,
          'HIV_RS_02': assessment.hivStatus,
          'HIV_RS_03': assessment.hivTestDone,
          'HIV_RS_04': assessment.biologicalFather,
          'HIV_RS_05': assessment.malnourished,
          'HIV_RS_06': assessment.sexualAbuse,
          'HIV_RS_09': assessment.sexualAbuseAdolescent,
          'HIV_RS_06A': assessment.traditionalProcedures,
          'HIV_RS_07': assessment.persistentlySick,
          'HIV_RS_08': assessment.tb,
          'HIV_RS_10': assessment.sexualIntercourse,
          'HIV_RS_10A': assessment.symptomsOfSTI,
          'HIV_RS_10B': assessment.ivDrugUser,
          'HIV_RS_11': assessment.finalEvaluation,
          'HIV_RS_14': assessment.parentAcceptHivTesting,
          'HIV_RS_15': assessment.parentAcceptHivTestingDate,
          'HIV_RS_16': assessment.formalReferralMade,
          'HIV_RS_17': assessment.formalReferralMadeDate,
          'HIV_RS_18': assessment.formalReferralCompleted,
          'HIV_RS_18A': assessment.reasonForNotMakingReferral,
          'HIV_RS_18B': assessment.hivTestResult,
          'HIV_RS_21': assessment.referredForArt,
          'HIV_RS_22': assessment.referredForArtDate,
          'HIV_RS_23': assessment.artReferralCompleted,
          'HIV_RS_24': assessment.artReferralCompletedDate,
          'HIV_RA_3Q6': assessment.facilityOfArtEnrollment,
          'uuid': uuid,
          'form_date_synced': null,
          'message': null,
          'rejected': isRejected,
        },
      );
      if (isRejected == true) {
        var dio = Dio();
        var prefs = await SharedPreferences.getInstance();
        var accessToken = prefs.getString('access');
        String bearerAuth = "Bearer $accessToken";

        var updateUpstreamEndpoint = "${cpimsProdApiUrl}mobile/record_saved";
        var response = await dio.post(updateUpstreamEndpoint,
            data: {"record_id": uuid, "saved": 1, "form_type": "hrs"},
            options: Options(headers: {"Authorization": bearerAuth}));
        if (response.statusCode == 200) {
          debugPrint("Data sent successfully");
        } else {
          debugPrint("Data not sent");
        }
      }
      return true;
    } catch (e) {
      debugPrint(e.toString());
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> fetchHRSFormData() async {
    try {
      final db = await LocalDb.instance.database;

      final hrsData = await db.query(HRSForms,
          where:
              '"rejected" = 0 AND (form_date_synced IS NULL OR form_date_synced = "")');

      List<Map<String, dynamic>> updatedHRSData = [];

      for (Map hrsDataRow in hrsData) {
        // Modify values in the HRS form data
        Map<String, dynamic> modifiedHRSDataRow = Map.from(hrsDataRow);
        for (String key in modifiedHRSDataRow.keys) {
          if (modifiedHRSDataRow[key] is String) {
            if (modifiedHRSDataRow[key].toLowerCase() == 'yes') {
              modifiedHRSDataRow[key] = 'AYES';
            } else if (modifiedHRSDataRow[key].toLowerCase() == 'no') {
              modifiedHRSDataRow[key] = 'ANNO';
            }
          }
        }

        String uuid = modifiedHRSDataRow['uuid'];

        // Fetch associated AppFormMetaData
        final AppFormMetaData appFormMetaData = await getAppFormMetaData(uuid);

        // Create a new map that includes modified HRS form data and AppFormMetaData
        Map<String, dynamic> updatedHRSDataRow = {
          ...modifiedHRSDataRow,
          'app_form_metadata': appFormMetaData.toJson(),
        };

        // Add the updated map to the list
        updatedHRSData.add(updatedHRSDataRow);
      }

      debugPrint("Updated HRS form data: ${jsonEncode(updatedHRSData)}");

      return updatedHRSData;
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching HRS form data: $e");
      }
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchRejectedHRSFormData() async {
    try {
      final db = await LocalDb.instance.database;

      final hrsData = await db.query(HRSForms, where: 'rejected = 1');

      List<Map<String, dynamic>> updatedHRSData = [];

      for (Map hrsDataRow in hrsData) {
        // Modify values in the HRS form data
        Map<String, dynamic> modifiedHRSDataRow = Map.from(hrsDataRow);
        for (String key in modifiedHRSDataRow.keys) {
          if (modifiedHRSDataRow[key] is String) {
            if (modifiedHRSDataRow[key].toLowerCase() == 'yes') {
              modifiedHRSDataRow[key] = 'AYES';
            } else if (modifiedHRSDataRow[key].toLowerCase() == 'no') {
              modifiedHRSDataRow[key] = 'ANNO';
            }
          }
        }

        String uuid = modifiedHRSDataRow['uuid'];

        // Fetch associated AppFormMetaData
        final AppFormMetaData appFormMetaData = await getAppFormMetaData(uuid);

        // Create a new map that includes modified HRS form data and AppFormMetaData
        Map<String, dynamic> updatedHRSDataRow = {
          ...modifiedHRSDataRow,
          'app_form_metadata': appFormMetaData.toJson(),
        };

        // Add the updated map to the list
        updatedHRSData.add(updatedHRSDataRow);
      }

      debugPrint("Updated HRS form data: ${jsonEncode(updatedHRSData)}");

      return updatedHRSData;
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching HRS form data: $e");
      }
      return [];
    }
  }

  Future<int> countHRSFormData() async {
    try {
      final db = await LocalDb.instance.database;
      final count = Sqflite.firstIntValue(await db.rawQuery(
          'SELECT COUNT(*) FROM "$HRSForms" WHERE ("form_date_synced" IS NULL OR "form_date_synced" = "") AND "rejected" = 0'));
      debugPrint("The count hrs is $count");
      return count ?? 0;
    } catch (e) {
      if (kDebugMode) {
        print("Error counting HRS form data: $e");
      }
      return 0;
    }
  }

  Future<int> countUnApprovedHRSFormData() async {
    try {
      final db = await LocalDb.instance.database;

      final count = Sqflite.firstIntValue(await db.rawQuery(
          'SELECT COUNT(*) FROM $HRSForms WHERE ("form_date_synced" IS NULL OR "form_date_synced" = "") AND "rejected" = 1'));

      return count ?? 0;
    } catch (e) {
      if (kDebugMode) {
        print("Error counting HRS form data: $e");
      }
      return 0;
    }
  }

  Future<int> countHRSFormDataDistinctByCareGiver() async {
    try {
      final db = await LocalDb.instance.database;

      final count = Sqflite.firstIntValue(await db.rawQuery(
          'SELECT COUNT(DISTINCT caregiver_cpims_id) FROM $HRSForms WHERE form_date_synced IS NULL OR form_date_synced = "" AND "rejected" = 0'));

      return count ?? 0;
    } catch (e) {
      if (kDebugMode) {
        print("Error counting HRS form data: $e");
      }
      return 0;
    }
  }

  Future<void> deleteHRSData(String id) async {
    final db = await LocalDb.instance.database;
    await db.delete(HRSForms, where: 'uuid = ?', whereArgs: [id]);
  }

  Future<void> updateHRSData(String id) async {
    final db = await LocalDb.instance.database;
    await db.update(HRSForms, {'form_date_synced': DateTime.now().toString()},
        where: 'uuid = ?', whereArgs: [id]);
  }

  Future<void> updateHMFData(String id) async {
    debugPrint("The uuid is $id and form is being accepted is here");
    final db = await LocalDb.instance.database;
    await db.update(HMForms, {'form_date_synced': DateTime.now().toString()},
        where: 'uuid = ?', whereArgs: [id]);
  }

  Future<void> updateGraduationData(String id) async {
    final db = await LocalDb.instance.database;
    await db.update(
        graduation_monitoring, {'form_date_synced': DateTime.now().toString()},
        where: 'uuid = ?', whereArgs: [id]);
  }

  // create HIVManagement table
  Future<void> createHMFForms(Database db, int version) async {
    const String createTableQuery = '''
    CREATE TABLE $HMForms (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      ovc_cpims_id TEXT,
      caregiver_cpims_id TEXT,
      HIV_MGMT_1_A TEXT,
      HIV_MGMT_1_B TEXT,
      HIV_MGMT_1_C TEXT,
      HIV_MGMT_1_D TEXT,
      HIV_MGMT_1_E TEXT,
      HIV_MGMT_1_E_DATE TEXT,
      HIV_MGMT_1_F TEXT,
      HIV_MGMT_1_F_DATE TEXT,
      HIV_MGMT_1_G TEXT,
      HIV_MGMT_1_G_DATE TEXT,
      HIV_MGMT_2_A TEXT,
      HIV_MGMT_2_B TEXT,
      HIV_MGMT_2_C TEXT,
      HIV_MGMT_2_D TEXT,
      HIV_MGMT_2_E TEXT,
      HIV_MGMT_2_F TEXT,
      HIV_MGMT_2_G TEXT,
      HIV_MGMT_2_H_2 TEXT,
      HIV_MGMT_2_H_3 TEXT,
      HIV_MGMT_2_H_4 TEXT,
      HIV_MGMT_2_H_5 TEXT,
      HIV_MGMT_2_I_1 TEXT,
      HIV_MGMT_2_I_DATE TEXT,
      HIV_MGMT_2_J TEXT,
      HIV_MGMT_2_K TEXT,
      HIV_MGMT_2_L_1 TEXT,
      HIV_MGMT_2_L_2 TEXT,
      HIV_MGMT_2_M TEXT,
      HIV_MGMT_2_N TEXT,
      HIV_MGMT_2_O_1 TEXT,
      HIV_MGMT_2_O_2 TEXT,
      HIV_MGMT_2_P TEXT,
      HIV_MGMT_2_Q TEXT,
      HIV_MGMT_2_R TEXT,
      HIV_MGMT_2_S TEXT,
      uuid TEXT,
      form_date_synced TEXT NULL,
      message TEXT NULL,
      rejected BOOLEAN 
    )
  ''';

    try {
      await db.execute(createTableQuery);
      if (kDebugMode) {
        debugPrint(
            "------------------Function ----Creating HMF Forms---------------------------");
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            "-------------------Error HMF Forms---------------------------$e");
      }
    }
  }

  Future<bool> insertHMFFormData(
    String? cpmisId,
    String? caregiverCpimsId,
    HivManagementFormModel hivManagementFormModel,
    String? uuid,
    String? startTimeInterview,
    String? formType,
    bool? isRejected,
    String? rejectedMessage,
  ) async {
    try {
      final db = await instance.database;
      if (uuid != null || startTimeInterview != null) {
        await insertAppFormMetaData(uuid, startTimeInterview, formType);
      }
      await db.insert(
        HMForms,
        {
          'ovc_cpims_id': cpmisId,
          'caregiver_cpims_id': caregiverCpimsId,
          'HIV_MGMT_1_A': hivManagementFormModel.dateHIVConfirmedPositive,
          'HIV_MGMT_1_B': hivManagementFormModel.dateTreatmentInitiated,
          'HIV_MGMT_1_C': hivManagementFormModel.baselineHEILoad,
          'HIV_MGMT_1_D': hivManagementFormModel.dateStartedFirstLine,
          'HIV_MGMT_1_E': hivManagementFormModel.arvsSubWithFirstLine,
          'HIV_MGMT_1_E_DATE': hivManagementFormModel.arvsSubWithFirstLineDate,
          'HIV_MGMT_1_F': hivManagementFormModel.switchToSecondLine,
          'HIV_MGMT_1_F_DATE': hivManagementFormModel.switchToSecondLineDate,
          'HIV_MGMT_1_G': hivManagementFormModel.switchToThirdLine,
          'HIV_MGMT_1_G_DATE': hivManagementFormModel.switchToThirdLineDate,
          'HIV_MGMT_2_A': hivManagementFormModel.visitDate,
          'HIV_MGMT_2_B': hivManagementFormModel.durationOnARTs,
          'HIV_MGMT_2_C': hivManagementFormModel.height,
          'HIV_MGMT_2_D': hivManagementFormModel.mUAC,
          'HIV_MGMT_2_E': hivManagementFormModel.arvDrugsAdherence,
          'HIV_MGMT_2_F': hivManagementFormModel.arvDrugsDuration,
          'HIV_MGMT_2_G': hivManagementFormModel.adherenceCounseling,
          'HIV_MGMT_2_H_2': hivManagementFormModel.treatmentSupporter,
          'HIV_MGMT_2_H_3': hivManagementFormModel.treatmentSupporterSex,
          'HIV_MGMT_2_H_4': hivManagementFormModel.treatmentSupporterAge,
          'HIV_MGMT_2_H_5': hivManagementFormModel.treatmentSupporterHIVStatus,
          'HIV_MGMT_2_I_1': hivManagementFormModel.viralLoadResults,
          'HIV_MGMT_2_I_DATE': hivManagementFormModel.labInvestigationsDate,
          'HIV_MGMT_2_J':
              hivManagementFormModel.detectableViralLoadInterventions,
          'HIV_MGMT_2_K': hivManagementFormModel.disclosure,
          'HIV_MGMT_2_L_1': hivManagementFormModel.mUACScore,
          'HIV_MGMT_2_L_2': hivManagementFormModel.zScore,
          'HIV_MGMT_2_M': hivManagementFormModel.nutritionalSupport.join(', '),
          'HIV_MGMT_2_N': hivManagementFormModel.supportGroupStatus,
          'HIV_MGMT_2_O_1': hivManagementFormModel.nhifEnrollment,
          'HIV_MGMT_2_O_2': hivManagementFormModel.nhifEnrollmentStatus,
          'HIV_MGMT_2_P': hivManagementFormModel.referralServices,
          'HIV_MGMT_2_Q': hivManagementFormModel.nextAppointmentDate,
          'HIV_MGMT_2_R': hivManagementFormModel.peerEducatorName,
          'HIV_MGMT_2_S': hivManagementFormModel.peerEducatorContact,
          'uuid': uuid,
          'form_date_synced': null,
          'message': rejectedMessage,
          'rejected': isRejected,
        },
      );
      if (isRejected == true) {
        var dio = Dio();
        var prefs = await SharedPreferences.getInstance();
        var accessToken = prefs.getString('access');
        String bearerAuth = "Bearer $accessToken";

        var updateUpstreamEndpoint = "${cpimsProdApiUrl}mobile/record_saved";
        var response = await dio.post(updateUpstreamEndpoint,
            data: {"record_id": uuid, "saved": 1, "form_type": "hmf"},
            options: Options(headers: {"Authorization": bearerAuth}));
        if (response.statusCode == 200) {
          debugPrint("Data sent successfully");
        } else {
          debugPrint("Data not sent");
        }
      }

      return true;
    } catch (e) {
      debugPrint(e.toString());
      return false; // Exception occurred during form data insert
    }
  }

  // todo check on this function

  Future<List<Map<String, dynamic>>> fetchHMFFormData() async {
    try {
      final db = await LocalDb.instance.database;

      final hmfFormData = await db.query(HMForms,
          where:
              '"rejected" = 0 AND (form_date_synced IS NULL OR form_date_synced = "")');

      List<Map<String, dynamic>> updatedHMFFormData = [];

      for (Map<String, dynamic> hmfDataRow in hmfFormData) {
        // Create a mutable copy of hmfDataRow
        Map<String, dynamic> mutableHmfDataRow = Map.from(hmfDataRow);

        // Loop through the formData map and apply modifications
        mutableHmfDataRow.forEach((key, value) {
          if ((value == "Yes") || (value == true)) {
            mutableHmfDataRow[key] = convertBooleanStringToDBBoolen("Yes");
          } else if ((value == "No") || (value == false)) {
            mutableHmfDataRow[key] = convertBooleanStringToDBBoolen("No");
          }
        });

        // Convert "Yes" to "AYES" and "No" to "ANO" for specific fields
        _convertYesNoToAYESANO(mutableHmfDataRow, 'your_field_name');
        // Add more fields if needed

        String uuid = mutableHmfDataRow['uuid'];

        // restructure nutrition support field
        dynamic nutritionalSupportData = mutableHmfDataRow['HIV_MGMT_2_M'];

        if (nutritionalSupportData is String) {
          // Remove leading and trailing whitespace and split by comma and space
          List<String> nutritionalSupportList = nutritionalSupportData
              .trim()
              .split(', ')
              .map((value) => value.replaceAll("'", '')) // Remove single quotes
              .toList();

          // Update the copy of the record with the new list
          mutableHmfDataRow['HIV_MGMT_2_M'] = nutritionalSupportList;
        } else if (nutritionalSupportData is List<String>) {
          // The data is already a list of strings, do nothing
        } else {
          // Handle other types if needed
        }

        // Fetch associated AppFormMetaData
        final AppFormMetaData appFormMetaData = await getAppFormMetaData(uuid);

        Map<String, dynamic> updatedHMFDataRow = {
          ...mutableHmfDataRow,
          'app_form_metadata': appFormMetaData.toJson(),
        };

        // Add the updated map to the list
        updatedHMFFormData.add(updatedHMFDataRow);
      }

      debugPrint("Updated HMF form data: $updatedHMFFormData");
      return updatedHMFFormData;
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching HMF form data: $e");
      }
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchRejectedHMFFormData() async {
    try {
      final db = await LocalDb.instance.database;
      final hmfFormData = await db.query(HMForms, where: 'rejected = 1');

      List<Map<String, dynamic>> updatedHMFFormData = [];

      for (Map<String, dynamic> hmfDataRow in hmfFormData) {
        // Create a mutable copy of hmfDataRow
        Map<String, dynamic> mutableHmfDataRow = Map.from(hmfDataRow);

        // Loop through the formData map and apply modifications
        mutableHmfDataRow.forEach((key, value) {
          if ((value == "Yes") || (value == true)) {
            mutableHmfDataRow[key] = convertBooleanStringToDBBoolen("Yes");
          } else if ((value == "No") || (value == false)) {
            mutableHmfDataRow[key] = convertBooleanStringToDBBoolen("No");
          }
        });

        // Convert "Yes" to "AYES" and "No" to "ANO" for specific fields
        _convertYesNoToAYESANO(mutableHmfDataRow, 'your_field_name');
        // Add more fields if needed

        String uuid = mutableHmfDataRow['uuid'];

        // restructure nutrition support field
        dynamic nutritionalSupportData = mutableHmfDataRow['HIV_MGMT_2_M'];

        if (nutritionalSupportData is String) {
          // Remove leading and trailing whitespace and split by comma and space
          List<String> nutritionalSupportList = nutritionalSupportData
              .trim()
              .split(', ')
              .map((value) => value.replaceAll("'", '')) // Remove single quotes
              .toList();

          // Update the copy of the record with the new list
          mutableHmfDataRow['HIV_MGMT_2_M'] = nutritionalSupportList;
        } else if (nutritionalSupportData is List<String>) {
          // The data is already a list of strings, do nothing
        } else {
          // Handle other types if needed
        }

        // Fetch associated AppFormMetaData
        final AppFormMetaData appFormMetaData = await getAppFormMetaData(uuid);

        Map<String, dynamic> updatedHMFDataRow = {
          ...mutableHmfDataRow,
          'app_form_metadata': appFormMetaData.toJson(),
        };

        // Add the updated map to the list
        updatedHMFFormData.add(updatedHMFDataRow);
      }

      debugPrint("UnApproved HMF: $updatedHMFFormData");
      return updatedHMFFormData;
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching HMF form data: $e");
      }
      return [];
    }
  }

// Function to convert "Yes" to "AYES" and "No" to "ANO" for specific field
  void _convertYesNoToAYESANO(Map<String, dynamic> data, String fieldName) {
    if (data.containsKey(fieldName) && data[fieldName] is String) {
      if (data[fieldName].toLowerCase() == 'yes' || data[fieldName] == true) {
        data[fieldName] = 'AYES';
      } else if (data[fieldName].toLowerCase() == 'no' ||
          data[fieldName] == false) {
        data[fieldName] = 'ANO';
      }
    }
  }

  Future<int> countHMFFormData() async {
    try {
      final db = await LocalDb.instance.database;
      final count = Sqflite.firstIntValue(await db.rawQuery(
          'SELECT COUNT(*) FROM "$HMForms" WHERE ("form_date_synced" IS NULL OR "form_date_synced" = "") AND "rejected" = 0'));
      return count ?? 0;
    } catch (e) {
      if (kDebugMode) {
        print("Error counting HMF form data: $e");
      }
      return 0;
    }
  }

  Future<int> countUnApprovedHMFFormData() async {
    try {
      final db = await LocalDb.instance.database;
      final count = Sqflite.firstIntValue(await db.rawQuery(
          'SELECT COUNT(*) FROM "$HMForms" WHERE ("form_date_synced" IS NULL OR "form_date_synced" = "") AND "rejected" = 1'));
      return count ?? 0;
    } catch (e) {
      if (kDebugMode) {
        print("Error counting HMF form data: $e");
      }
      return 0;
    }
  }

  Future<int> countHMFFormDataDistinctByCareGiver() async {
    try {
      final db = await LocalDb.instance.database;
      final count = Sqflite.firstIntValue(await db.rawQuery(
          'SELECT COUNT(DISTINCT "caregiver_cpims_id") FROM "$HMForms" WHERE ("form_date_synced" IS NULL OR "form_date_synced" = "") AND "rejected" = 0'));
      return count ?? 0;
    } catch (e) {
      if (kDebugMode) {
        print("Error counting HMF form data: $e");
      }
      return 0;
    }
  }

  Future<bool> deleteUnApprovedHMFData(String id) async {
    final db = await LocalDb.instance.database;
    await db.delete(HMForms, where: 'uuid = ?', whereArgs: [id]);
    return true;
  }

  Future<bool> deleteUnApprovedHRSFData(String id) async {
    final db = await LocalDb.instance.database;
    await db.delete(HRSForms, where: 'uuid = ?', whereArgs: [id]);
    return true;
  }

  Future<void> insertOvcSubpopulationData(String uuid, String cpimsId,
      String dateOfAssessment, List<CheckboxQuestion> questions) async {
    final db = await instance.database;
    for (var question in questions) {
      await db.insert(
          ovcsubpopulation,
          {
            'uuid': uuid,
            'cpims_id': cpimsId,
            'criteria': question.questionID,
            'date_of_event': dateOfAssessment,
            'form_date_synced': null
          },
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<List<Map<String, dynamic>>> fetchOvcSubPopulationData() async {
    final db = await LocalDb.instance.database;
    final result = await db.query(ovcsubpopulation);
    return result;
  }

  Future<void> insertAppFormMetaData(
    uuid,
    startOfInterview,
    formType,
    // {required BuildContext context}
  ) async {
    AppFormMetaData appFormMetaData =
        AppFormMetaData(formId: uuid, startOfInterview: startOfInterview);

    await insertAppFormMetaDataFromMetaData(appFormMetaData, formType);
  }

  Future<void> insertAppFormMetaDataFromMetaData(
    AppFormMetaData appFormMetaData,
    formType,
    // {required BuildContext context}
  ) async {
    final db = await instance.database;
    // if(context.mounted){
    try {
      Position userLocation = await getUserLocation(
          // context: context
          ); // Await the location here
      String lat =
          appFormMetaData.location_lat ?? userLocation.latitude.toString();
      String longitude =
          appFormMetaData.location_long ?? userLocation.longitude.toString();
      String deviceId = appFormMetaData.device_id ?? await getDeviceId();
      await db.insert(
        appFormMetaDataTable,
        {
          'form_id': appFormMetaData.formId,
          'location_lat': lat,
          'location_long': longitude,
          'start_of_interview': appFormMetaData.startOfInterview,
          'end_of_interview': DateTime.now().toIso8601String(),
          'form_type': formType,
          'device_id': deviceId
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> insertUnapprovedAppFormMetaData(
      uuid, AppFormMetaData metadata, formType) async {
    final db = await instance.database;
    await db.insert(
      appFormMetaDataTable,
      {
        'form_id': uuid,
        'location_lat': metadata.location_lat,
        'location_long': metadata.location_long,
        'start_of_interview': metadata.startOfInterview,
        'end_of_interview': metadata.endOfInterview,
        'form_type': formType,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // insert formData(either form1a or form1b)
  Future<void> insertForm1Data(
    String formType,
    formData,
    metadata,
    id,
  ) async {
    try {
      final db = await instance.database;

      //insert app form metadata
      await insertAppFormMetaDataFromMetaData(metadata, formType
          // context: context
          );
      final formId = await db.insert(
        form1Table,
        {
          'ovc_cpims_id': formData.ovcCpimsId,
          'date_of_event': formData.dateOfEvent,
          'caregiver_cpims_id': formData.caregiverCpimsId,
          'form_type': formType,
          'form_date_synced': null,
          'form_uuid': id,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      // //insert app form metadata
      // await insertAppFormMetaData(uuid, metadata.startOfInterview, formType,
      //     // context: context
      // );

      // insert services
      for (var service in formData.services) {
        await db.insert(
          form1ServicesTable,
          {
            'form_id': formId,
            'domain_id': service.domainId,
            'service_id': service.serviceId,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      for (var criticalEvent in formData.criticalEvents) {
        await db.insert(
          form1CriticalEventsTable,
          {
            'form_id': formId,
            'event_id': criticalEvent.eventId,
            'event_date': criticalEvent.eventDate,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error inserting form1 data: $e');
      }
      rethrow;
    }
  }

  // insert formData(either form1a or form1b)
  Future<void> insertUnapprovedForm1Data(
      String formType, UnapprovedForm1DataModel formData, metadata, id) async {
    try {
      final db = await instance.database;

      // Check if data already exists
      final existingData = await db.query(
        unapprovedForm1Table,
        where: 'form_uuid = ?',
        whereArgs: [id],
      );

      // If data does not exist, insert it
      if (existingData.isEmpty) {
        final formId = await db.insert(
          unapprovedForm1Table,
          {
            'ovc_cpims_id': formData.ovcCpimsId,
            'date_of_event': formData.dateOfEvent,
            'form_type': formType,
            'form_uuid': id,
            Form1.message: formData.message
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        //insert app form metadata
        await insertUnapprovedAppFormMetaData(id, metadata, formType);

        // insert services
        for (var service in formData.services) {
          await db.insert(
            form1ServicesTable,
            {
              Form1Services.unapprovedFormId: formId,
              'domain_id': service.domainId,
              'service_id': service.serviceId,
              Form1Services.message: service.message
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        for (var criticalEvent in formData.criticalEvents) {
          await db.insert(
            form1CriticalEventsTable,
            {
              Form1Services.unapprovedFormId: formId,
              'event_id': criticalEvent.eventId,
              'event_date': criticalEvent.eventDate,
              Form1CriticalEvents.message: criticalEvent.message
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        var dio = Dio();
        var prefs = await SharedPreferences.getInstance();
        var accessToken = prefs.getString('access');
        String bearerAuth = "Bearer $accessToken";

        var updateUpstreamEndpoint = "${cpimsProdApiUrl}mobile/record_saved";
        var response = await dio.post(updateUpstreamEndpoint,
            data: {
              "record_id": id,
              "saved": 1,
              "form_type": formType == "form1a" ? "F1A" : "F1B"
            },
            options: Options(headers: {"Authorization": bearerAuth}));
        if (response.statusCode == 200) {
          debugPrint("Data sent successfully");
        } else {
          debugPrint("Data not sent");
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error inserting form1 data: $e');
      }
    }
  }

  Future<List<Map<String, dynamic>>> queryAllForm1Rows(String formType) async {
    try {
      final db = await instance.database;
      const sql =
          'SELECT * FROM $form1Table WHERE form_type = ? AND form_date_synced IS NULL';
      final List<Map<String, dynamic>> form1Rows =
          await db.rawQuery(sql, [formType]);

      List<Map<String, dynamic>> updatedForm1Rows = [];

      for (var form1row in form1Rows) {
        int formId = form1row['local_id'];

        // Fetch associated services
        final List<Map<String, dynamic>> services = await db.query(
          form1ServicesTable,
          where: '${Form1Services.formId} = ?',
          whereArgs: [formId],
        );

        // Fetch associated critical events
        final List<Map<String, dynamic>> criticalEvents = await db.query(
          form1CriticalEventsTable,
          where: '${Form1CriticalEvents.formId} = ?',
          whereArgs: [formId],
        );

        final AppFormMetaData appFormMetaData =
            await getAppFormMetaData(form1row['form_uuid']);

        // Create a new map that includes existing form1row data, services, critical_events, and ID
        Map<String, dynamic> updatedForm1Row = {
          ...form1row,
          'services': services,
          'critical_events': criticalEvents,
          'app_form_metadata': appFormMetaData.toJson(),
          'device_id': await getDeviceId(),
        };
        // Add the updated map to the list
        updatedForm1Rows.add(updatedForm1Row);
      }
      debugPrint("Updated form1 rows HERE: $updatedForm1Rows");

      return updatedForm1Rows;
    } catch (e) {
      if (kDebugMode) {
        print("Error querying form1 data here: $e");
      }
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> queryAllUnapprovedForm1Rows(
      String formType) async {
    try {
      final db = await instance.database;
      const sql = 'SELECT * FROM $unapprovedForm1Table WHERE form_type = ?';
      final List<Map<String, dynamic>> form1Rows =
          await db.rawQuery(sql, [formType]);

      List<Map<String, dynamic>> updatedForm1Rows = [];

      for (var form1row in form1Rows) {
        int formId = form1row['local_id'];

        // Fetch associated services
        final List<Map<String, dynamic>> services = await db.query(
          form1ServicesTable,
          where: '${Form1Services.unapprovedFormId} = ?',
          whereArgs: [formId],
        );

        // Fetch associated critical events
        final List<Map<String, dynamic>> criticalEvents = await db.query(
          form1CriticalEventsTable,
          where: '${Form1CriticalEvents.unapprovedFormId} = ?',
          whereArgs: [formId],
        );

        final AppFormMetaData appFormMetaData =
            await getAppFormMetaData(form1row['form_uuid']);

        // Create a new map that includes existing form1row data, services, critical_events, and ID
        Map<String, dynamic> updatedForm1Row = {
          ...form1row,
          'services': services,
          'critical_events': criticalEvents,
          'app_form_metadata': appFormMetaData.toJson(),
          'device_id': await getDeviceId(),
        };
        // Add the updated map to the list
        updatedForm1Rows.add(updatedForm1Row);
      }
      debugPrint("Updated form1 rows: $updatedForm1Rows");

      return updatedForm1Rows;
    } catch (e) {
      if (kDebugMode) {
        print("Error querying form1 data: $e");
      }
      return [];
    }
  }

  Future<CaseLoadModel> getCaseLoad(int id) async {
    try {
      final db = await instance.database;
      const sql = 'SELECT * FROM $caseloadTable WHERE ${OvcFields.cboID} = ?';
      final List<Map<String, dynamic>> form1Rows = await db.rawQuery(sql, [id]);

      return CaseLoadModel.fromJson(form1Rows.first);
    } catch (e) {
      if (kDebugMode) {
        print("Error querying form1 data: $e");
      }
      return CaseLoadModel();
    }
  }

  Future<int?> queryForm1UnsyncedForms(String formType) async {
    try {
      final db = await instance.database;
      const sql =
          'SELECT COUNT(*) FROM $form1Table WHERE form_type = ? AND form_date_synced IS NULL';
      final List<Map<String, dynamic>> result =
          await db.rawQuery(sql, [formType]);

      if (result.isNotEmpty) {
        return Sqflite.firstIntValue(result);
      } else {
        return 0; // Return 0 if no count is found.
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error querying form1 count: $e");
      }
      return 0; // Return 0 if there is an error.
    }
  }

  Future<int?> queryForm1UnApprovedForm1(String formType) async {
    try {
      final db = await instance.database;
      const sql =
          'SELECT COUNT(*) FROM $unapprovedForm1Table WHERE form_type = ?';
      final List<Map<String, dynamic>> result =
          await db.rawQuery(sql, [formType]);

      if (result.isNotEmpty) {
        return Sqflite.firstIntValue(result);
      } else {
        return 0; // Return 0 if no count is found.
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error querying form1 count: $e");
      }
      return 0; // Return 0 if there is an error.
    }
  }

  Future<int?> countFormOneByDistinctCareGiver(String formType) async {
    try {
      final db = await instance.database;
      const sql =
          'SELECT COUNT(DISTINCT caregiver_cpims_id) FROM $form1Table WHERE form_type = ? AND form_date_synced IS NULL';
      final List<Map<String, dynamic>> result =
          await db.rawQuery(sql, [formType]);

      if (result.isNotEmpty) {
        return Sqflite.firstIntValue(result);
      } else {
        return 0; // Return 0 if no count is found.
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error querying form1 count: $e");
      }
      return 0; // Return 0 if there is an error.
    }
  }

  Future<Stream<int>> queryForm1UnsyncedFormsStream(String formType) async {
    final controller = StreamController<int>();

    try {
      final db = await instance.database;
      const sql =
          'SELECT COUNT(*) FROM $form1Table WHERE form_type = ? AND form_date_synced IS NULL';
      final List<Map<String, dynamic>> result =
          await db.rawQuery(sql, [formType]);

      if (result.isNotEmpty) {
        controller.add(Sqflite.firstIntValue(result)!);
      } else {
        controller.add(0); // Return 0 if no count is found.
      }

      controller.close(); // Close the stream when the operation is complete.
    } catch (e) {
      if (kDebugMode) {
        print("Error querying form1 count: $e");
      }
      controller.addError(e);
      controller.close();
    }

    return controller.stream;
  }

  // get a single row(form 1a or 1b)
  Future<bool> deleteUnApprovedForm1Data(int id) async {
    try {
      final db = await instance.database;
      final queryResults = await db.query(
        unapprovedForm1Table,
        where: '${Form1.localId} = ?',
        whereArgs: [id],
      );

      if (queryResults.isNotEmpty) {
        final form1Id = queryResults.first[Form1.localId] as int;
        await db.delete(
          form1ServicesTable,
          where: '${Form1Services.unapprovedFormId} = ?',
          whereArgs: [form1Id],
        );
        await db.delete(
          form1CriticalEventsTable,
          where: '${Form1CriticalEvents.unapprovedFormId} = ?',
          whereArgs: [form1Id],
        );
        final rowsAffected = await db.delete(
          unapprovedForm1Table,
          where: '${Form1.localId} = ?',
          whereArgs: [form1Id],
        );
        return rowsAffected > 0;
      }
      return false;
    } catch (e) {
      debugPrint("Error deleting form1 data: $e");
    }
    return false;
  }

  // get a single row(form 1a or 1b)
  Future<bool> deleteForm1Data(String formType, int id) async {
    try {
      final db = await instance.database;
      final queryResults = await db.query(
        form1Table,
        where: '${Form1.localId} = ?',
        whereArgs: [id],
      );

      if (queryResults.isNotEmpty) {
        final form1Id = queryResults.first[Form1.localId] as int;
        await db.delete(
          form1ServicesTable,
          where: 'form_id = ?',
          whereArgs: [form1Id],
        );
        await db.delete(
          form1CriticalEventsTable,
          where: 'form_id = ?',
          whereArgs: [form1Id],
        );
        final rowsAffected = await db.delete(
          form1Table,
          where: '${Form1.localId} = ?',
          whereArgs: [form1Id],
        );
        return rowsAffected > 0;
      }
      return false;
    } catch (e) {
      debugPrint("Error deleting form1 data: $e");
    }
    return false;
  }

  //update form1 date_synced column
  Future<void> updateForm1DataDateSync(String formType, int id) async {
    try {
      final db = await instance.database;
      final queryResults = await db.query(
        form1Table,
        where: '${Form1.localId} = ?',
        whereArgs: [id],
      );

      if (queryResults.isNotEmpty) {
        final form1Id = queryResults.first[Form1.localId] as int;
        await db.update(
          form1Table,
          {
            'form_date_synced': DateTime.now().toString(),
          },
          where: '${Form1.localId} = ?',
          whereArgs: [form1Id],
        );
      }
    } catch (e) {
      debugPrint("Error updating form1 data: $e");
    }
  }

  //new insert case plan
  Future<bool> insertCasePlanNew(CasePlanModel casePlan, String formUuid,
      String startTimeOfInterview) async {
    try {
      final db = await instance.database;

      await insertAppFormMetaData(formUuid, startTimeOfInterview, "caseplan");

      await db.transaction((txn) async {
        final casePlanId = await txn.insert(
          casePlanTable,
          {
            'ovc_cpims_id': casePlan.ovcCpimsId,
            'date_of_event': casePlan.dateOfEvent,
            'form_date_synced': null,
            'uuid': formUuid,
            'caregiver_cpims_id': casePlan.caregiverCpimsId,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        for (var service in casePlan.services) {
          final serviceIdList = service.serviceIds.join(',');
          final responsibleIdList = service.responsibleIds.join(',');

          await txn.insert(
            casePlanServicesTable,
            {
              'form_id': casePlanId,
              'domain_id': service.domainId,
              'goal_id': service.goalId,
              'gap_id': service.gapId,
              'priority_id': service.priorityId,
              'results_id': service.resultsId,
              'reason_id': service.reasonId,
              'completion_date': service.completionDate ?? '',
              'service_ids': serviceIdList,
              'responsible_ids': responsibleIdList,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });

      return true;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error inserting case plan: $e');
        print('Stack trace: $stackTrace');
      }
      return false;
    }
  }

  Future<CasePlanModel?> getCasePlanById(String ovcCpimsId) async {
    try {
      // Retrieve the main case plan information
      final db = await instance.database;
      final mainQueryResult = await db.query(
        casePlanTable,
        where: '${CasePlan.ovcCpimsId} = ?',
        whereArgs: [ovcCpimsId],
      );

      if (mainQueryResult.isNotEmpty) {
        final casePlanId = mainQueryResult.first[CasePlan.id] as int;

        // Retrieve the associated services
        final serviceQueryResult = await db.query(
          casePlanTable,
          where: 'form_id = ?',
          whereArgs: [casePlanId],
        );

        List<CasePlanServiceModel> services = [];
        for (var serviceRow in serviceQueryResult) {
          services.add(CasePlanServiceModel(
            domainId: serviceRow['domain_id'] as String,
            serviceIds: (serviceRow['service_ids'] as String).split(','),
            // Parse comma-separated service IDs
            goalId: serviceRow[CasePlanServices.goalId] as String,
            gapId: serviceRow[CasePlanServices.gapId] as String,
            priorityId: serviceRow[CasePlanServices.priorityId] as String,
            responsibleIds:
                (serviceRow['responsible_ids'] as String).split(','),
            // Parse comma-separated responsible IDs
            resultsId: serviceRow[CasePlanServices.resultsId] as String,
            reasonId: serviceRow[CasePlanServices.reasonId] as String,
            completionDate:
                serviceRow[CasePlanServices.completionDate] as String,
          ));
        }

        // Create and return the CasePlanModel instance
        return CasePlanModel(
          caregiverCpimsId:
              mainQueryResult.first[CasePlan.caregiverId] as String,
          ovcCpimsId: mainQueryResult.first[CasePlan.ovcCpimsId] as String,
          dateOfEvent: mainQueryResult.first[CasePlan.dateOfEvent] as String,
          services: services,
        );
      }

      return null; // Return null if case plan not found
    } catch (e) {
      if (kDebugMode) {
        print('Error retrieving case plan: $e');
      }
      return null;
    }
  }

  Future<List<CasePlanModel>> getAllUnsyncedCasePlans() async {
    try {
      final db = await instance.database;

      // Use a raw SQL query to select all rows from the table
      final queryResult = await db.rawQuery(
          'SELECT * FROM $casePlanTable WHERE form_date_synced IS NULL');

      List<CasePlanModel> casePlans = [];

      for (var row in queryResult) {
        final casePlanId = row[CasePlan.id] as int;

        // Fetch associated AppFormMetaData
        final AppFormMetaData appFormMetaData =
            await getAppFormMetaData(row[CasePlan.uuid] as String);
        debugPrint("The id is ${row[CasePlan.uuid]}");
        debugPrint("tHE app form meatdata is ${appFormMetaData.toJson()}");

        // Retrieve the associated services
        final serviceQueryResult = await db.query(
          casePlanServicesTable,
          where: 'form_id = ?',
          whereArgs: [casePlanId],
        );

        List<CasePlanServiceModel> services = [];
        for (var serviceRow in serviceQueryResult) {
          services.add(CasePlanServiceModel(
            domainId: serviceRow['domain_id'] as String,
            serviceIds: (serviceRow['service_ids'] as String).split(','),
            goalId: serviceRow[CasePlanServices.goalId] as String,
            gapId: serviceRow[CasePlanServices.gapId] as String,
            priorityId: serviceRow[CasePlanServices.priorityId] as String,
            responsibleIds:
                (serviceRow['responsible_ids'] as String).split(','),
            resultsId: serviceRow[CasePlanServices.resultsId] as String,
            reasonId: serviceRow[CasePlanServices.reasonId] as String,
            completionDate:
                serviceRow[CasePlanServices.completionDate] as String,
          ));
        }

        // casePlans.add(CasePlanModel(
        //   id: row[CasePlan.id] as int,
        //   ovcCpimsId: row[CasePlan.ovcCpimsId] as String,
        //   dateOfEvent: row[CasePlan.dateOfEvent] as String,
        //   services: services,
        //   appFormMetaData: appFormMetaData,
        // ));

        casePlans.add(CasePlanModel(
          id: row[CasePlan.id] as int,
          caregiverCpimsId: row[CasePlan.caregiverId] as String,
          ovcCpimsId: row[CasePlan.ovcCpimsId] as String,
          dateOfEvent: row[CasePlan.dateOfEvent] as String,
          services: services,
          appFormMetaData: appFormMetaData,
        ));
      }

      debugPrint("Case plans are: ${casePlans.toString()}");

      return casePlans;
    } catch (e) {
      if (kDebugMode) {
        print('Error retrieving case plans: $e');
      }
      return [];
    }
  }

  Future<int> getUnsyncedCasePlanCount() async {
    try {
      final db = await instance.database;
      final queryResult = await db.rawQuery(
          'SELECT COUNT(*) FROM $casePlanTable WHERE form_date_synced IS NULL');

      if (queryResult.isEmpty) {
        return 0; // No unsynced case plans found
      }

      // Extract the count from the first row
      final count = queryResult.first.values.first as int;

      return count;
    } catch (e) {
      debugPrint('Error retrieving unsynced case plan count: $e');
      return 0; // Handle the error and return 0
    }
  }

  Future<int> getUnApprovedCasePlanCount() async {
    try {
      final db = await instance.database;
      final queryResult =
          await db.rawQuery('SELECT COUNT(*) FROM unapproved_cpt');

      if (queryResult.isEmpty) {
        return 0; // No unsynced case plans found
      }

      // Extract the count from the first row
      final count = queryResult.first.values.first as int;

      return count;
    } catch (e) {
      debugPrint('Error retrieving unsynced case plan count: $e');
      return 0; // Handle the error and return 0
    }
  }

  Future<int> getUnsyncedCasePlanCountDistinctByCareGiverId() async {
    try {
      final db = await instance.database;
      final queryResult = await db.rawQuery(
          'SELECT COUNT(DISTINCT caregiver_cpims_id) FROM $casePlanTable WHERE form_date_synced IS NULL');
      if (queryResult.isEmpty) {
        return 0; // No unsynced case plans found
      }
      // Extract the count from the first row
      final count = queryResult.first.values.first as int;
      return count;
    } catch (e) {
      debugPrint('Error retrieving unsynced case plan count: $e');
      return 0; // Handle the error and return 0
    }
  }

  Future<bool> deleteCasePlan(String ovcCpimsId) async {
    try {
      // Retrieve the case plan id to be deleted
      final db = await instance.database;
      final casePlanIdQueryResult = await db.query(
        casePlanTable,
        columns: [CasePlan.id],
        where: '${CasePlan.ovcCpimsId} = ?',
        whereArgs: [ovcCpimsId],
      );

      if (casePlanIdQueryResult.isNotEmpty) {
        final casePlanId = casePlanIdQueryResult.first[CasePlan.id] as int;

        // Delete associated services first
        await db.delete(
          casePlanServicesTable,
          where: 'form_id = ?',
          whereArgs: [casePlanId],
        );

        // Delete the main case plan entry
        final rowsAffected = await db.delete(
          casePlanTable,
          where: '${CasePlan.id} = ?',
          whereArgs: [casePlanId],
        );

        return rowsAffected >
            0; // Return true if any rows were affected (case plan was deleted)
      }

      return false; // Return false if case plan was not found
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting case plan: $e');
      }
      return false;
    }
  }

  Future<int> getUnsyncedCparaFormCount() async {
    final db = await instance.database;
    try {
      List<Map<String, dynamic>> countResult = await db.rawQuery(
          "SELECT COUNT(id) AS count FROM Form WHERE form_date_synced IS NULL");

      if (countResult.isNotEmpty) {
        int count = countResult[0]['count'];
        return count;
      } else {
        return 0;
      }
    } catch (err) {
      throw ("Could Not Get Unsynced Forms Count: ${err.toString()}");
    }
  }

  Future<int> getUnApprovedCparaFormCount() async {
    final db = await instance.database;
    try {
      List<Map<String, dynamic>> countResult =
          await db.rawQuery("SELECT COUNT(id) AS count FROM UnapprovedCPARA");

      if (countResult.isNotEmpty) {
        int count = countResult[0]['count'];
        return count;
      } else {
        return 0;
      }
    } catch (err) {
      throw ("Could Not Get Unapproved Cpara Forms Count: ${err.toString()}");
    }
  }

  Future<int> getUnsyncedCparaFormCountDistinct() async {
    final db = await instance.database;
    try {
      List<Map<String, dynamic>> countResult = await db.rawQuery(
          "SELECT COUNT(DISTINCT caregiver_cpims_id) AS count FROM Form WHERE form_date_synced IS NULL");
      if (countResult.isNotEmpty) {
        int count = countResult[0]['count'];
        return count;
      } else {
        return 0;
      }
    } catch (err) {
      throw ("Could Not Get Unsynced Forms Count: ${err.toString()}");
    }
  }

  Future<int> getUnsyncedCparaFormCountDistinctByCareGiver() async {
    final db = await instance.database;
    try {
      List<Map<String, dynamic>> countResult = await db.rawQuery(
          "SELECT COUNT(DISTINCT caregiver_cpims_id) AS count FROM Form WHERE form_date_synced IS NULL");

      if (countResult.isNotEmpty) {
        int count = countResult[0]['count'];
        return count;
      } else {
        return 0;
      }
    } catch (err) {
      throw ("Could Not Get Unsynced Forms Count: ${err.toString()}");
    }
  }

  Future<int> countOvcSubpopulationDataWithNullDateSynced() async {
    final db = await LocalDb.instance.database;
    const sql =
        "SELECT COUNT(*) as count FROM ovcsubpopulation WHERE form_date_synced IS NULL";
    List<Map<String, dynamic>> result = await db.rawQuery(sql);
    if (result.isNotEmpty) {
      return result[0]['count'];
    } else {
      return 0;
    }
  }

  Future<AppFormMetaData> getAppFormMetaData(String uuid) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> metaDataList = await db.query(
      appFormMetaDataTable,
      where: 'form_id = ?',
      whereArgs: [uuid],
    );

    if (metaDataList.isNotEmpty) {
      return AppFormMetaData.fromJson(metaDataList.first);
    } else {
      // Handle the case where no metadata is found
      return const AppFormMetaData(); // You should replace this with an appropriate default value or error handling.
    }
  }

  // Returns the name of the child who has the given ovc cpims id. If given null it returns the empty string
  Future<String> getFullChildNameFromOVCID(String? ovcCpmisId) async {
    if (ovcCpmisId == null) {
      return "";
    }

    var db = await database;
    var fetchResult = await db.rawQuery(
        "SELECT  ovc_first_name || ' ' || ovc_surname AS name  FROM OVCS WHERE ovc_cpims_id = ?",
        [ovcCpmisId]);

    if (fetchResult.isEmpty) {
      return "";
    }

    return fetchResult[0]['name'] != null
        ? fetchResult[0]['name'] as String
        : "";
  }

  //delete forms older than 30 days and whose syncing has been successful
  Future<void> deleteSyncedFormsFromDevice() async {
    //TODO handle delete of children tables when deleting data from parent table
    final db = await instance.database;
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

    await db.delete(
      form1Table,
      where: 'form_date_synced IS NOT NULL AND form_date_synced < ?',
      whereArgs: [thirtyDaysAgo.toIso8601String()],
    );

    await db.delete(
      casePlanTable,
      where: 'form_date_synced IS NOT NULL AND form_date_synced < ?',
      whereArgs: [thirtyDaysAgo.toIso8601String()],
    );

    await db.delete(
      cparaForms,
      where: 'form_date_synced IS NOT NULL AND form_date_synced < ?',
      whereArgs: [thirtyDaysAgo.toIso8601String()],
    );

    await db.delete(
      HRSForms,
      where: 'form_date_synced IS NOT NULL AND form_date_synced < ?',
      whereArgs: [thirtyDaysAgo.toIso8601String()],
    );

    await db.delete(
      HMForms,
      where: 'form_date_synced IS NOT NULL AND form_date_synced < ?',
      whereArgs: [thirtyDaysAgo.toIso8601String()],
    );
  }

  //graduation monitoring
  Future<void> createGraduationMonitoringTable(Database db, int version) async {
    const String createTableQuery = '''
    CREATE TABLE $graduation_monitoring (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      ovc_cpims_id TEXT,
      caregiver_cpims_id TEXT,
      gm1d TEXT NOT NULL,
      form_type TEXT NOT NULL,
      cm2q TEXT NOT NULL,
      cm3q TEXT NOT NULL,
      cm4q TEXT NOT NULL,
      cm5q TEXT NOT NULL,
      cm6q TEXT NOT NULL,
      cm7q TEXT NOT NULL,
      cm8q TEXT NOT NULL,
      cm9q TEXT NOT NULL,
      cm10q TEXT NOT NULL,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      cm13q TEXT NOT NULL,
      cm14q TEXT NOT NULL,
      uuid TEXT,
      form_date_synced TEXT NULL,
      message TEXT NULL,
      rejected BOOLEAN 
    )
  ''';

    try {
      await db.execute(createTableQuery);
      if (kDebugMode) {
        debugPrint(
            "------------------Function ----Creating Graduation Monitoring Forms---------------------------");
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            "-------------------Error Graduation Monitoring Forms---------------------------$e");
      }
    }
  }

  Future<List<Map<String, dynamic>>> fetchGraduationMonitoringData() async {
    try {
      final db = await LocalDb.instance.database;
      final graduationData = await db.query(graduation_monitoring,
          where:
              'form_date_synced IS NULL OR form_date_synced = "" AND rejected = 0');
      List<Map<String, dynamic>> updatedGraduationFormData = [];

      for (Map<String, dynamic> graduationRow in graduationData) {
        final AppFormMetaData appFormMetaData =
            await getAppFormMetaData(graduationRow['uuid']);
        Map<String, dynamic> updatedGraduationRow = {
          ...graduationRow,
          'app_form_metadata': appFormMetaData.toJson(),
        };
        updatedGraduationFormData.add(updatedGraduationRow);
      }
      debugPrint("GradMonitoring 1: $updatedGraduationFormData");
      return updatedGraduationFormData;
    } catch (e) {
      debugPrint("Error fetching graduation monitoring data 2: $e");
    }
    return [];
  }

  Future<bool> insertGraduationMonitoringFormData(
    String? cpmisId,
    String? caregiverCpimsId,
    GraduationMonitoringFormModel graduationMonitoringFormModel,
    String? uuid,
    String? startTimeInterview,
    String? formType,
    bool? isRejected,
    String? rejectedMessage,
  ) async {
    final db = await instance.database;

    try {
      if (uuid != null || startTimeInterview != null) {
        await insertAppFormMetaData(uuid, startTimeInterview, formType);
      }

      await db.insert(
        graduation_monitoring,
        {
          'ovc_cpims_id': cpmisId,
          'caregiver_cpims_id': caregiverCpimsId,
          'gm1d': graduationMonitoringFormModel.gm1d,
          'form_type': graduationMonitoringFormModel.form_type,
          'cm2q': graduationMonitoringFormModel.cm2q,
          'cm3q': graduationMonitoringFormModel.cm3q,
          'cm4q': graduationMonitoringFormModel.cm4q,
          'cm5q': graduationMonitoringFormModel.cm5q,
          'cm6q': graduationMonitoringFormModel.cm6q,
          'cm7q': graduationMonitoringFormModel.cm7q,
          'cm8q': graduationMonitoringFormModel.cm8q,
          'cm9q': graduationMonitoringFormModel.cm9q,
          'cm10q': graduationMonitoringFormModel.cm10q,
          'cm13q': graduationMonitoringFormModel.cm13q,
          'cm14q': graduationMonitoringFormModel.cm14q,
          'uuid': uuid,
          'form_date_synced': null,
          'message': rejectedMessage,
          'rejected': isRejected,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      debugPrint("Inserted ID: $uuid");

      if (isRejected == true) {
        debugPrint("2 :Posting rejected form");
        var dio = Dio();
        var prefs = await SharedPreferences.getInstance();
        var accessToken = prefs.getString('access');
        String bearerAuth = "Bearer $accessToken";
        var updateUpstreamEndpoint = "${cpimsProdApiUrl}mobile/record_saved";
        var response = await dio.post(
          updateUpstreamEndpoint,
          data: {
            "record_id": uuid,
            "saved": 1,
            "form_type": graduationMonitoringFormModel.form_type
          },
          options: Options(headers: {"Authorization": bearerAuth}),
        );
        print("GradMonit uuid: $uuid");

        if (response.statusCode == 200) {
          debugPrint(
              "Data sent successfully ${response.data} form type: ${graduationMonitoringFormModel.form_type}");
        } else {
          debugPrint(
              "Data not sent ${response.data} form type: ${graduationMonitoringFormModel.form_type}");
        }
      }

      return true; // Data was saved successfully
    } catch (e) {
      debugPrint('Error inserting graduation monitoring data: $e');
      return false; // Data was not saved
    }
  }

  Future<List<Map<String, dynamic>>>
      fetchUnapprovedGraduationMonitoringData() async {
    try {
      final db = await LocalDb.instance.database;
      final graduationData = await db.rawQuery(
          'SELECT * FROM "$graduation_monitoring" WHERE ("form_date_synced" IS NULL OR "form_date_synced" = "") AND "rejected" = 1');

      List<Map<String, dynamic>> updatedGraduationFormData = [];

      for (Map<String, dynamic> graduationRow in graduationData) {
        final AppFormMetaData appFormMetaData =
            await getAppFormMetaData(graduationRow['uuid']);
        Map<String, dynamic> updatedGraduationRow = {
          ...graduationRow,
          'app_form_metadata': appFormMetaData.toJson(),
        };
        updatedGraduationFormData.add(updatedGraduationRow);
      }
      debugPrint("GradMonitoring 2: $updatedGraduationFormData");
      debugPrint("CALLED THIS AFTER EDIT");
      return updatedGraduationFormData;
    } catch (e) {
      debugPrint("Error fetching graduation monitoring data 1: $e");
    }
    return [];
  }

  Future<int> countUnsyncedGraduationMonitoringFormData() async {
    try {
      final db = await LocalDb.instance.database;
      final count = Sqflite.firstIntValue(await db.rawQuery(
          'SELECT COUNT(*) FROM "$graduation_monitoring" WHERE ("form_date_synced" IS NULL OR "form_date_synced" = "") AND "rejected" = 0'));
      return count ?? 0;
    } catch (e) {
      if (kDebugMode) {
        print("Error counting HMF form data: $e");
      }
      return 0;
    }
  }

  Future<int> countUnApprovedGraduationMonitoringFormData() async {
    try {
      final db = await LocalDb.instance.database;
      final count = Sqflite.firstIntValue(await db.rawQuery(
          'SELECT COUNT(*) FROM "$graduation_monitoring" WHERE ("form_date_synced" IS NULL OR "form_date_synced" = "") AND "rejected" = 1'));
      return count ?? 0;
    } catch (e) {
      if (kDebugMode) {
        print("Error counting HMF form data: $e");
      }
      return 0;
    }
  }

  Future<int> countGraduationFormDataDistinctByCareGiver() async {
    try {
      final db = await LocalDb.instance.database;
      final count = Sqflite.firstIntValue(await db.rawQuery(
          'SELECT COUNT(DISTINCT "caregiver_cpims_id") FROM "$graduation_monitoring" WHERE ("form_date_synced" IS NULL OR "form_date_synced" = "") AND "rejected" = 0'));
      return count ?? 0;
    } catch (e) {
      if (kDebugMode) {
        print("Error counting HMF form data: $e");
      }
      return 0;
    }
  }

  Future<bool> deleteGraduationMonitoringFormData(String uuid) async {
    final db = await instance.database;
    debugPrint("The  id being deleted is $uuid");

    try {
      // Check if the data is already synced
      final List<Map<String, dynamic>> graduationData = await db.query(
        graduation_monitoring,
        where: 'uuid = ?',
        whereArgs: [uuid],
      );

      final List<Map<String, dynamic>> metaData = await db.query(
        appFormMetaDataTable,
        where: 'form_id = ?',
        whereArgs: [uuid],
      );

      if (graduationData.isEmpty || metaData.isEmpty) {
        // Data is not synced yet
        return false;
      }

      // Delete from graduation_monitoring table
      int deletedRows = await db.delete(
        graduation_monitoring,
        where: 'uuid = ?',
        whereArgs: [uuid],
      );

      // Delete from appFormMetaDataTable
      int deletedMetaRows = await db.delete(
        appFormMetaDataTable,
        where: 'form_id = ?',
        whereArgs: [uuid],
      );

      // Check if deletion was successful
      if (deletedRows == 0 || deletedMetaRows == 0) {
        // Data was not deleted successfully
        return false;
      }
      //call function for fetching unapproved forms
      await fetchUnapprovedGraduationMonitoringData();

      return true; // Data was deleted successfully
    } catch (e) {
      debugPrint('Error deleting graduation monitoring data: $e');
      return false; // Data was not deleted
    }
  }

  Future<void> clearAllTables() async {
    try {
      final db = await instance.database;

      /**
       * currently hard coded table names which is bad practice but will be refactored
       * to dynamically get all table names and clear them once we unify the table names
       * across the app
       * */
      // TODO: Refactor to dynamically get all table names
      final tables = [
        "Form",
        "ChildAnswer",
        "HMFForm",
        "HRSForm",
        "HouseholdAnswer",
        "UnapprovedCPARA",
        "UnapprovedCPARAAnswers",
        "app_form_metadata",
        "case_plan",
        "case_plan_services",
        "form1",
        "form1_critical_events",
        "form1_services",
        "form_metadata",
        "graduation_monitoring",
        "ovcs",
        "ovcsubpopulation",
        "statistics",
        "unapproved_form1",
        "unapproved_cpt",
      ];

      // Use a batch to clear all tables
      final batch = db.batch();

      for (final table in tables) {
        batch.delete(table);
      }

      // Commit the batch to clear all the data in a single transaction
      await batch.commit(noResult: true);
    } catch (e) {
      debugPrint('Error clearing tables: $e');
    }
  }
}

// table name and field names
const caseloadTable = 'ovcs';
const statisticsTable = 'statistics';
const casePlanTable = 'case_plan';
const casePlanServicesTable = 'case_plan_services';
const form1Table = 'form1';
const unapprovedForm1Table = 'unapproved_form1';
const appFormMetaDataTable = 'app_form_metadata';
const form1ServicesTable = 'form1_services';
const form1CriticalEventsTable = 'form1_critical_events';
const ovcsubpopulation = 'ovcsubpopulation';
const cparaForms = 'Form';
const HRSForms = 'HRSForm';
const HMForms = 'HMFForm';
const cparaHouseholdAnswers = 'cpara_household_answers';
const cparaChildAnswers = 'cpara_child_answers';
const graduation_monitoring = 'graduation_monitoring';
const appFormMetadata = 'app_form_metadata';

class OvcFields {
  static final List<String> values = [
    id,
    cboID,
    ovcFirstName,
    ovcSurname,
    dateOfBirth,
    caregiverNames,
    sex,
    caregiverCpimsId,
    chvCpimsId,
    ovchivstatus,
    benchMarks,
    benchMarksScore,
    benchMarksPathWay,
    hhGaps
  ];

  static const String id = '_id';
  static const String cboID = 'ovc_cpims_id';
  static const String ovcFirstName = 'ovc_first_name';
  static const String ovcSurname = 'ovc_surname';
  static const String dateOfBirth = 'date_of_birth';
  static const String age = 'age';
  static const String registationDate = 'registration_date';
  static const String caregiverNames = 'caregiver_names';
  static const String sex = 'sex';
  static const String caregiverCpimsId = 'caregiver_cpims_id';
  static const String chvCpimsId = 'chv_cpims_id';
  static const String ovchivstatus = 'ovchivstatus';
  static const String benchMarks = 'benchmarks';
  static const String benchMarksScore = 'benchmarks_score';
  static const String benchMarksPathWay = 'benchmarks_pathway';
  static const String hhGaps = 'hh_gaps';
}

class SummaryFields {
  static final List<String> values = [
    id,
    children,
    caregivers,
    government,
    ngo,
    caseRecords,
    pendingCases,
    orgUnits,
    workforceMembers,
    household,
    childrenAll,
    ovcSummary,
    ovcRegs,
    caseRegs,
    caseCats,
    criteria,
    orgUnit,
    orgUnitId,
    details
  ];

  static const String id = '_id';
  static const String children = 'children';
  static const String caregivers = 'caregivers';
  static const String government = 'government';
  static const String ngo = 'ngo';
  static const String caseRecords = 'case_records';
  static const String pendingCases = 'pending_cases';
  static const String orgUnits = 'org_units';
  static const String workforceMembers = 'workforce_members';
  static const String household = 'household';
  static const String childrenAll = 'children_all';
  static const String ovcSummary = 'ovc_summary';
  static const String ovcRegs = 'ovc_regs';
  static const String caseRegs = 'case_regs';
  static const String caseCats = 'case_cats';
  static const String criteria = 'criteria';
  static const String orgUnit = 'org_unit';
  static const String orgUnitId = 'org_unit_id';
  static const String details = 'details';
}

class FormMetadata {
  static final List<String> values = [
    columnId,
    columnFieldName,
    columnItemId,
    columnItemDescription,
    columnItemSubCategory,
    columnTheOrder,
  ];
  static const String columnId = '_id';
  static const String columnFieldName = 'field_name';
  static const String columnItemId = 'item_id';
  static const String columnItemDescription = 'item_description';
  static const String columnItemSubCategory = 'item_sub_Category';
  static const String columnTheOrder = 'the_order';
}

class CasePlan {
  static final List<String> values = [
    id,
    ovcCpimsId,
    dateOfEvent,
    formDateSynced,
    uuid,
    caregiverId,
  ];

  static const String id = 'id';
  static const String ovcCpimsId = 'ovc_cpims_id';
  static const String dateOfEvent = 'date_of_event';
  static const String formDateSynced = 'form_date_synced';
  static const String uuid = 'uuid';
  static const String caregiverId = 'caregiver_cpims_id';
}

class CasePlanServices {
  static final List<String> values = [
    id,
    formId,
    domainId,
    goalId,
    priorityId,
    gapId,
    resultsId,
    reasonId,
    completionDate,
    responsibleIds,
    serviceIds
  ];
  static const String id = 'id';
  static const String formId = 'form_id';
  static const String unapprovedFormId = 'unapproved_form_id';
  static const String domainId = 'domain_id';
  static const String goalId = 'goal_id';
  static const String priorityId = 'priority_id';
  static const String gapId = 'gap_id';
  static const String resultsId = 'results_id';
  static const String serviceIds = 'service_ids';
  static const String responsibleIds = 'responsible_ids';
  static const String reasonId = 'reason_id';
  static const String completionDate = 'completion_date';
}

class Form1 {
  static final List<String> values = [
    localId,
    id,
    formType,
    ovcCpimsId,
    dateOfEvent,
  ];

  static const String localId = "local_id";
  static const String id = "form_uuid";
  static const String formType = "form_type";
  static const String ovcCpimsId = "ovc_cpims_id";
  static const String dateOfEvent = 'date_of_event';
  static const String formDateSynced = 'form_date_synced';
  static const String message = 'message';
  static const String caregiverId = 'caregiver_cpims_id';
}

class Form1Services {
  static final List<String> values = [
    id,
    formId,
    domainId,
    serviceId,
  ];

  static const String id = "_id";
  static const String formId = "form_id";
  static const String unapprovedFormId = "unapproved_form_id";
  static const String domainId = "domain_id";
  static const String serviceId = "service_id";
  static const String message = "message";
}

class Form1CriticalEvents {
  static final List<String> values = [
    id,
    formId,
    eventId,
    eventDate,
  ];

  static const String id = "_id";
  static const String formId = "form_id";
  static const String unapprovedFormId = "unapproved_form_id";
  static const String eventId = "event_id";
  static const String eventDate = "event_date";
  static const String message = "message";
}
