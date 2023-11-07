import 'package:cpims_mobile/screens/cpara/provider/hiv_assessment_provider.dart';
import 'package:cpims_mobile/screens/cpara/widgets/cpara_details_widget.dart';
import 'package:cpims_mobile/screens/cpara/widgets/cpara_stable_widget.dart';
import 'package:cpims_mobile/screens/cpara/widgets/custom_radio_buttons.dart';
import 'package:cpims_mobile/screens/forms/hiv_assessment/hiv_assessment.dart';
import 'package:cpims_mobile/widgets/custom_dynamic_radio_button.dart';
import 'package:cpims_mobile/widgets/custom_text_field.dart';
import 'package:cpims_mobile/widgets/form_section.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ProgressMonitoringModel {
  final String parentAcceptHivTesting;
  final String parentAcceptHivTestingDate;
  final String formalReferralMade;
  final String formalReferralMadeDate;
  final String formalReferralCompleted;
  final String formalReferralCompletedDate;
  String reasonForNotMakingReferral;
  final String hivTestResult;
  final String hivTestResultDate;
  final String referredForArt;
  final String referredForArtDate;
  final String artReferralCompleted;
  final String artReferralCompletedDate;
  final String facilityOfArtEnrollment;

  ProgressMonitoringModel({
    this.parentAcceptHivTesting = "",
    this.parentAcceptHivTestingDate = "",
    this.formalReferralMade = "",
    this.formalReferralMadeDate = "",
    this.formalReferralCompleted = "",
    this.formalReferralCompletedDate = "",
    this.reasonForNotMakingReferral = "A",
    this.hivTestResult = "",
    this.hivTestResultDate = "",
    this.referredForArt = "",
    this.referredForArtDate = "",
    this.artReferralCompleted = "",
    this.artReferralCompletedDate = "",
    this.facilityOfArtEnrollment = "",
  });

  Map<String, dynamic> toJson() {
    return {
      'parentAcceptHivTesting': parentAcceptHivTesting,
      'parentAcceptHivTestingDate': parentAcceptHivTestingDate,
      'formalReferralMade': formalReferralMade,
      'formalReferralMadeDate': formalReferralMadeDate,
      'formalReferralCompleted': formalReferralCompleted,
      'formalReferralCompletedDate': formalReferralCompletedDate,
      'reasonForNotMakingReferral': reasonForNotMakingReferral,
      'hivTestResult': hivTestResult,
      'hivTestResultDate': hivTestResultDate,
      'referredForArt': referredForArt,
      'referredForArtDate': referredForArtDate,
      'artReferralCompleted': artReferralCompleted,
      'artReferralCompletedDate': artReferralCompletedDate,
      'facilityOfArtEnrollment': facilityOfArtEnrollment,
    };
  }
}

class ProgressMonitoringForm extends StatefulWidget {
  const ProgressMonitoringForm({super.key});

  @override
  State<ProgressMonitoringForm> createState() => _ProgressMonitoringFormState();
}

class _ProgressMonitoringFormState extends State<ProgressMonitoringForm> {
  String parentAcceptHivTesting = "";
  String parentAcceptHivTestingDate = "";
  String formalReferralMade = "";
  String formalReferralMadeDate = "";
  String formalReferralCompleted = "";
  String formalReferralCompletedDate = "";
  String reasonForNotMakingReferral = "A";
  String hivTestResult = "";
  String hivTestResultDate = "";
  String referredForArt = "";
  String referredForArtDate = "";
  String artReferralCompleted = "";
  String artReferralCompletedDate = "";
  String facilityOfArtEnrollment = "";

