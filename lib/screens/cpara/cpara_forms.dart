import 'dart:typed_data';

import 'package:cpims_mobile/constants.dart';
import 'package:cpims_mobile/providers/app_meta_data_provider.dart';
import 'package:cpims_mobile/providers/db_provider.dart';
import 'package:cpims_mobile/screens/cpara/model/cpara_model.dart';
import 'package:cpims_mobile/screens/cpara/model/detail_model.dart';
import 'package:cpims_mobile/screens/cpara/model/health_model.dart';
import 'package:cpims_mobile/screens/cpara/model/safe_model.dart';
import 'package:cpims_mobile/screens/cpara/model/schooled_model.dart';
import 'package:cpims_mobile/screens/cpara/model/stable_model.dart';
import 'package:cpims_mobile/screens/cpara/provider/cpara_provider.dart';
import 'package:cpims_mobile/screens/cpara/widgets/cpara_details_widget.dart';
import 'package:cpims_mobile/screens/cpara/widgets/cpara_healthy_widget.dart';
import 'package:cpims_mobile/screens/cpara/widgets/cpara_safe_widget.dart';
import 'package:cpims_mobile/screens/cpara/widgets/cpara_schooled_widget.dart';
import 'package:cpims_mobile/screens/cpara/widgets/cpara_stable_widget.dart';
import 'package:cpims_mobile/screens/cpara/widgets/ovc_sub_population_form.dart';
import 'package:cpims_mobile/screens/homepage/provider/stats_provider.dart';
import 'package:cpims_mobile/widgets/app_bar.dart';
import 'package:cpims_mobile/widgets/custom_button.dart';
import 'package:cpims_mobile/widgets/custom_stepper.dart';
import 'package:cpims_mobile/widgets/drawer.dart';
import 'package:cpims_mobile/widgets/footer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:signature/signature.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../Models/case_load_model.dart';
import '../../providers/cpara/unapproved_records_screen_provider.dart';
import '../../widgets/location_dialog.dart';
import 'model/ovc_model.dart';

class CparaFormsScreen extends StatefulWidget {
  final bool isRejected;
  final String rejectedMessage;
  final String formId;
  final String cpmisID;

  final CaseLoadModel caseLoadModel;

  const CparaFormsScreen(
      {super.key,
      required this.caseLoadModel,
      this.isRejected = false,
      this.rejectedMessage = "",
      this.formId = "",
      this.cpmisID = ""});

  @override
  State<CparaFormsScreen> createState() => _CparaFormsScreenState();
}

class _CparaFormsScreenState extends State<CparaFormsScreen> {
  final ScrollController _scrollController = ScrollController();
  int selectedStep = 0;
  bool isLoading = false;
  Database? database;

  final SignatureController _signature_controller = SignatureController(
    penStrokeWidth: 1,
    penColor: Colors.red,
    exportBackgroundColor: Colors.transparent,
    exportPenColor: Colors.black,
    // onDrawStart: () => log('onDrawStart called!'),
    // onDrawEnd: () => log('onDrawEnd called!'),
  );

  // Initialize database
  @override
  void initState() {
    super.initState();
  }

  Future<Uint8List?> exportSignature() async {
    final exportController = SignatureController(
      penStrokeWidth: 2,
      exportBackgroundColor: Colors.white,
      penColor: Colors.black,
      points: _signature_controller.points,
    );
    //converting the signature to png bytes
    final signature = exportController.toPngBytes();
    //clean up the memory
    exportController.dispose();
    return signature;
  }

