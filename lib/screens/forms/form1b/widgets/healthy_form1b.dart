import 'package:cpims_mobile/providers/form1b_provider.dart';
import 'package:cpims_mobile/screens/registry/organisation_units/widgets/steps_wrapper.dart';
import 'package:cpims_mobile/services/manager/metadata_manager.dart';
import 'package:cpims_mobile/utils/map_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:multi_dropdown/multiselect_dropdown.dart';
import 'package:provider/provider.dart';

import '../utils/form1bConstants.dart';

class HealthyForm1b extends StatefulWidget {
  const HealthyForm1b({Key? key}) : super(key: key);

  @override
  State<HealthyForm1b> createState() => _HealthyForm1bState();
}

class _HealthyForm1bState extends State<HealthyForm1b> {
  List<ValueItem> caregiverHealthServiceItems =
      careGiverHealthServices.map((service) {
    return ValueItem(
        label: service['item_description'], value: service['item_id']);
  }).toList();

  List<ValueItem> selectedCareGiverServices = [];
  List<ValueItem> selectedCareGiverServicesOptions = [];
  String currentlySelectedDate = "";

  @override
  Widget build(BuildContext context) {
    Form1bProvider form1bProvider = Provider.of<Form1bProvider>(context);
    selectedCareGiverServicesOptions = form1bProvider.formData.selectedServices;
    currentlySelectedDate = form1bProvider.formData.selectedDate!;
    String healthDomainId = domainsList[1]['item_id'];

    return StepsWrapper(
      title: 'Caregiver health and nutrition status',
      children: [
        const Text(
          'Service(s)',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        MultiSelectDropDown(
          hint: 'Services(s)',
          onOptionSelected: (selectedServices) {
            selectedCareGiverServices = selectedServices;
            form1bProvider.setSelectedHealthServices(
                selectedCareGiverServices, healthDomainId);
          },
          options: MetadataManager.getInstance().form1bitems.toValueItemList(),
          maxItems: 13,
          selectedOptions: selectedCareGiverServicesOptions.cast<ValueItem>(),
          disabledOptions: const [ValueItem(label: 'Option 1', value: '1')],
          selectionType: SelectionType.multi,
          chipConfig: const ChipConfig(wrapType: WrapType.wrap),
          dropdownHeight: 300,
          optionTextStyle: const TextStyle(fontSize: 16),
          selectedOptionIcon: const Icon(Icons.check_circle),
          borderRadius: BorderRadius.circular(5.w).topLeft.x,
        ),
        const SizedBox(
          height: 15,
        ),
      ],
    );
  }
}
