import 'package:cpims_mobile/Models/case_load_model.dart';
import 'package:cpims_mobile/constants.dart';
import 'package:cpims_mobile/screens/forms/form1b/utils/form1bConstants.dart';
import 'package:cpims_mobile/screens/forms/form1b/widgets/critical_event_form1b.dart';
import 'package:cpims_mobile/screens/forms/form1b/widgets/healthy_form1b.dart';
import 'package:cpims_mobile/screens/forms/form1b/widgets/safe_form1b.dart';
import 'package:cpims_mobile/screens/forms/form1b/widgets/stable_form1b.dart';
import 'package:cpims_mobile/widgets/app_bar.dart';
import 'package:cpims_mobile/widgets/custom_button.dart';
import 'package:cpims_mobile/widgets/custom_stepper.dart';
import 'package:cpims_mobile/widgets/drawer.dart';
import 'package:cpims_mobile/widgets/footer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../Models/unapproved_form_1_model.dart';
import '../../../providers/app_meta_data_provider.dart';
import '../../../providers/form1b_provider.dart';
import '../../../widgets/location_dialog.dart';
import '../../cpara/widgets/cpara_details_widget.dart';
import '../../homepage/provider/stats_provider.dart';

class Form1BScreen extends StatefulWidget {
  const Form1BScreen({super.key, required this.caseLoad, this.unapprovedForm1});

  final CaseLoadModel caseLoad;
  final UnapprovedForm1DataModel? unapprovedForm1;

  @override
  State<Form1BScreen> createState() => _Form1BScreen();
}

class _Form1BScreen extends State<Form1BScreen> {
  int selectedStep = 0;
  bool isLoading = false;
  String dateOfEvent = '';

