// ignore_for_file: depend_on_referenced_packages
import 'package:cpims_mobile/Models/case_load_model.dart';
import 'package:cpims_mobile/Models/form_metadata_model.dart';
import 'package:cpims_mobile/Models/statistic_model.dart';
import 'package:cpims_mobile/screens/cpara/model/cpara_model.dart';
import 'package:cpims_mobile/screens/cpara/widgets/ovc_sub_population_form.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
// import '../Models/case_plan_form.dart';
import '../Models/caseplan_form_model.dart';
import '../screens/cpara/model/cpara_model.dart';

class LocalDb {
  static final LocalDb instance = LocalDb._init();
  static Database? _database;

  LocalDb._init();

  Future<Database> get database async {
    // If database exists, return database
    if (_database != null) return _database!;

    // If database don't exists, create one
    _database = await _initDB('children_ovc4.db');

    return _database!;
  }

//create database and child table

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createTables);
  }

  Future<void> _createTables(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER';

    await db.execute('''
      CREATE TABLE $caseloadTable (
        ${OvcFields.id} $idType,
        ${OvcFields.cboID} $textType,
        ${OvcFields.ovcFirstName} $textType,
        ${OvcFields.ovcSurname} $textType,
        ${OvcFields.registationDate} $textType,
        ${OvcFields.dateOfBirth} $textType,
        ${OvcFields.caregiverNames} $textType,
        ${OvcFields.sex} $textType,
        ${OvcFields.caregiverCpimsId} $textType,
        ${OvcFields.chvCpimsId} $textType
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
        ${CasePlan.dateOfEvent} $textType
      )
      ''');

    await db.execute('''
        CREATE TABLE $casePlanServicesTable (
          ${CasePlanServices.id} $idType,
          ${CasePlanServices.formId} $intType,
          ${CasePlanServices.domainId} $textType,
          ${CasePlanServices.goalId} $textType,
          ${CasePlanServices.priorityId} $textType,
          ${CasePlanServices.gapId} $textType,
          ${CasePlanServices.serviceIds} $textType,
          ${CasePlanServices.resultsId} $textType,
          ${CasePlanServices.reasonId} $textType,
          ${CasePlanServices.completionDate} $textType,
          ${CasePlanServices.responsibleIds} $textType,
          FOREIGN KEY (${CasePlanServices
        .formId}) REFERENCES $casePlanTable(${CasePlan.id})
        )
        ''');

    await db.execute('''
        CREATE TABLE $tableFormMetadata (
          ${FormMetadata.columnId} $idType,
          ${FormMetadata.columnItemId} $textType,
          ${FormMetadata.columnFieldName} $textType,
          ${FormMetadata.columnItemDescription} $textType,
          ${FormMetadata.columnItemSubCategory} $textType,
          ${FormMetadata.columnTheOrder} $textType
        )
        ''');

    await db.execute('''
        CREATE TABLE $form1Table (
          ${Form1.id} $idType,
          ${Form1.ovcCpimsId} $textType,
          ${Form1.dateOfEvent} $textType,
          ${Form1.formType} $textType
        )
        ''');

    await db.execute('''
  CREATE TABLE $form1ServicesTable (
    ${Form1Services.id} $idType,
    ${Form1Services.formId} $intType,
    ${Form1Services.domainId} $textType,
    ${Form1Services.serviceId} $textType,
    FOREIGN KEY (${Form1Services.formId}) REFERENCES $form1Table(${Form1.id})
  )
''');

    await db.execute('''
      CREATE TABLE $form1CriticalEventsTable (
        ${Form1CriticalEvents.id} $idType,
        ${Form1CriticalEvents.formId} $textType,
        ${Form1CriticalEvents.eventId} $textType,
        ${Form1CriticalEvents.event_date} $textType,
        FOREIGN KEY (${Form1CriticalEvents
        .formId}) REFERENCES $form1Table(${Form1.id})
        )
      ''');

    await creatingCparaTables(db, version);
    await createOvcSubPopulation(db, version);
  }

  Future<void> insertCaseLoad(CaseLoadModel caseLoadModel) async {
    final db = await instance.database;

    await db.insert(caseloadTable, caseLoadModel.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace
    );
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
    try {
      debugPrint("Creating Cpara tables");
      await db.execute(
          "CREATE TABLE IF NOT EXISTS Form(id INTEGER PRIMARY KEY, date TEXT);");

      // await db.execute(
      //     "CREATE TABLE IF NOT EXISTS Child(childOVCCPMISID TEXT PRIMARY KEY, childName TEXT, childAge TEXT, childGender TEXT, childSchool TEXT, childOVCRegistered TEXT);");

      // await db.execute(
      //     "CREATE TABLE IF NOT EXISTS Household(householdID TEXT PRIMARY KEY);");

      // await db.execute(
      //     "CREATE TABLE IF NOT EXISTS HouseholdChild(childID TEXT, householdID TEXT, FOREIGN KEY (householdID) REFERENCES Household(householdID), PRIMARY KEY(childID, householdID));");

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
      required String careProviderId}) async {

    final db = await instance.database;

    // Create form
    cparaModelDB.createForm(db).then((value) {
      // Get formID
      cparaModelDB.getLatestFormID(db).then((formData) {
        var formDate = formData.formDate;
        var formDateString = formDate.toString().split(' ')[0];
        var formID = formData.formID;
        cparaModelDB.addHouseholdFilledQuestionsToDB(
            db, formDateString, ovcId, formID);
      });
    });
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
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    } catch (err) {
      debugPrint(err.toString());
    }
  }

  Future<void> insertOvcSubpopulationData(String uuid,String cpimsId,String date_of_assessment,List<CheckboxQuestion> questions) async{
    final db = await instance.database;
    for(var question in questions){
      int value= question.isChecked! ? 1 : 0;
      await db.insert(ovcsubpopulation, {
        'uuid':uuid,
        'cpims_id':cpimsId,
        'criteria':question.questionID,
        'date_of_event':date_of_assessment,
      },conflictAlgorithm: ConflictAlgorithm.replace
      );
    }

  }

  Future<List<Map<String, dynamic>>> fetchOvcSubPopulationData() async {
    final db = await LocalDb.instance.database;
    final result = await db.query(ovcsubpopulation);
    return result;
  }

  // insert Metadata
  Future<bool> insertMetadata(Metadata metadata) async {
    final db = await instance.database;
    await db.insert(tableFormMetadata, metadata.toJson());
    return true;
  }

  // Query All form Metadata
  Future<List<Map<String, dynamic>>> queryAllMetadataRows() async {
    final db = await instance.database;
    List<Map<String, dynamic>> results = await db.query(tableFormMetadata);
    return results;
  }

  //Query specific field Items
  Future<List<Map<String, dynamic>>> querySpecificMetadataFieldItems(
      String fieldName) async {
    final db = await instance.database;
    const sql = 'SELECT * FROM $tableFormMetadata WHERE field_name = ?';
    final List<Map<String, dynamic>> results =
    await db.rawQuery(sql, [fieldName]);
    return results;
  }

  // insert formData(either form1a or form1b)
  Future<void> insertForm1Data(String formType, formData) async {
    try {
      final db = await instance.database;
      final formId = await db.insert(
        form1Table,
        {
          'ovc_cpims_id': formData.ovcCpimsId,
          'date_of_event': formData.date_of_event,
          'form_type': formType,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
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
            'event_id': criticalEvent.event_id,
            'event_date': criticalEvent.event_date
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    } catch (e) {
      print(">>>>>>>>>>>>>$e");
    }
  }

  Future<List<Map<String, dynamic>>> queryAllForm1Rows(String formType) async {
    try {
      final db = await instance.database;
      const sql = 'SELECT * FROM $form1Table WHERE form_type = ?';
      final List<Map<String, dynamic>> form1Rows = await db.rawQuery(
          sql, [formType]);

      List<Map<String, dynamic>> updatedForm1Rows = [];

      for (var form1row in form1Rows) {
        int formId = form1row['_id'];

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

        // Create a new map that includes existing form1row data, services, and critical_events
        Map<String, dynamic> updatedForm1Row = {
          ...form1row,
          'services': services,
          'critical_events': criticalEvents,
        };

        // Add the updated map to the list
        updatedForm1Rows.add(updatedForm1Row);
      }

      return updatedForm1Rows;
    } catch (e) {
      print("Error querying form1 data: $e");
      return [];
    }
  }

  // get a single row(form 1a or 1b)
  Future<bool> deleteForm1Data(String formType, int id) async {
    try {
      final db = await instance.database;
      final queryResults = await db.query(
        form1Table,
        where: '${Form1.id} = ?',
        whereArgs: [id],
      );

      if (queryResults.isNotEmpty) {
        final form1Id = queryResults.first[Form1.id] as int;
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
          where: '${Form1.id} = ?',
          whereArgs: [form1Id],
        );
        return rowsAffected > 0;
      }
      return false;
    } catch (e) {
      print(e);
    }
    return false;
  }


// inserting case plan
  Future<bool> insertCasePlan(CasePlanModel casePlan) async {
    try {
      // Insert the main case plan information
      final db = await instance.database;
      final casePlanId = await db.insert(
        casePlanTable,
        {
          'ovc_cpims_id': casePlan.ovcCpimsId,
          'date_of_event': casePlan.dateOfEvent,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Insert the associated services
      for (var service in casePlan.services) {
        final serviceIdList =
        service.serviceIds.join(','); // Join service IDs with commas
        final responsibleIdList = service.responsibleIds
            .join(','); // Join responsible IDs with commas

        await db.insert(
          casePlanServicesTable,
          {
            'form_id': casePlanId,
            'domain_id': service.domainId,
            'goal_id': service.goalId,
            'gap_id': service.gapId,
            'priority_id': service.priorityId,
            'results_id': service.resultsId,
            'reason_id': service.reasonId,
            'completion_date': service.completionDate,
            'service_ids': serviceIdList,
            'responsible_ids': responsibleIdList,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      return true;
    } catch (e) {
      print('Error inserting case plan: $e');
      return false;
    }
  }

  Future<CasePlanModel?> getCasePlan(String ovcCpimsId) async {
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
          ovcCpimsId: mainQueryResult.first[CasePlan.ovcCpimsId] as String,
          dateOfEvent: mainQueryResult.first[CasePlan.dateOfEvent] as String,
          services: services,
        );
      }

      return null; // Return null if case plan not found
    } catch (e) {
      print('Error retrieving case plan: $e');
      return null;
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
      print('Error deleting case plan: $e');
      return false;
    }
  }

}

// table name and field names
const caseloadTable = 'ovcs';
const statisticsTable = 'statistics';
const tableFormMetadata = 'form_metadata';
const casePlanTable = 'case_plan';
const casePlanServicesTable = 'case_plan_services';
const form1Table = 'form1';
const form1ServicesTable = 'form1_services';
const form1CriticalEventsTable = 'form1_critical_events';
const ovcsubpopulation='ovcsubpopulation';

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
  ];

  static const String id = '_id';
  static const String cboID = 'ovc_cpims_id';
  static const String ovcFirstName = 'ovc_first_name';
  static const String ovcSurname = 'ovc_surname';
  static const String dateOfBirth = 'date_of_birth';
  static const String registationDate = 'registration_date';
  static const String caregiverNames = 'caregiver_names';
  static const String sex = 'sex';
  static const String caregiverCpimsId = 'caregiver_cpims_id';
  static const String chvCpimsId = 'chv_cpims_id';
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
  static final List<String> values = [id, ovcCpimsId, dateOfEvent];

  static const String id = '_id';
  static const String ovcCpimsId = 'ovc_cpims_id';
  static const String dateOfEvent = 'date_of_event';
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
  static const String id = '_id';
  static const String formId = 'form_id';
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
    id,
    formType,
    ovcCpimsId,
    dateOfEvent,
  ];

  static const String id = "_id";
  static const String formType = "form_type";
  static const String ovcCpimsId = "ovc_cpims_id";
  static const String dateOfEvent = 'date_of_event';
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
  static const String domainId = "domain_id";
  static const String serviceId = "service_id";
}

class Form1CriticalEvents {
  static final List<String> values = [
    id,
    formId,
    eventId,
    event_date,
  ];

  static const String id = "_id";
  static const String formId = "form_id";
  static const String eventId = "event_id";
  static const String event_date = "event_date";
}
