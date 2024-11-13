import 'package:cpims_mobile/Models/case_load_model.dart';
import 'package:cpims_mobile/Models/statistic_model.dart';
import 'package:cpims_mobile/constants_prod.dart';
import 'package:cpims_mobile/providers/ui_provider.dart';
import 'package:cpims_mobile/screens/cpara/model/detail_model.dart';
import 'package:cpims_mobile/screens/cpara/provider/cpara_provider.dart';
import 'package:cpims_mobile/screens/cpara/widgets/cpara_stable_widget.dart';
import 'package:cpims_mobile/screens/cpara/widgets/custom_radio_buttons.dart';
import 'package:cpims_mobile/screens/cpara/widgets/ovc_sub_population_form.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../registry/organisation_units/widgets/steps_wrapper.dart';

class CparaDetailsWidget extends StatefulWidget {
  const CparaDetailsWidget({super.key});

  @override
  State<StatefulWidget> createState() => _CparaDetailsWidgetState();
}

class _CparaDetailsWidgetState extends State<CparaDetailsWidget> {
  RadioButtonOptions? selected;
  RadioButtonOptions? isFirstAssessment;
  RadioButtonOptions? isChildHeaded;
  RadioButtonOptions? hasHivExposedInfant;
  RadioButtonOptions? hasPregnantOrBreastfeedingWoman;

  List<CaseLoadModel> children = [];

  @override
  void initState() {
    DetailModel detailModel =
        context.read<CparaProvider>().detailModel ?? DetailModel();
    isFirstAssessment = detailModel.isFirstAssessment == null
        ? isFirstAssessment
        : convertingStringToRadioButtonOptions(detailModel.isFirstAssessment!);
    isChildHeaded = detailModel.isChildHeaded == null
        ? isChildHeaded
        : convertingStringToRadioButtonOptions(detailModel.isChildHeaded!);
    hasHivExposedInfant = detailModel.hasHivExposedInfant == null
        ? hasHivExposedInfant
        : convertingStringToRadioButtonOptions(
            detailModel.hasHivExposedInfant!);
    List<CaseLoadModel> models = context.read<CparaProvider>().children;
    children = models;

    super.initState();
  }

  void updateDate(String whatDate, String? newDate) {
    switch (whatDate) {
      case 'assesment':
        DetailModel detailModel =
            context.read<CparaProvider>().detailModel ?? DetailModel();
        var newDetailModel =
            detailModel.copyWith(dateOfAssessment: newDate ?? "");
        context.read<CparaProvider>().updateDetailModel(newDetailModel);
      case 'previous':
        DetailModel detailModel =
            context.read<CparaProvider>().detailModel ?? DetailModel();
        var newDetailModel =
            detailModel.copyWith(dateOfLastAssessment: newDate ?? "");
        context.read<CparaProvider>().updateDetailModel(newDetailModel);
      default:
        break;
    }
  }

  void getDataAndMoveToNext() {
    if (kDebugMode) {
      print('Is first assessment: $widget');
    }
    if (kDebugMode) {
      print('Is child headed: $isChildHeaded');
    }
    if (kDebugMode) {
      print('Has HIV exposed infant: $hasHivExposedInfant');
    }
    if (kDebugMode) {
      print(
          'Has pregnant or breastfeeding woman: $hasPregnantOrBreastfeedingWoman');
    }

    DateTime? dateOfAssessment =
        _dateTextFieldKey.currentState?.getSelectedDate();
    String formattedDateOfAssessment = dateOfAssessment != null
        ? DateFormat('yyyy-MM-dd').format(dateOfAssessment)
        : '';
    if (kDebugMode) {
      print('Date of assessment: $formattedDateOfAssessment');
    }

    DateTime? dateOfPreviousAssessment =
        _dateTextFieldPreviousKey.currentState?.getSelectedDate();
    String formattedDateOfPreviousAssessment = dateOfPreviousAssessment != null
        ? DateFormat('yyyy-MM-dd').format(dateOfPreviousAssessment)
        : '';
    if (kDebugMode) {
      print('Date of previous assessment: $formattedDateOfPreviousAssessment');
    }
  }

