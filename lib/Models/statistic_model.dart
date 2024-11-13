class SummaryDataModel {
  int children = 0;
  int caregivers = 0;
  int government = 0;
  int ngo = 0;
  int caseRecords = 0;
  int pendingCases = 0;
  String orgUnits = "";
  int workforceMembers = 0;
  int household = 0;
  int childrenAll = 0; //ever register
  OvcSummary ovcSummary = OvcSummary(
      m0: 0, m1: 0, m2: 0, m3: 0, m4: 0, f0: 0, f1: 0, f2: 0, f3: 0, f4: 0);
  List<dynamic> ovcRegs = [];
  List<dynamic> caseRegs = [];
  Map<String, dynamic> caseCats = {};
  Map<String, dynamic> criteria = {};
  String orgUnit = '';
  int orgUnitId = 0;
  String details = '';
  String userOrgUnits = '';
  String username = '';
  int userCpimsId = 0;
  String email = '';
  String ward = '';
  String subCounties = '';
  int caseloadOvc = 0;
  int caseloadHh = 0;
  int caseloadClhiv = 0;
  int caseloadHei = 0;

  SummaryDataModel({
    required this.children,
    required this.caregivers,
    required this.government,
    required this.ngo,
    required this.caseRecords,
    required this.pendingCases,
    required this.orgUnits,
    required this.workforceMembers,
    required this.household,
    required this.childrenAll,
    required this.ovcSummary,
    required this.ovcRegs,
    required this.caseRegs,
    required this.caseCats,
    required this.criteria,
    required this.orgUnit,
    required this.orgUnitId,
    required this.details,
    required this.userOrgUnits,
    required this.username,
    required this.userCpimsId,
    required this.email,
    required this.ward,
    required this.subCounties,
    required this.caseloadOvc,
    required this.caseloadHh,
    required this.caseloadClhiv,
    required this.caseloadHei,
  });

  factory SummaryDataModel.fromJson(Map<String, dynamic> json) {
    return SummaryDataModel(
      children: json['children'],
      caregivers: json['caregivers'],
      government: json['government'],
      ngo: json['ngo'],
      caseRecords: json['case_records'],
      pendingCases: json['pending_cases'],
      orgUnits: json['org_units'].toString(),
      workforceMembers: json['workforce_members'],
      household: json['household'],
      childrenAll: json['children_all'],
      ovcSummary: OvcSummary.fromJson(json['ovc_summary']),
      ovcRegs: json['ovc_regs'],
      caseRegs: json['case_regs'],
      caseCats: json['case_cats'],
      criteria: json['criteria'],
      orgUnit: json['org_unit'],
      orgUnitId: json['org_unit_id'],
      details: json['details'],
      userOrgUnits: json['user_org_units'] ?? "N/A",
      username: json['username'] ?? "",
      userCpimsId: json['user_cpims_id'] ?? 0,
      email: json['email'] ?? "",
      ward: json['wards'] ?? "",
      subCounties: json['sub_counties'] ?? "",
      caseloadOvc: json['caseload_ovc'] ?? 0,
      caseloadHh: json['caseload_hh'] ?? 0,
      caseloadClhiv: json['caseload_clhiv'] ?? 0,
      caseloadHei: json['caseload_hei'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'children': children,
      'caregivers': caregivers,
      'government': government,
      'ngo': ngo,
      'case_records': caseRecords,
      'pending_cases': pendingCases,
      'org_units': orgUnits,
      'workforce_members': workforceMembers,
      'household': household,
      'children_all': childrenAll,
      'ovc_summary': ovcSummary.toJson(),
      'ovc_regs': ovcRegs,
      'case_regs': caseRegs,
      'case_cats': caseCats,
      'criteria': criteria,
      'org_unit': orgUnit,
      'org_unit_id': orgUnitId,
      'details': details,
      'user_org_units': userOrgUnits,
      'username': username,
      'user_cpims_id': userCpimsId,
      'email': email,
      'wards': ward,
      'sub_counties': subCounties,
      'caseload_ovc': caseloadOvc,
      'caseload_hh': caseloadHh,
      'caseload_clhiv': caseloadClhiv,
      'caseload_hei': caseloadHei,
    };
  }

  @override
  String toString() {
    return 'SummaryDataModel{'
        'children: $children, '
        'caregivers: $caregivers, '
        'government: $government, '
        'ngo: $ngo, '
        'caseRecords: $caseRecords, '
        'pendingCases: $pendingCases, '
        'orgUnits: $orgUnits, '
        'workforceMembers: $workforceMembers, '
        'household: $household, '
        'childrenAll: $childrenAll, '
        'ovcSummary: $ovcSummary, '
        'ovcRegs: $ovcRegs, '
        'caseRegs: $caseRegs, '
        'caseCats: $caseCats, '
        'criteria: $criteria, '
        'orgUnit: $orgUnit, '
        'orgUnitId: $orgUnitId, '
        'details: $details, '
        'user_org_units: $userOrgUnits,'
        'username: $username,'
        'user_cpims_id: $userCpimsId,'
        'email: $email,'
        'wards: $ward,'
        'sub_counties: $subCounties,'
        'caseload_ovc: $caseloadOvc,'
        'caseload_hh: $caseloadHh,'
        'caseload_clhiv: $caseloadClhiv,'
        'caseload_hei: $caseloadHei}';
  }
}

class OvcSummary {
  final int m0;
  final int m1;
  final int m2;
  final int m3;
  final int m4;
  final int f0;
  final int f1;
  final int f2;
  final int f3;
  final int f4;

  OvcSummary({
    required this.m0,
    required this.m1,
    required this.m2,
    required this.m3,
    required this.m4,
    required this.f0,
    required this.f1,
    required this.f2,
    required this.f3,
    required this.f4,
  });

  factory OvcSummary.fromJson(Map<String, dynamic> json) {
    return OvcSummary(
      m0: json['m0'],
      m1: json['m1'],
      m2: json['m2'],
      m3: json['m3'],
      m4: json['m4'],
      f0: json['f0'],
      f1: json['f1'],
      f2: json['f2'],
      f3: json['f3'],
      f4: json['f4'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'm0': m0,
      'm1': m1,
      'm2': m2,
      'm3': m3,
      'm4': m4,
      'f0': f0,
      'f1': f1,
      'f2': f2,
      'f3': f3,
      'f4': f4,
    };
  }

  @override
  String toString() {
    return 'OvcSummary{'
        'm0: $m0, '
        'm1: $m1, '
        'm2: $m2, '
        'm3: $m3, '
        'm4: $m4, '
        'f0: $f0, '
        'f1: $f1, '
        'f2: $f2, '
        'f3: $f3, '
        'f4: $f4}';
  }
}