  void handleOnFormSaved() {
    final val = ProgressMonitoringModel(
      parentAcceptHivTesting: parentAcceptHivTesting,
      parentAcceptHivTestingDate: parentAcceptHivTestingDate,
      formalReferralMade: formalReferralMade,
      formalReferralMadeDate: formalReferralMadeDate,
      formalReferralCompleted: formalReferralCompleted,
      formalReferralCompletedDate: formalReferralCompletedDate,
      reasonForNotMakingReferral:
          reasonForNotMakingReferral.isEmpty ? "A" : reasonForNotMakingReferral,
      hivTestResult: hivTestResult,
      hivTestResultDate: hivTestResultDate,
      referredForArt: referredForArt,
      referredForArtDate: referredForArtDate,
      artReferralCompleted: artReferralCompleted,
      artReferralCompletedDate: artReferralCompletedDate,
      facilityOfArtEnrollment: facilityOfArtEnrollment,
    );
    Provider.of<HIVAssessmentProvider>(context, listen: false)
        .updateProgressMonitoringModel(val);
  }

  @override
  Widget build(BuildContext context) {
    final formData =
        Provider.of<HIVAssessmentProvider>(context).progressMonitoringModel;

    return Container(
      padding: const EdgeInsets.only(top: 20),
      child: FormSection(
        isDisabled: disableSubsquentHIVAssessmentFieldsAndSubmit(context),
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "3. PROGRESS MONITORING",
                style: TextStyle(
                    color: Colors.blue[900],
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(
                height: 10,
              ),
              const Text("1.Does the parent accept HIV testing for the child?"),
              const SizedBox(
                height: 10,
              ),
              CustomRadioButton(
                isNaAvailable: false,
                option: formData != null &&
                        formData.parentAcceptHivTesting.isNotEmpty
                    ? convertingStringToRadioButtonOptions(
                        formData.parentAcceptHivTesting)
                    : null,
                optionSelected: (val) {
                  parentAcceptHivTesting =
                      convertingRadioButtonOptionsToString(val);
                  handleOnFormSaved();
                },
              ),
              if (formData != null && formData.parentAcceptHivTesting == "Yes")
                DateTextField(
                  label: "Report Date",
                  enabled: true,
                  identifier: DateTextFieldIdentifier.dateOfAssessment,
                  onDateSelected: (val) {
                    parentAcceptHivTestingDate =
                        DateFormat("dd-MM-yyyy").format(val ?? DateTime.now());
                    handleOnFormSaved();
                  },
                ),
              const SizedBox(height: 14),
              const Divider(),
              const Text("2. Was a formal referral made for HIV testing?"),
              CustomRadioButton(
                isNaAvailable: false,
                option:
                    formData != null && formData.formalReferralMade.isNotEmpty
                        ? convertingStringToRadioButtonOptions(
                            formData.formalReferralMade)
                        : null,
                optionSelected: (val) {
                  formalReferralMade =
                      convertingRadioButtonOptionsToString(val);
                  handleOnFormSaved();
                },
              ),
              if (formData != null && formData.formalReferralMade == "Yes")
                DateTextField(
                  label: "Report Date",
                  enabled: true,
                  identifier: DateTextFieldIdentifier.dateOfAssessment,
                  onDateSelected: (val) {
                    formalReferralMadeDate =
                        DateFormat("dd-MM-yyyy").format(val ?? DateTime.now());
                    handleOnFormSaved();
                  },
                ),
              const SizedBox(
                height: 4,
              ),
              const Text("3. Was the referal for HIV testing completed?"),
              const SizedBox(
                height: 4,
              ),
              CustomRadioButton(
                isNaAvailable: false,
                option: formData != null &&
                        formData.formalReferralCompleted.isNotEmpty
                    ? convertingStringToRadioButtonOptions(
                        formData.formalReferralCompleted)
                    : null,
                optionSelected: (val) {
                  formalReferralCompleted =
                      convertingRadioButtonOptionsToString(val);
                  handleOnFormSaved();
                },
              ),
              if (formData != null && formData.formalReferralCompleted == "Yes")
                DateTextField(
                  label: "Report Date",
                  enabled: true,
                  identifier: DateTextFieldIdentifier.dateOfAssessment,
                  onDateSelected: (val) {
                    formalReferralCompletedDate =
                        DateFormat("dd-MM-yyyy").format(val ?? DateTime.now());
                    handleOnFormSaved();
                  },
                ),
              const SizedBox(
                height: 14,
              ),
              const Text("3a. If no (formal referral made), report why not	"),
              const SizedBox(height: 10),
              CustomTextField(
                hintText: "Response",
                initialValue: formData?.reasonForNotMakingReferral,
                onChanged: (val) {
                  reasonForNotMakingReferral = val;
                  handleOnFormSaved();
                },
              ),
              const SizedBox(
                height: 14,
              ),
              const Text(
                  "3b. If yes(formal referral made), ellicit the HIV test result of the child from the caregiver."),
              const SizedBox(height: 10),
              CustomDynamicRadioButton(
                isNaAvailable: false,
                option: formData != null && formData.hivTestResult.isNotEmpty
                    ? formData.hivTestResult
                    : null,
                optionSelected: (val) {
                  hivTestResult = val!;
                  handleOnFormSaved();
                },
                customOptions: const [
                  "HIV_Positive",
                  "HIV_NEGATIVE",
                  "HIV_UNKOWN/UNDISCLOSED"
                ],
              ),
              const SizedBox(
                height: 14,
              ),
              FormSection(
                isDisabled:
                    hivTestResult != "HIV_Positive" && hivTestResult.isNotEmpty,
                children: [
                  const Text(
                      "4. If HIV positive(3b), was the child referred for ART?"),
                  const SizedBox(height: 10),
                  CustomRadioButton(
                    isNaAvailable: false,
                    option:
                        formData != null && formData.referredForArt.isNotEmpty
                            ? convertingStringToRadioButtonOptions(
                                formData.referredForArt)
                            : null,
                    optionSelected: (val) {
                      referredForArt =
                          convertingRadioButtonOptionsToString(val);
                      handleOnFormSaved();
                    },
                  ),
                  if (formData != null && formData.referredForArt == "Yes")
                    DateTextField(
                      label: "Report Date",
                      enabled: true,
                      identifier: DateTextFieldIdentifier.dateOfAssessment,
                      onDateSelected: (val) {
                        referredForArtDate = DateFormat("dd-MM-yyyy")
                            .format(val ?? DateTime.now());
                        handleOnFormSaved();
                      },
                    ),
                ],
              ),
              const SizedBox(
                height: 14,
              ),
              FormSection(
                isDisabled:
                    hivTestResult != "HIV_Positive" && hivTestResult.isNotEmpty,
                children: [
                  const Text(
                      "5. If HIV positive(3b), was the ART referral completed?"),
                  const SizedBox(height: 10),
                  CustomRadioButton(
                    isNaAvailable: false,
                    option: formData != null &&
                            formData.artReferralCompleted.isNotEmpty
                        ? convertingStringToRadioButtonOptions(
                            formData.artReferralCompleted)
                        : null,
                    optionSelected: (val) {
                      artReferralCompleted =
                          convertingRadioButtonOptionsToString(val);
                      handleOnFormSaved();
                    },
                  ),
                  if (formData != null &&
                      formData.artReferralCompleted == "Yes")
                    DateTextField(
                      label: "Report Date",
                      enabled: true,
                      identifier: DateTextFieldIdentifier.dateOfAssessment,
                      onDateSelected: (val) {
                        artReferralCompletedDate = DateFormat("dd-MM-yyyy")
                            .format(val ?? DateTime.now());
                        handleOnFormSaved();
                      },
                    ),
                ],
              ),
              const SizedBox(
                height: 14,
              ),
              FormSection(
                isDisabled:
                    hivTestResult != "HIV_Positive" && hivTestResult.isNotEmpty,
                children: [
                  const Text(
                      "6. (If applicable) Record facility of child's ART enrollment	"),
                  const SizedBox(height: 10),
                  CustomTextField(
                      hintText: "Search for facility here",
                      initialValue: formData?.facilityOfArtEnrollment,
                      onChanged: (val) {
                        facilityOfArtEnrollment = val;
                        handleOnFormSaved();
                      }),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