  final GlobalKey<_DateTextFieldState> _dateTextFieldKey = GlobalKey();
  final GlobalKey<_DateTextFieldState> _dateTextFieldPreviousKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    // Providing access to the provider
    return Consumer<CparaProvider>(
      builder: (context, model, _) {
        return StepsWrapper(
          title: 'CPARA Details',
          children: [
            DateTextField(
              key: _dateTextFieldKey,
              label: 'Date of Assessment',
              enabled: true,
              identifier: DateTextFieldIdentifier.dateOfAssessment,
              onDateSelected: (date) {
                if (date != null) {
                  String formattedDate = DateFormat('yyyy-MM-dd').format(date);
                  print('Date selected: $formattedDate');
                  DetailModel detailModel =
                      context.read<CparaProvider>().detailModel ?? DetailModel();
                  context.read<CparaProvider>().updateDetailModel(
                      detailModel.copyWith(dateOfAssessment: formattedDate));
                }
              },
            ),
            // DateTextField2(
            //     label: 'Date of Assessment',
            //     enabled: true,
            //     initialValue: model.detailModel?.dateOfAssessment ?? "",
            //     updateDate: (String? newDate) {
            //       updateDate('assesment', newDate);
            //     }),
            const Divider(
              height: 20,
              thickness: 2,
            ),
            const SizedBox(height: 20),
            const TextViewsColumn(),
            QuestionWidget(
              question: 'Is this the first Case Plan Readiness Assessment?',
              selectedOption: (value) {
                setState(() {
                  isFirstAssessment = value;
                  if (isFirstAssessment == RadioButtonOptions.yes) {
                    _dateTextFieldPreviousKey.currentState?.clearDate();
                  }
                  DetailModel detailModel =
                      context.read<CparaProvider>().detailModel ??
                          DetailModel();
                  String selectedOption =
                      convertingRadioButtonOptionsToString(value);
                  context.read<CparaProvider>().updateDetailModel(
                      detailModel.copyWith(isFirstAssessment: selectedOption));
                });
              },
              isNaAvailable: false,
              option: convertingStringToRadioButtonOptions(
                  model.detailModel?.isFirstAssessment ?? ""),
            ),

            const SizedBox(height: 20),
            DateTextField(
              key: _dateTextFieldPreviousKey,
              label:
                  'If No, give date of Previous Case Plan Readiness Assessment',
              enabled: isFirstAssessment == RadioButtonOptions.no,
              identifier: DateTextFieldIdentifier.previousAssessment,
              onDateSelected: (date) {
                if(date != null) {
                  String formattedDate = DateFormat('yyyy-MM-dd').format(date);
                  print('Previous Date selected: $formattedDate');
                  DetailModel detailModel = context.read<CparaProvider>().detailModel ?? DetailModel();
                  context.read<CparaProvider>().updateDetailModel(detailModel.copyWith(dateOfLastAssessment: formattedDate));
                }
              },
            ),
            const SizedBox(height: 20),
            const ReusableTitleText(
                title:
                    'Details of all children below 18 years currently living in the household.'),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: children.length,
              itemBuilder: (context, index) {
                return ExpansionTile(
                    title: Text(
                        '${children[index].ovcFirstName!} ${children[index].ovcSurname!}'),
                    children: [
                      ChildCard(childDetails: children[index]),
                    ]);
              },
            ),
            QuestionWidget(
              question:
                  "Is this household child-headed (i.e. Household head age is less than 18 years)?",
              selectedOption: (value) {
                setState(() {
                  DetailModel detailModel =
                      context.read<CparaProvider>().detailModel ??
                          DetailModel();
                  String selectedOption =
                      convertingRadioButtonOptionsToString(value);
                  context.read<CparaProvider>().updateDetailModel(
                      detailModel.copyWith(isChildHeaded: selectedOption));
                });
              },
              isNaAvailable: false,
              option: convertingStringToRadioButtonOptions(
                  model.detailModel?.isChildHeaded ?? ""),
            ),
            QuestionWidget(
              question: 'Does this HH have HIV exposed infant?',
              selectedOption: (value) {
                setState(() {
                  hasHivExposedInfant = value;
                  DetailModel detailModel =
                      context.read<CparaProvider>().detailModel ??
                          DetailModel();
                  String selectedOption =
                      convertingRadioButtonOptionsToString(value);
                  context.read<CparaProvider>().updateDetailModel(detailModel
                      .copyWith(hasHivExposedInfant: selectedOption));
                });
              },
              isNaAvailable: false,
              option: convertingStringToRadioButtonOptions(
                  model.detailModel?.hasHivExposedInfant ?? ""),
            ),
            QuestionWidget(
              question:
                  'Does this HH currently have a pregnant and/or breastfeeding woman/ adolescent?',
              selectedOption: (value) {
                setState(() {
                  hasPregnantOrBreastfeedingWoman = value;
                  DetailModel detailModel =
                      context.read<CparaProvider>().detailModel ??
                          DetailModel();
                  String selectedOption =
                      convertingRadioButtonOptionsToString(value);
                  context.read<CparaProvider>().updateDetailModel(
                      detailModel.copyWith(
                          hasPregnantOrBreastfeedingWoman: selectedOption));
                });
              },
              isNaAvailable: false,
              option: convertingStringToRadioButtonOptions(
                  model.detailModel?.hasPregnantOrBreastfeedingWoman ?? ""),
            ),
            const SizedBox(height: 20),
            const QuestionForCard(
              text: "OVC Sub Population",
            ),
            const SizedBox(
              height: 10.0,
            ),
            // for(var child in children)
            //   OvcForm(caseLoadModel: child),
            const OvcOverallForm(),
            // const SizedBox(height: 15),
            // CustomButton(
            //   text: "Submit",
            //   onTap: () {
            //     List<Map<CaseLoadModel, List<CheckboxQuestion>>> ovcSubPopulations = context.read<CparaProvider>().ovcSubPopulations ?? [];
            //     debugPrint("${ovcSubPopulations.length}");
            //   },
            // ),
          ],
        );
      },
    );
  }
}

