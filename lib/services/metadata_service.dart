import 'dart:convert';
import 'package:cpims_mobile/Models/form_metadata_model.dart';
import 'package:cpims_mobile/providers/db_provider.dart';
import 'package:cpims_mobile/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

const String metadataTable = "metadata";

class MetadataService {

  static Future<void> saveMetadata() async {
    const urlEndpoint = "api/metadata/";
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('access');
    String? valueToken = "$token";

    try {
      var db = await LocalDb.instance.database;
      final response =
          await ApiService().getSecureData(urlEndpoint, valueToken);
      var responseData = jsonDecode(response.body);

      List<Metadata> metadataList = responseData.map<Metadata>((data) {
        return Metadata.fromJson(data);
      }).toList();

      await saveMetadataInDB(
          db, metadataList); // Pass the list of Metadata to the DB
    } catch (err) {
      print(err);
      throw "Could Not Get Metadata";
    }
  }


  static Future<void> saveMetadataInDB(
      Database db, List<Metadata> metadataList) async {
    try {
      var batch = db.batch();

      for (var meta in metadataList) {
        batch.insert(
          metadataTable, // Replace with your actual table name
          {
            "item_id": meta.itemId,
            "field_name": meta.itemName,
            "item_description": meta.itemDescription,
            "item_sub_Category": meta.itemSubCategory,
            "the_order": meta.itemTheOrder,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await batch.commit();
    } catch (err) {
      print(err);
      throw "Could Not Save Metadata in DB";
    }
  }

  static Future<void> testGetMetadata() async {
    try {
      // Call getMetadata function and pass the required MetadataTypes argument
      List<Metadata> metadataList = await getMetadata(
          MetadataTypes.ovcDomain); // Replace with actual MetadataTypes value

      if (metadataList.isNotEmpty) {
        // Print the first metadata item
        print(
            "First Metadata: ${metadataList[0].itemName}, ${metadataList[0].itemId}, ${metadataList[0].itemDescription}");
      } else {
        print("No metadata found.");
      }
    } catch (err) {
      print("Error: $err");
    }
  }

static Future<List<Metadata>> getMetadata(MetadataTypes type) async {
  try {
    var db = await LocalDb.instance.database;
    var results = await db.query(metadataTable,
        distinct: true,
        where: "field_name = ?",
        columns: ['item_description', 'item_id'],
        whereArgs: [type.value]);
    return results
        .map((e) => Metadata(
            itemDescription: e['item_description'].toString(),
            itemId: e['item_id'].toString(),
            itemName: e['field_name'].toString(),
            itemSubCategory: e['item_sub_category'].toString(),
            itemTheOrder: int.tryParse(e['the_order'].toString()) ?? 0))
        .toList();
  } catch (err) {
    throw "Could Not Get Metadata";
  }
}

}

enum MetadataTypes {
  sexId,
  yesNo,
  olmisHealthServices,
  form1bItems,
  ovcDomain,
  casePlanGoalsHealth,
  casePlanGoalsStable,
  casePlanGoalsSafe,
  casePlanGoalsSchool,
  yesNona,
  casePlanResponsible,
  olmisHeServices,
  olmisProtectionServices,
  olmisEducationServices,
  casePlanGapsHealth,
  casePlanGapsSafe,
  casePlanGapsSchool,
  casePlanGapsStable,
  casePlanPrioritiesHealth,
  casePlanPrioritiesSafe,
  casePlanPrioritiesSchool,
  casePlanPrioritiesStable,
  casePlan,
  casePlanServicesSafe,
  casePlanServicesSchool,
  casePlanServicesStable,
}

extension MetadataValues on MetadataTypes {
  String get value {
    switch (this) {
      case MetadataTypes.sexId:
        return "sex_id";
      case MetadataTypes.yesNo:
        return "yesno_id";
      case MetadataTypes.olmisHealthServices:
        return "olmis_health_service_id";
      case MetadataTypes.form1bItems:
        return "form1b_items";
      case MetadataTypes.ovcDomain:
        return "ovc_domain_id";
      case MetadataTypes.casePlanGoalsHealth:
        return "case_plan_goals_health";
      case MetadataTypes.casePlanGoalsStable:
        return "case_plan_goals_stable";
      case MetadataTypes.casePlanGoalsSafe:
        return "case_plan_goals_safe";
      case MetadataTypes.casePlanGoalsSchool:
        return "case_plan_goals_school";
      case MetadataTypes.yesNona:
        return "yesno_na";
      case MetadataTypes.casePlanResponsible:
        return "case_plan_responsible";
      case MetadataTypes.olmisHeServices:
        return "olmis_hes_service_id";
      case MetadataTypes.olmisProtectionServices:
        return "olmis_protection_service_id";
      case MetadataTypes.olmisEducationServices:
        return "olmis_education_service_id";
      case MetadataTypes.casePlanGapsHealth:
        return "case_plan_gaps_health";
      case MetadataTypes.casePlanGapsSafe:
        return "case_plan_gaps_safe";
      case MetadataTypes.casePlanGapsSchool:
        return "case_plan_gaps_school";
      case MetadataTypes.casePlanGapsStable:
        return "case_plan_gaps_stable";
      case MetadataTypes.casePlanPrioritiesHealth:
        return "case_plan_priorities_health";
      case MetadataTypes.casePlanPrioritiesSafe:
        return "case_plan_priorities_safe";
      case MetadataTypes.casePlanPrioritiesSchool:
        return "case_plan_priorities_school";
      case MetadataTypes.casePlanPrioritiesStable:
        return "case_plan_priorities_stable";
      case MetadataTypes.casePlan:
        return "case_plan_services_health";
      case MetadataTypes.casePlanServicesSafe:
        return "case_plan_services_safe";
      case MetadataTypes.casePlanServicesSchool:
        return "case_plan_services_school";
      case MetadataTypes.casePlanServicesStable:
        return "case_plan_services_stable";
      default:
        throw "Unsupported Type";
    }
  }
}

