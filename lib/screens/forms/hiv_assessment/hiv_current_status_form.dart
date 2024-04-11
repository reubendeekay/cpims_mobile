import 'package:cpims_mobile/screens/cpara/provider/hiv_assessment_provider.dart';
import 'package:cpims_mobile/screens/cpara/widgets/cpara_details_widget.dart';
import 'package:cpims_mobile/screens/cpara/widgets/cpara_stable_widget.dart';
import 'package:cpims_mobile/screens/cpara/widgets/custom_radio_buttons.dart';
import 'package:cpims_mobile/screens/forms/hiv_assessment/unapproved/hiv_risk_assessment_form_model.dart';
import 'package:cpims_mobile/widgets/custom_dynamic_radio_button.dart';
import 'package:cpims_mobile/widgets/form_section.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// class HIVCurrentStatusModel {
//   final String dateOfAssessment;
//   final String statusOfChild;
//   final String hivStatus;
//   final String hivTestDone;
//
//   HIVCurrentStatusModel({
//     this.dateOfAssessment = "",
//     this.statusOfChild = "",
//     this.hivStatus = "",
//     this.hivTestDone = "",
//   });
//
//   Map<String, dynamic> toJson() {
//     return {
//       'HIV_RA_1A': dateOfAssessment,
//       'HIV_RS_01': statusOfChild,
//       'HIV_RS_02': hivStatus,
//       'HIV_RS_03': hivTestDone,
//     };
//   }
// }

class HIVCurrentStatusForm extends StatefulWidget {
  const HIVCurrentStatusForm({
    super.key,
  });

  @override
  State<HIVCurrentStatusForm> createState() => _HIVCurrentStatusFormState();
}

class _HIVCurrentStatusFormState extends State<HIVCurrentStatusForm> {
  late final RiskAssessmentFormModel riskAssessmentFormModel;
  String dateOfAssessment = "";
  String statusOfChild = "";
  String hivStatus = "";
  String hivTestDone = "";

  void handleOnFormSaved() {
    final  formModel=Provider.of<HIVAssessmentProvider>(context, listen: false).riskAssessmentFormModel;
    formModel.dateOfAssessment = dateOfAssessment;
    formModel.statusOfChild = statusOfChild;
    formModel.hivStatus = hivStatus;
    formModel.hivTestDone = hivTestDone;
    Provider.of<HIVAssessmentProvider>(context, listen: false).notifyListeners();
  }

  @override
  void initState() {
    super.initState();
    riskAssessmentFormModel = context.read<HIVAssessmentProvider>().riskAssessmentFormModel;
    final hivAssessmentProvider = context.read<HIVAssessmentProvider>().riskAssessmentFormModel;
    // todo come here an check these values
    dateOfAssessment = hivAssessmentProvider.dateOfAssessment.isNotEmpty
        ? hivAssessmentProvider.dateOfAssessment
        : "Date of assessment";
    statusOfChild = hivAssessmentProvider.statusOfChild;
    hivStatus = hivAssessmentProvider.hivStatus;
    hivTestDone = hivAssessmentProvider.hivTestDone;
  }

  @override
  Widget build(BuildContext context) {

    return Container(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "1. CURRENT HIV STATUS",
            style: TextStyle(
                color: Colors.blue[900],
                fontSize: 18,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(
            height: 10,
          ),
          FormSection(
            children: [
              const Text("1a) Date of assessment *"),
              const SizedBox(
                height: 10,
              ),
              DateTextField(
                label: dateOfAssessment,
                enabled: true,
                onDateSelected: (date) {
                  setState(() {
                    dateOfAssessment = DateFormat("yyyy-MM-dd").format(date!);
                    handleOnFormSaved();
                  });
                },
                identifier: DateTextFieldIdentifier.dateOfAssessment,
              ),
              const SizedBox(height: 14),
            ],
          ),
          const Divider(),
          FormSection(children: [
            const Text(
                "1b) Does the caregiver know the status of the child? /Does the Adolescent and youth (>15) years know his/her status? *"),
            CustomRadioButton(
                isNaAvailable: false,
                option: convertingStringToRadioButtonOptions(
                        statusOfChild),
                optionSelected: (val) {
                  setState(() {
                    statusOfChild = convertingRadioButtonOptionsToString(val);
                    handleOnFormSaved();
                  });
                }),
          ]),
          FormSection(
            isVisibleCondition: () {
              return statusOfChild == "Yes";
            },
            children: [
              const Text("What is the HIV Status *"),
              const SizedBox(
                height: 4,
              ),
              CustomDynamicRadioButton(
                isNaAvailable: false,
                optionSelected: (val) {
                  setState(() {
                    hivStatus = val!;
                    handleOnFormSaved();
                  });
                },
                option: hivStatus.isNotEmpty
                    ? hivStatus
                    : null,
                customOptions: const [
                  "HIV_Positive",
                  "HIV_Negative",
                ],
              ),
              const SizedBox(
                height: 14,
              ),
            ],
          ),
          const Divider(),
          FormSection(
            isVisibleCondition: () {
              return statusOfChild == "Yes"  && hivStatus == "HIV_Negative";
            },
            children: [
              const Text("1c) Was the HIV test done less than 6 months ago?	*"),
              const SizedBox(height: 10),
              CustomRadioButton(
                  isNaAvailable: false,
                  option: convertingStringToRadioButtonOptions(hivTestDone),
                  optionSelected: (val) {
                    setState(() {
                      hivTestDone = convertingRadioButtonOptionsToString(val);
                      handleOnFormSaved();
                      // if (hivTestDone == "Yes") {
                      //   Provider.of<HIVAssessmentProvider>(context,
                      //           listen: false)
                      //       .clearForms();
                      // }
                    });
                  }),
            ],
          ),
        ],
      ),
    );
  }
}