typedef UpdateDate = Function(String? newDate);

class DateTextField2 extends StatelessWidget {
  final String label;
  final bool enabled;
  final String initialValue;
  final UpdateDate updateDate;

  DateTextField2(
      {required this.label,
      required this.enabled,
      required this.initialValue,
      required this.updateDate,
      super.key});

  final TextEditingController controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    var dateFormat = DateFormat('MMMM d, yyyy');
    DateTime parsedDate;
    String dateString;
    try {
      parsedDate = DateTime.parse(initialValue);
      dateString = dateFormat.format(parsedDate);
    } catch (err) {
      debugPrint("$initialValue is an invalid date");
      dateString = "";
    }
    controller.text = dateString;
    return TextField(
      onTap: () {
        if (enabled) {
          showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime.now(),
          ).then((pickedDate) {
            if (pickedDate != null) {
              updateDate(DateFormat('yyyy-MM-dd')
                  .format(pickedDate ?? DateTime.now()));
            }
          });
        }
      },
      readOnly: true,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      controller: controller,
    );
  }
}

class DateTextField2New extends StatefulWidget {
  final String label;
  final bool enabled;
  final UpdateDate updateDate;
  final bool allowPastDates;

  const DateTextField2New({
    required this.label,
    required this.enabled,
    required this.updateDate,
    this.allowPastDates = false,
    super.key,
  });

  @override
  State<DateTextField2New> createState() => _DateTextField2NewState();
}

class _DateTextField2NewState extends State<DateTextField2New> {
  final TextEditingController _controller = TextEditingController(text: '');
  late DateTime? _selectedDate;

  @override
  Widget build(BuildContext context) {
    var dateFormat = DateFormat('MMMM d, yyyy');

    return TextField(
      onTap: () {
        if (widget.enabled) {
          showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: widget.allowPastDates ? DateTime(1900) : DateTime.now(),
            lastDate: DateTime.now(),
          ).then((pickedDate) {
            if (pickedDate != null) {
              setState(() {
                _selectedDate = pickedDate;
                _controller.text = dateFormat.format(pickedDate);
              });
              widget.updateDate(DateFormat('yyyy-MM-dd').format(pickedDate));
            }
          });
        }
      },
      readOnly: true,
      enabled: widget.enabled,
      decoration: InputDecoration(
        labelText: widget.label,
        border: const OutlineInputBorder(),
      ),
      controller: _controller,
    );
  }
}

class DateTextField extends StatefulWidget {
  const DateTextField({
    Key? key,
    // required this.initialValue,
    this.allowFutureDates = false,
    required this.label,
    required this.enabled,
    required this.onDateSelected,
    required this.identifier,
  }) : super(key: key);

  final String label;
  final bool enabled;

  // final String initialValue;
  final DateTextFieldIdentifier identifier;
  final Function(DateTime?)? onDateSelected;
  final bool allowFutureDates;

