import 'package:cpims_mobile/constants.dart';
import 'package:cpims_mobile/providers/db_provider.dart';
import 'package:cpims_mobile/providers/ui_provider.dart';
import 'package:cpims_mobile/screens/cpara/model/cpara_model.dart';
import 'package:cpims_mobile/screens/cpara/model/detail_model.dart';
import 'package:cpims_mobile/screens/cpara/model/health_model.dart';
import 'package:cpims_mobile/screens/cpara/model/safe_model.dart';
import 'package:cpims_mobile/screens/cpara/model/schooled_model.dart';
import 'package:cpims_mobile/screens/cpara/model/stable_model.dart';
import 'package:cpims_mobile/screens/cpara/provider/cpara_provider.dart';
import 'package:cpims_mobile/screens/cpara/provider/db_util.dart';
import 'package:cpims_mobile/screens/cpara/widgets/cpara_details_widget.dart';
import 'package:cpims_mobile/screens/cpara/widgets/cpara_healthy_widget.dart';
import 'package:cpims_mobile/screens/cpara/widgets/cpara_safe_widget.dart';
import 'package:cpims_mobile/screens/cpara/widgets/cpara_schooled_widget.dart';
import 'package:cpims_mobile/screens/cpara/widgets/cpara_stable_widget.dart';
import 'package:cpims_mobile/widgets/app_bar.dart';
import 'package:cpims_mobile/widgets/custom_button.dart';
import 'package:cpims_mobile/widgets/custom_stepper.dart';
import 'package:cpims_mobile/widgets/drawer.dart';
import 'package:cpims_mobile/widgets/footer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

import '../../Models/case_load_model.dart';

class CparaFormsScreen extends StatefulWidget {
  final CaseLoadModel caseLoadModel;

  const CparaFormsScreen({super.key, required this.caseLoadModel});

  @override
  State<CparaFormsScreen> createState() => _CparaFormsScreenState();
}

class _CparaFormsScreenState extends State<CparaFormsScreen> {
  final ScrollController _scrollController = ScrollController();
  int selectedStep = 0;

  List<Widget> steps = [
    const CparaDetailsWidget(),
    const CparaHealthyWidget(),
    const CparaStableWidget(),
    const CparaSafeWidget(),
    const CparaSchooledWidget(),
  ];

  Database? database;
  static const databaseName = "CPARAv2.db";

  // Initialize database
  @override
  void initState() {
    super.initState();
    final caseLoadData =
        Provider.of<UIProvider>(context, listen: false).caseLoadData;
    // todo: update case load data in Cpara provider
    fetchChildren(caseLoadData);
  }

  Future<void> initializeDbInstance() async {
    database = await LocalDb.instance.database;
    if (mounted) setState(() {});
  }

  fetchChildren(caseList) async {
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      context.read<CparaProvider>().updateChildren(caseList);
    });
  }

  @override
  Widget build(BuildContext context) {
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
                                text: selectedStep == steps.length - 1
                                    ? 'Submit'
                                    : 'Next',
                                onTap: () async {
                                  if (selectedStep == steps.length - 1) {
                                    handleSubmitCparaToUpstream();
                                    // display collected data
                                    DetailModel detailModel = context
                                            .read<CparaProvider>()
                                            .detailModel ??
                                        DetailModel();
                                    HealthModel healthModel = context
                                            .read<CparaProvider>()
                                            .healthModel ??
                                        HealthModel();
                                    // context.read<CparaProvider>().updateHealthModel((healthModel ?? HealthModel()
                                    //     ));
                                    StableModel stableModel = context
                                            .read<CparaProvider>()
                                            .stableModel ??
                                        StableModel();
                                    SafeModel safeModel = context
                                            .read<CparaProvider>()
                                            .safeModel ??
                                        SafeModel();
                                    SchooledModel schooledModel = context
                                            .read<CparaProvider>()
                                            .schooledModel ??
                                        SchooledModel();

                                    // number of children
                                    List<CaseLoadModel> children =
                                        context.read<CparaProvider>().children;

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
                                          childrenQuestions: childrenQuestions);
                                      context
                                          .read<CparaProvider>()
                                          .updateSafeModel(safeModel);
                                    }

                                    if (healthModel.childrenQuestions == null) {
                                      List<HealthChild> childrenQuestions = [];
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
                                          childrenQuestions: childrenQuestions);
                                      context
                                          .read<CparaProvider>()
                                          .updateHealthModel(healthModel);
                                    }

                                    CparaModel? cparaModel = context
                                        .read<CparaProvider>()
                                        .cparaModel;

                                    try {
                                      String? ovsId = context
                                          .read<CparaProvider>()
                                          .caseLoadModel
                                          ?.cpimsId;
                                      // String? careGiverId = context.read<CparaProvider>().caseLoadModel?.cpimsId;

                                      if (ovsId == null)
                                        throw ("No CPMSID found");
                                      String ovcpmisid = ovsId ?? "0";
                                      // Insert to db
                                      CparaModel cparaModelDB = CparaModel(
                                        detail: detailModel,
                                        safe: safeModel,
                                        stable: stableModel,
                                        schooled: schooledModel,
                                        health: (healthModel),
                                      );
                                      // Create form
                                      await LocalDb.instance.insertCparaData(
                                          cparaModelDB: cparaModelDB,
                                          ovcId: ovcpmisid,
                                          careProviderId: ovcpmisid);

                                      debugPrint("Here is the cpara data being saved $cparaModelDB");
                                      if (context.mounted) {
                                        context
                                            .read<CparaProvider>()
                                            .clearCparaProvider();
                                        showDialog(
                                          context: context,
                                          // Use the context from the build method
                                          builder: (context) => AlertDialog(
                                            title: const Text('Success'),
                                            content: const Text(
                                                'CPARA data saved successfully.'),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  Get.back(); // Close the dialog
                                                  Get.back(); // Go back to the previous screen
                                                },
                                                child: const Text('OK'),
                                              ),
                                            ],
                                          ),
                                        );
                                      }
                                    } catch (err) {
                                      debugPrint("Error saving cpara data ${err.toString()}");
                                    }
                                  }
                                  // else{
                                  //   var form = await getUnsynchedForms(await LocalDb.instance.database);
                                  //   print(form);
                                  // }

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
                      ],
                    ),
                  ),
                ],
              )),
          const SizedBox(height: 20),
          const PastCPARAWidget(),
          ElevatedButton(
              onPressed: () async {
                await submitCparaToUpstream();
              },
              child: const Text("Sync")),
          const Footer(),
        ],
      ),
    );
  }

  void handleSubmitCparaToUpstream() {
    print("I was called");
  }
}