  fetchChildren(caseList) async {
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      context.read<CparaProvider>().updateChildren(caseList);
    });
  }

  List<CheckboxQuestion> questions = [
    CheckboxQuestion(id: 1, question: 'Orphan', questionID: "double"),
    CheckboxQuestion(id: 2, question: 'AGYW', questionID: "AGYW"),
    CheckboxQuestion(id: 3, question: 'HEI', questionID: "HEI"),
    CheckboxQuestion(id: 4, question: 'Child of FSW', questionID: "FSW"),
    CheckboxQuestion(id: 5, question: 'Child of PLHIV', questionID: "PLHIV"),
    CheckboxQuestion(id: 6, question: 'CLHIV', questionID: "CLHIV"),
    CheckboxQuestion(id: 7, question: 'SVAC', questionID: "SVAC"),
    CheckboxQuestion(
        id: 8, question: 'Household Affected by HIV', questionID: "AHIV"),
  ];

  void clearCparaContent() {
    Navigator.pop(context);
    context.read<CparaProvider>().clearCparaProvider();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> steps = [
      const CparaDetailsWidget(),
      const CparaHealthyWidget(),
      const CparaStableWidget(),
      CparaSafeWidget(isRejected: widget.isRejected),
      const CparaSchooledWidget(),
    ];

    return Scaffold(
      appBar: customAppBar(),
      drawer: const Drawer(
        child: CustomDrawer(),
      ),
      body: ListView(
        controller: _scrollController, // Assign the ScrollController
        padding: const EdgeInsets.symmetric(horizontal: 15),
        children: [
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
                      'Case Plan Achievement Readiness Assessment \n ${widget.caseLoadModel.caregiverNames}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  if (widget.isRejected == true)
                    Padding(
                      padding: const EdgeInsets.only(top: 15.0),
                      child: Container(
                          padding: const EdgeInsets.all(10),
                          width: double.infinity,
                          color: Colors.red,
                          child: Text(
                            widget.rejectedMessage,
                            style: const TextStyle(color: Colors.white),
                          )),
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
                          data: cparaStepperData,
                          selectedIndex: selectedStep,
                        ),
                        const SizedBox(
                          height: 25,
                        ),
                        steps[selectedStep],
                        const SizedBox(
                          height: 30,
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: CustomButton(
                                text: selectedStep <= 0 ? 'Cancel' : 'Previous',
                                onTap: () {
                                  if (selectedStep == 0) {
                                    Navigator.pop(context);
                                    context
                                        .read<CparaProvider>()
                                        .clearCparaProvider();
                                  }
                                  _scrollController.animateTo(
                                    0,
                                    duration: const Duration(milliseconds: 100),
                                    curve: Curves.easeInOut,
                                  );
                                  setState(() {
                                    if (selectedStep > 0) {
                                      selectedStep--;
                                    }
                                  });
                                },
                                color: kTextGrey,
                              ),
                            ),
                            const SizedBox(
                              width: 50,
                            ),
                            Expanded(
                              child: CustomButton(
                                isLoading: isLoading,
                                text: selectedStep == steps.length - 1
                                    ? 'Submit'
                                    : 'Next',
                                onTap: () async {
                                  if (selectedStep == steps.length - 1) {
                                    CparaProvider cparaProvider =
                                        context.read<CparaProvider>();

                                    // display collected data
                                    DetailModel detailModel =
                                        cparaProvider.detailModel ??
                                            DetailModel();
                                    HealthModel healthModel =
                                        cparaProvider.healthModel ??
                                            HealthModel();

                                    StableModel stableModel =
                                        cparaProvider.stableModel ??
                                            StableModel();
                                    SafeModel safeModel =
                                        cparaProvider.safeModel ?? SafeModel();
                                    SchooledModel schooledModel =
                                        cparaProvider.schooledModel ??
                                            SchooledModel();
                                    CparaOvcSubPopulation cparaOvcSub =
                                        cparaProvider.cparaOvcSubPopulation ??
                                            CparaOvcSubPopulation();
                                    try {
                                      cparaFormValidation(
                                          context: context,
                                          detailModel: detailModel,
                                          ovcSubPopulation: cparaProvider
                                                  .cparaOvcSubPopulation ??
                                              CparaOvcSubPopulation(),
                                          health: healthModel,
                                          stable: stableModel,
                                          safe: safeModel,
                                          schooled: schooledModel);
                                      // number of children
                                      List<CaseLoadModel> children =
                                          cparaProvider.children;

                                      if (safeModel.childrenQuestions == null) {
                                        List<SafeChild> childrenQuestions = [];
                                        for (int i = 0;
                                            i < children.length;
                                            i++) {
                                          childrenQuestions.add(SafeChild(
                                              question1: null,
                                              ovcId: "${children[i].cpimsId}",
                                              name:
                                                  "${children[i].ovcFirstName} ${children[i].ovcSurname}"));
                                        }

                                        safeModel = safeModel.copyWith(
                                            childrenQuestions:
                                                childrenQuestions);
                                        cparaProvider
                                            .updateSafeModel(safeModel);
                                      }

                                      if (healthModel.childrenQuestions ==
                                          null) {
                                        List<HealthChild> childrenQuestions =
                                            [];
                                        for (int i = 0;
                                            i < children.length;
                                            i++) {
                                          childrenQuestions.add(HealthChild(
                                              question1: "",
                                              question2: '',
                                              question3: '',
                                              id: "${children[i].cpimsId}",
                                              name:
                                                  "${children[i].ovcFirstName} ${children[i].ovcSurname}"));
                                        }
                                        healthModel = healthModel.copyWith(
                                            childrenQuestions:
                                                childrenQuestions);
                                        cparaProvider
                                            .updateHealthModel(healthModel);
                                      }

                                      String? ovsId;
                                      if (widget.isRejected == true) {
                                        ovsId = widget.cpmisID;
                                      } else {
                                        ovsId = cparaProvider
                                            .caseLoadModel?.cpimsId;
                                      }

                                      if (ovsId == null) {
                                        throw ("No CPMSID found");
                                      }

                                      // Show signature
                                      Uint8List blob = await showDialog(
                                          barrierDismissible: false,
                                          context: context,
                                          builder: (context) {
                                            return SimpleDialog(
                                              backgroundColor: Colors.white,
                                              title: const Text('Sign below'),
                                              titleTextStyle: TextStyle(
                                                  fontSize: 16.sp,
                                                  color: Colors.black),
                                              children: [
                                                Center(
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Signature(
                                                        controller:
                                                            _signature_controller,
                                                        height: 300,
                                                        width: 300,
                                                        backgroundColor:
                                                            Colors.grey[200]!,
                                                      ),
                                                      Container(
                                                        width: 300,
                                                        color: Colors.white,
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                vertical: 20),
                                                        child: Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceAround,
                                                          children: [
                                                            TextButton(
                                                              onPressed:
                                                                  () async {
                                                                var signatureData =
                                                                    await exportSignature();
                                                                if (context
                                                                    .mounted) {
                                                                  Navigator.of(
                                                                          context)
                                                                      .pop(
                                                                          signatureData);
                                                                }
                                                              },
                                                              child: Text(
                                                                "Done",
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .blue,
                                                                    fontSize:
                                                                        16.sp),
                                                              ),
                                                            ),
                                                            TextButton(
                                                              onPressed: () {
                                                                setState(() =>
                                                                    _signature_controller
                                                                        .clear());
                                                                Navigator.of(
                                                                        context)
                                                                    .pop();
                                                              },
                                                              child: Text(
                                                                "Clear",
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        16.sp,
                                                                    color: Colors
                                                                        .red),
                                                              ),
                                                            )
                                                          ],
                                                        ),
                                                      )
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            );
                                          });
                                      setState(() {
                                        isLoading = true;
                                      });
                                      String ovcpmisid = ovsId;
                                      // Insert to db
                                      CparaModel cparaModelDB = CparaModel(
                                          detail: detailModel,
                                          safe: safeModel,
                                          stable: stableModel,
                                          schooled: schooledModel,
                                          health: (healthModel),
                                          ovcSubPopulations: cparaOvcSub,
                                          uuid:
                                              cparaProvider.cparaModel?.uuid ??
                                                  "");
                                      // Create form
                                      String startTime = context
                                              .read<AppMetaDataProvider>()
                                              .startTimeInterview ??
                                          DateTime.now().toIso8601String();
                                      await LocalDb.instance.insertCparaData(
                                        cparaModelDB: cparaModelDB,
                                        ovcId: ovcpmisid,
                                        startTime: startTime,
                                        isRejected: widget.isRejected,
                                        signature: blob,
                                        careProviderId: ovcpmisid,
                                        caregiverCpimsId: widget.caseLoadModel
                                                .caregiverCpimsId ??
                                            "",
                                      );

                                      if (context.mounted) {
                                        if (widget.isRejected) {
                                          context
                                              .read<
                                                  UnapprovedRecordsScreenProvider>()
                                              .updateUnnapprovedCparas();
                                        }
                                        cparaProvider.clearCparaProvider();
                                        context
                                            .read<StatsProvider>()
                                            .updateCparaFormStats();
                                        context
                                            .read<StatsProvider>()
                                            .updateCparaDistinctStats();
                                        //navigate back
                                        Get.snackbar(
                                          'Success',
                                          'Successfully saved CPARA form',
                                          backgroundColor: Colors.green,
                                          colorText: Colors.white,
                                        );
                                        setState(() {
                                          isLoading = false;
                                        });
                                        Navigator.pop(context);
                                      }
                                    } catch (e) {
                                      setState(() {
                                        isLoading = false;
                                      });
                                      if (e.toString() == locationDisabled ||
                                          e.toString() == locationDenied) {
                                        if (context.mounted) {
                                          locationMissingDialog(context);
                                        }
                                      } else {
                                        Get.snackbar(
                                          'Error',
                                          e.toString(),
                                          backgroundColor: Colors.red,
                                          colorText: Colors.white,
                                        );
                                      }
                                    }
                                  }
                                  _scrollController.animateTo(
                                    0,
                                    duration: const Duration(milliseconds: 100),
                                    curve: Curves.easeInOut,
                                  );
                                  setState(() {
                                    if (selectedStep < steps.length - 1) {
                                      selectedStep++;
                                    }
                                  });
                                },
                              ),
                            )
                          ],
                        ),

                        // Cancel Button
                        Padding(
                          padding: const EdgeInsets.only(top: 10.0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                                onPressed: () {
                                  showDialog(
                                      barrierDismissible: false,
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          content: const Text(
                                              "Are you sure you want to clear the form?"),
                                          actions: [
                                            TextButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                  clearCparaContent();
                                                },
                                                child: Text(
                                                  "Yes",
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                    fontSize: 14.sp,
                                                  ),
                                                )),
                                            TextButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                },
                                                child: Text(
                                                  "No",
                                                  style: TextStyle(
                                                    fontSize: 14.sp,
                                                  ),
                                                ))
                                          ],
                                        );
                                      });
                                },
                                child: Text(
                                  "Clear Form",
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 14.sp,
                                  ),
                                )),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )),
          const SizedBox(height: 20),
          const Footer(),
        ],
      ),
    );
  }

  void handleSubmit(
      {required BuildContext context, required DateTime? selectedDate}) async {
    CparaOvcSubPopulation ovcSub =
        context.read<CparaProvider>().cparaOvcSubPopulation ??
            CparaOvcSubPopulation();
    final localDb = LocalDb.instance;
    List<CparaOvcChild> listOfOvcChild = ovcSub.childrenQuestions ?? [];

    final currentContext = context; // Store the context in a local variable

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

        String uuid = const Uuid().v4();
        String? dateOfAssessment = selectedDate != null
            ? DateFormat('yyyy-MM-dd').format(selectedDate)
            : null;
        await localDb.insertOvcSubpopulationData(
            uuid,
            widget.caseLoadModel.cpimsId!,
            dateOfAssessment!,
            selectedQuestions);
      }
      // if(mounted) {
      //   Navigator.pop(context);
      // }
    } catch (error) {
      if (currentContext.mounted) {
        showDialog(
          context: currentContext, // Use the local context
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text('An error occurred: $error'),
            actions: [
              TextButton(
                onPressed: () {
                  Get.back(); // Close the dialog
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  void cparaFormValidation(
      {required BuildContext context,
      required DetailModel detailModel,
      required CparaOvcSubPopulation ovcSubPopulation,
      required HealthModel health,
      required StableModel stable,
      required SafeModel safe,
      required SchooledModel schooled}) {
//todo: 1. validate the details part using details model
    if (detailModel.isFirstAssessment == null) {
      throw ("Please fill all mandatory fields in Details section.");
    } else if ((detailModel.isFirstAssessment?.toLowerCase() == "no" &&
            detailModel.dateOfLastAssessment == null) ||
        detailModel.isChildHeaded == null ||
        detailModel.hasHivExposedInfant == null ||
        detailModel.hasPregnantOrBreastfeedingWoman == null ||
        detailModel.dateOfAssessment == null) {
      throw ("Please fill all mandatory fields in Details section.");
    } else if ((detailModel.isFirstAssessment?.toLowerCase() == "no" &&
        detailModel.dateOfLastAssessment != null &&
        DateTime.parse(detailModel.dateOfLastAssessment!)
            .isAfter(DateTime.parse(detailModel.dateOfAssessment!)))) {
      throw ("The last assessment date cannot be ahead of the date of this assessment.");
    }
    // else if (detailModel.isChildHeaded == null ||
    //     detailModel.hasHivExposedInfant == null ||
    //     detailModel.hasPregnantOrBreastfeedingWoman == null ||
    //     detailModel.dateOfAssessment == null) {
    //   throw ("Please fill all mandatory fields in Details section.");
    // }
    // todo: 2. validate the ovc subpopulation using CparaOvcSubpopulation
    // todo: 3. validate health details using health model
    else if (health.question1 == null ||
            health.question2 == null ||
            health.question3 == null ||
            health.question4 == null ||
            health.question5 == null ||
            health.question6 == null ||
            health.question7 == null ||
            health.question8 == null ||
            health.question9 == null ||
            health.question10 == null ||
            health.question11 == null ||
            health.question12 == null ||
            health.question13 == null ||
            health.question14 == null ||
            health.question15 == null ||
            health.question16 == null ||
            health.question17 == null ||
            health.question18 == null ||
            (health.childrenQuestions ?? []).isNotEmpty &&
                validateHealthChildren(
                    childrenQuestions: health.childrenQuestions)
        //     || health.overallQuestion1 == null || health.overallQuestion2 == null || health.overallQuestion3 == null
        // || health.overallQuestion4 == null || health.overallQuestion5 == null || health.overallQuestion6 == null || health.overallQuestion7 == null
        ) {
      throw ("Please fill all mandatory fields in Health section.");
    }
    // todo: 4. validate stable details using stable model
    else if (stable.question1 == null ||
        stable.question2 == null ||
        stable.question3 == null) {
      throw ("Please fill all mandatory fields in Stable section.");
    }
    // todo: 5. validate safe details using safe model
    else if (
        // safe.question1 == null ||
        //     safe.question2 == null ||
        safe.question3 == null ||
            safe.question4 == null ||
            safe.question5 == null ||
            safe.question6 == null ||
            safe.question7 == null
        // safe.childrenQuestions == null
        // // || safe.overallQuestion1 == null || safe.overallQuestion2 == null
        // ||
        // (safe.childrenQuestions ?? []).isNotEmpty &&
        //     validateSafeChildren(childrenQuestions: safe.childrenQuestions)
        ) {
      throw ("Please fill all mandatory fields in Safe section.");
    }
    // todo: 6. validate schooled details using schooled model
    else if (schooled.question1 == null ||
            schooled.question2 == null ||
            schooled.question3 == null ||
            schooled.question4 == null
        //     ||
        // schooled.mainquestion1 == null || schooled.mainquestion2 == null
        ) {
      throw ("Please fill all mandatory fields in Schooled section.");
    } else {}
  }

  bool validateHealthChildren({required List<HealthChild>? childrenQuestions}) {
    for (HealthChild child in childrenQuestions ?? []) {
      if (child.question1 == "" ||
          child.question2 == "" ||
          child.question3 == "") {
        return true;
      }
    }
    return false;
  }

  bool validateSafeChildren({required List<SafeChild>? childrenQuestions}) {
    for (SafeChild child in childrenQuestions ?? []) {
      if (child.question1 == "" || child.question1 == null) {
        return true;
      }
    }
    return false;
  }

  void showErrorSnackbar() {
    Get.snackbar(
      'Error',
      'Please fill all mandatory fields.',
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
    return;
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _signature_controller.dispose();
    super.dispose();
  }
}