  @override
  State<DateTextField> createState() => _DateTextFieldState();
}

class _DateTextFieldState extends State<DateTextField> {
  DateTime? selectedDate;

  void clearDate() {
    setState(() {
      selectedDate = null;
    });
  }

  DateTime? getSelectedDate() {
    return selectedDate;
  }

  @override
  Widget build(BuildContext context) {
    String textFieldText = selectedDate != null
        ? DateFormat('MMMM d, yyyy').format(selectedDate!)
        : '';

    return TextField(
      onTap: () {
        if (widget.enabled) {
          showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: widget.allowFutureDates ? DateTime(2101) : DateTime.now(),
          ).then((pickedDate) {
            if (pickedDate != null && mounted) {
              setState(() {
                selectedDate = pickedDate;
                String formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
                widget.onDateSelected!(pickedDate);
              });
            }
          });
        }
      },
      readOnly: true,
      enabled: widget.enabled,
      decoration: InputDecoration(
        labelText: widget.label,
        border: const OutlineInputBorder(),
      ),
      controller: TextEditingController(text: textFieldText),
    );
  }
}

class NewDateTextField extends StatefulWidget {
  const NewDateTextField({
    Key? key,
    required this.label,
    required this.enabled,
    required this.onDateSelected,
    this.allowFutureDates = false,
  }) : super(key: key);

  final String label;
  final bool enabled;
  final Function(DateTime?)? onDateSelected;
  final bool allowFutureDates;

  @override
  State<NewDateTextField> createState() => NewDateTextFieldState();
}

class NewDateTextFieldState extends State<NewDateTextField> {
  DateTime? selectedDate;

  void clearDate() {
    setState(() {
      selectedDate = null;
    });
  }

  DateTime? getSelectedDate() {
    return selectedDate;
  }

  @override
  Widget build(BuildContext context) {
    String textFieldText = selectedDate != null
        ? DateFormat('MMMM d, yyyy').format(selectedDate!)
        : '';
    return TextField(
      onTap: () {
        if (widget.enabled) {
          showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate:
                      widget.allowFutureDates ? DateTime(2101) : DateTime.now())
              .then((pickedDate) {
            if (pickedDate != null && mounted) {
              setState(() {
                selectedDate = pickedDate;
                widget.onDateSelected!(selectedDate);
              });
            }
          });
        }
      },
      readOnly: true,
      enabled: widget.enabled,
      decoration: InputDecoration(
        labelText: widget.label,
        border: const OutlineInputBorder(),
      ),
      controller: TextEditingController(text: textFieldText),
    );
  }
}

// class class TextViewsColumn
class TextViewsColumn extends StatefulWidget {
  const TextViewsColumn({super.key});

  @override
  State<TextViewsColumn> createState() => _TextViewsColumnState();
}

class _TextViewsColumnState extends State<TextViewsColumn> {
  CaseLoadModel caseLoadModel = CaseLoadModel();

  // SummaryDataModel dashData = SummaryDataModel();
  @override
  void initState() {
    super.initState();

    caseLoadModel =
        context.read<CparaProvider>().caseLoadModel ?? CaseLoadModel();
  }

  @override
  Widget build(BuildContext context) {
    final SummaryDataModel dashData =
        context.select((UIProvider provider) => provider.getDashData);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ReusableTitleText(title: 'Name of Organisation(LIP)'),
        const SizedBox(height: 10),
        Text(dashData.orgUnit),
        const SizedBox(height: 10),
        const ReusableTitleText(title: 'Date enrolled in the project'),
        const SizedBox(height: 10),
        Text("${caseLoadModel.registrationDate}"),
        const SizedBox(height: 10),
        const ReusableTitleText(title: 'Name of SDP staff/Case Manager'),
        const SizedBox(height: 10),
        Text(dashData.orgUnit),
        const SizedBox(height: 10),
        const ReusableTitleText(title: 'Name of Caregiver'),
        const SizedBox(height: 10),
        Text("${caseLoadModel.caregiverNames}"),
        const SizedBox(height: 10),
        const ReusableTitleText(title: 'Caregiver ID Number'),
        const SizedBox(height: 10),
        Text("${caseLoadModel.caregiverCpimsId}"),
        const SizedBox(height: 10),
        const SizedBox(height: 10),
        const Divider(height: 20, thickness: 2),
        const SizedBox(height: 20),
      ],
    );
  }
}