  List<Widget> steps = [
    const HealthyForm1b(),
    const SafeForm1b(),
    const StableForm1b(),
    const CriticalEventForm1b(),
  ];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Future.delayed(Duration.zero, () {
      Form1bProvider form1bProvider =
          Provider.of<Form1bProvider>(context, listen: false);
      form1bProvider.setFinalFormDataOvcId(widget.caseLoad.cpimsId!);
      form1bProvider
          .setFinalFormDataCareGiverId(widget.caseLoad.caregiverCpimsId!);
      if (widget.unapprovedForm1 != null) {
        form1bProvider.setSelectedDate(widget.unapprovedForm1!.dateOfEvent);
      }
    });
  }

  // bool isFormInvalid() {
  //   Form1bProvider form1bProvider =
  //       Provider.of<Form1bProvider>(context, listen: false);
  //   // Check if the date is filled
  //   bool isDateValid = (form1bProvider.formData.selectedDate != null ||
  //       form1bProvider.formData.selectedDate.isBlank!);

  //   // Check if all selected services are valid
  //   bool areServicesValid =
  //       (form1bProvider.formData.selectedServices.isBlank! &&
  //           form1bProvider.safeFormData.selectedServices.isBlank! &&
  //           form1bProvider.stableFormData.selectedServices.isBlank! &&
  //           form1bProvider.criticalEventDataForm1b.selectedEvents.isBlank!);

  //   return (isDateValid && areServicesValid);
  // }

  @override
  Widget build(BuildContext context) {
    bool isLastStep = selectedStep == steps.length - 1;
    Form1bProvider form1bProvider =
        Provider.of<Form1bProvider>(context, listen: false);

    bool isFormInvalid() {
      return ((form1bProvider.formData.selectedDate == null ||
              form1bProvider.formData.selectedDate == '') &&
          (form1bProvider.formData.selectedServices.isBlank! &&
              form1bProvider.safeFormData.selectedServices.isBlank! &&
              form1bProvider.stableFormData.selectedServices.isBlank! &&
              form1bProvider.criticalEventDataForm1b.selectedEvents.isBlank!));
    }

    return Scaffold(
      appBar: customAppBar(),
      drawer: const Drawer(
        child: CustomDrawer(),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        children: [
          const SizedBox(height: 20),
          const Text('Form 1B',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black)),
          const SizedBox(height: 5),
          const Text(
            'Caregiver Status and Service Monitoring',
            style: TextStyle(color: kTextGrey),
          ),
          const SizedBox(height: 30),
          Container(
              decoration: BoxDecoration(color: Colors.white, boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 5,
                ),
              ]),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    width: double.infinity,
                    color: Colors.black,
                    child: Text(
                      ' FORM 1B DETAILS \n CARE GIVER: ${widget.caseLoad.caregiverNames} \n CPIMS ID: ${widget.caseLoad.cpimsId}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Column(
                      children: [
                        CustomStepperWidget(
                          onTap: (index) {
                            setState(() {
                              selectedStep = index;
                            });
                          },
                          data: form1bsStepper,
                          selectedIndex: selectedStep,
                        ),
                        const SizedBox(
                          height: 25,
                        ),
                        steps[selectedStep],
                        const SizedBox(
                          height: 30,
                        ),
                        Visibility(
                          visible: isLastStep,
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Date of Event',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 10),
                                DateTextField(
                                    label: dateOfEvent.isNotEmpty
                                        ? dateOfEvent
                                        : 'Select the date',
                                    enabled: true,
                                    identifier: DateTextFieldIdentifier
                                        .dateOfAssessment,
                                    onDateSelected: (value) {
                                      setState(() {
                                        dateOfEvent = DateFormat("yyyy-MM-dd")
                                            .format(value!);
                                        if (dateOfEvent.isNotEmpty) {
                                          form1bProvider
                                              .setSelectedDate(dateOfEvent);
                                        }
                                      });
                                    }),
                                const SizedBox(
                                  height: 15,
                                ),
                              ]),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: CustomButton(
                                text: selectedStep <= 0 ? 'Cancel' : 'Previous',
                                onTap: () {
                                  if (selectedStep == 0) {
                                    Navigator.pop(context);
                                    form1bProvider.resetFormData();
                                  } else {
                                    setState(() {
                                      if (selectedStep > 0) {
                                        selectedStep--;
                                      }
                                    });
                                  }
                                },
                                color: kTextGrey,
                              ),
                            ),
                            const SizedBox(
                              width: 20,
                            ),
                            Expanded(
                              child: CustomButton(
                                isLoading: isLoading,
                                text: selectedStep == steps.length - 1
                                    ? 'Submit Form1B'
                                    : 'Next',
                                onTap: () async {
                                  // try {
                                  if (selectedStep == steps.length - 1) {
                                    if (isFormInvalid()) {
                                      Get.snackbar(
                                        'Error',
                                        'Please fill all the information',
                                        duration: const Duration(seconds: 2),
                                        snackPosition: SnackPosition.TOP,
                                        backgroundColor: Colors.red,
                                        colorText: Colors.white,
                                        margin: const EdgeInsets.all(16),
                                        borderRadius: 8,
                                      );
                                      setState(() {
                                        isLoading = false;
                                      });
                                      return;
                                    } else {
                                      try {
                                        String startInterviewTime = '';
                                        if (context.mounted) {
                                          startInterviewTime = context
                                                  .read<AppMetaDataProvider>()
                                                  .startTimeInterview ??
                                              '';
                                        }
                                        if (dateOfEvent.isEmpty &&
                                            form1bProvider
                                                    .formData.selectedDate ==
                                                "") {
                                          Get.snackbar(
                                            'Error',
                                            'Please select date of event',
                                            duration:
                                                const Duration(seconds: 2),
                                            snackPosition: SnackPosition.TOP,
                                            backgroundColor: Colors.red,
                                            colorText: Colors.white,
                                            margin: const EdgeInsets.all(16),
                                            borderRadius: 8,
                                          );
                                          setState(() {
                                            isLoading = false;
                                          });
                                        }

                                        setState(() {
                                          isLoading = true;
                                        });
                                        bool isFormSaved =
                                            await form1bProvider.saveForm1bData(
                                                form1bProvider.formData,
                                                startInterviewTime,
                                                context,
                                                widget.unapprovedForm1);

                                        setState(() {
                                          if (isFormSaved == true) {
                                            isLoading = false;
                                            if (context.mounted) {
                                              context
                                                  .read<StatsProvider>()
                                                  .updateFormOneBStats();
                                              context
                                                  .read<StatsProvider>()
                                                  .updateFormOneBDistinctStats();
                                              context
                                                  .read<AppMetaDataProvider>()
                                                  .clearFormMetaData();
                                            }
                                            Get.snackbar(
                                              'Success',
                                              'Form1B data saved successfully.',
                                              duration:
                                                  const Duration(seconds: 2),
                                              snackPosition: SnackPosition.TOP,
                                              // Display at the top of the screen
                                              backgroundColor: Colors.green,
                                              colorText: Colors.white,
                                              margin: const EdgeInsets.all(16),
                                              borderRadius: 8,
                                            );
                                            Navigator.pop(context, true);
                                            selectedStep = 0;
                                          }
                                        });
                                      } catch (e) {
                                        setState(() {
                                          isLoading = false;
                                        });
                                        if (kDebugMode) {
                                          print(
                                            "Error getting user location: ${e.toString()}",
                                          );
                                        }
                                        if (e.toString() == locationDisabled ||
                                            e.toString() == locationDenied) {
                                          if (context.mounted) {
                                            locationMissingDialog(context);
                                          }
                                        }
                                      }
                                    }
                                  } else {
                                    setState(() {
                                      isLoading = false;
                                      if (selectedStep < steps.length - 1) {
                                        selectedStep++;
                                      }
                                    });
                                  }
                                  // } catch (e) {
                                  //   if (e.toString() == locationDisabled ||
                                  //       e.toString() == locationDenied) {
                                  //     if (context.mounted) {
                                  //       setState(() {
                                  //         isLoading = false;
                                  //       });
                                  //       locationMissingDialog(context);
                                  //     }
                                  //   }
                                  // }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 30,
                        ),
                        Row(
                          children: [
                            TextButton(
                                onPressed: () {
                                  Provider.of<Form1bProvider>(context,
                                          listen: false)
                                      .resetFormData();
                                  Navigator.pop(context);
                                },
                                child: const Text(
                                  "Clear Form",
                                  style: TextStyle(color: Colors.red),
                                )),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // GestureDetector(
                        //   onTap: () {
                        //     // TODO Handle past assessments
                        //     // Get.to(() => HistoryForm1A(
                        //     //     caseLoadModel: widget.caseLoadModel));
                        //   },
                        //   child: const Row(
                        //     children: [
                        //       Text(
                        //         'Past Assessments',
                        //         style: TextStyle(color: Colors.blue),
                        //       ),
                        //       SizedBox(
                        //         width: 10,
                        //       ),
                        //       Icon(
                        //         Icons.arrow_forward_ios_rounded,
                        //         size: 15,
                        //       )
                        //     ],
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                ],
              )),
          const Footer(),
        ],
      ),
    );
  }
}

class HistoryAssessmentListWidget extends StatelessWidget {
  const HistoryAssessmentListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 4,
        itemBuilder: (context, index) {
          return const AssessmentItemWidget();
        });
  }
}

class AssessmentItemWidget extends StatelessWidget {
  const AssessmentItemWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: Text(
            'Child not Adhering to ARVs',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 50,
        ),
        Expanded(
          child: Text(
            '28-Aug-2023',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(width: 10),
        Icon(
          CupertinoIcons.delete,
          color: Colors.red,
        )
      ],
    );
  }
}