class ChildCard extends StatelessWidget {
  const ChildCard({Key? key, required this.childDetails}) : super(key: key);

  // CaseLoadModel caseLoadModel = CaseLoadModel();
  final CaseLoadModel childDetails;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(10),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ReusableTitleText(title: 'Name'),
                SizedBox(
                  width: 10.0,
                ),
                ReusableTitleText(title: 'Age')
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    '${childDetails.ovcFirstName!} ${childDetails.ovcSurname!}'),
                Text("${childDetails.age!.toString()} years"),
              ],
            ),
            const SizedBox(height: 8),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ReusableTitleText(title: 'Gender'),
                ReusableTitleText(title: 'CPIMS ID'),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(childDetails.sex!),
                Text(childDetails.cpimsId!),
              ],
            ),
            const SizedBox(height: 8),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ReusableTitleText(
                  title: 'School Level',
                ),
              ],
            ),
            //todo: change to be dynamic
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(""),
              ],
            ),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FittedBox(
                    child: ReusableTitleText(
                        title: 'Registered in this OVC Program')),
              ],
            ),
            //todo: change to be dynamic
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Yes"),
              ],
            ),
            const SizedBox(
              height: 2,
            ),
            const Divider(
              color: Colors.grey,
            ),
            const SizedBox(
              height: 2,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("${childDetails.ovchivstatus}"),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ReusableTitleText extends StatelessWidget {
  const ReusableTitleText({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.bold),
    );
  }
}

class ChildDetails {
  final String name;
  final int age;
  final String gender;
  final String uniqueNumber;
  final String schoolLevel;
  final bool registeredInProgram;

  ChildDetails({
    required this.name,
    required this.age,
    required this.gender,
    required this.uniqueNumber,
    required this.schoolLevel,
    required this.registeredInProgram,
  });
}

class CparaOvcDetails {
  final String ovcCpimsId;
  final String ovcNames;
  final String dateOfBirth;
  final String ovcEnrollmentDate;
  final String exitStatus;
  final String exitDate;
  final int cboId;
  final String cboName;
  final int chvCpimsId;
  final String chvNames;
  final int caregiverCpimsId;
  final String caregiverNames;
  final String wardCode;
  final String wardName;

  CparaOvcDetails({
    required this.ovcCpimsId,
    required this.ovcNames,
    required this.dateOfBirth,
    required this.ovcEnrollmentDate,
    required this.exitStatus,
    required this.exitDate,
    required this.cboId,
    required this.cboName,
    required this.chvCpimsId,
    required this.chvNames,
    required this.caregiverCpimsId,
    required this.caregiverNames,
    required this.wardCode,
    required this.wardName,
  });

  factory CparaOvcDetails.fromJson(Map<String, dynamic> json) {
    return CparaOvcDetails(
      ovcCpimsId: json['ovc_cpims_id'],
      ovcNames: json['ovc_names'],
      dateOfBirth: json['date_of_birth'],
      ovcEnrollmentDate: json['ovc_enrollment_date'],
      exitStatus: json['exit_status'],
      exitDate: json['exit_date'],
      cboId: json['cbo_id'],
      cboName: json['cbo_name'],
      chvCpimsId: json['chv_cpims_id'],
      chvNames: json['chv_names'],
      caregiverCpimsId: json['caregiver_cpims_id'],
      caregiverNames: json['caregiver_names'],
      wardCode: json['ward']['code'],
      wardName: json['ward']['name'],
    );
  }
}

class ApiService {
  static Future<CparaOvcDetails> fetchOvcDetails(
      String token, String ovcCpimsId) async {
    final response = await http.get(
      Uri.parse('$cpimsProdApiUrl/form/CPR/?ovc_cpims_id=$ovcCpimsId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = json.decode(response.body);
      return CparaOvcDetails.fromJson(jsonData);
    } else {
      throw Exception('Failed to load OVC details');
    }
  }
}

enum DateTextFieldIdentifier {
  dateOfAssessment,
  previousAssessment,
  dateHIVConfirmedPositive,
  dateTreatmentInitiated,
  dateStartedFirstLine,
  arvsSubWithFirstLineDate,
  switchToSecondLineDate,
  switchToThirdLineDate,
  labInvestigationsDate,
  nextAppointmentDate,
  visitDate
}
