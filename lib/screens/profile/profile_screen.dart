import 'package:cpims_mobile/Models/statistic_model.dart';
import 'package:cpims_mobile/providers/ui_provider.dart';
import 'package:cpims_mobile/widgets/app_bar.dart';
import 'package:cpims_mobile/widgets/custom_card.dart';
import 'package:cpims_mobile/widgets/drawer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    SummaryDataModel dashData = context.select((UIProvider provider) => provider.getDashData);

    return Scaffold(
      appBar: customAppBar(),
      drawer: const Drawer(
        child: CustomDrawer(),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Image.network(
              "",
              width: double.infinity,
              fit: BoxFit.fitWidth,
              errorBuilder:
                  (BuildContext context, Object exception, StackTrace? stackTrace) {
                return const Image(
                    image: AssetImage('assets/images/user-2.jpg'));
              },
            ),
            const SizedBox(height: 10,),
            CustomCard(title: "ACCOUNT DETAILS", children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                      "Username:",
                    style: TextStyle(
                      fontWeight: FontWeight.bold
                    ),
                  ),
                  const SizedBox(width: 10,),
                  Flexible(child: Text(dashData.username)),
                ],
              ),
              const SizedBox(height: 4,),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "CPIMS ID:",
                    style: TextStyle(
                        fontWeight: FontWeight.bold
                    ),
                  ),
                  const SizedBox(width: 10,),
                  Flexible(child: Text(dashData.userCpimsId.toString()))
                ],
              ),
              const SizedBox(height: 4,),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Email Address:",
                    style: TextStyle(
                        fontWeight: FontWeight.bold
                    ),
                  ),
                  const SizedBox(width: 10,),
                  Flexible(child: Text(dashData.email)),
                ],
              ),
              const SizedBox(height: 4,),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Sub-county:",
                    style: TextStyle(
                        fontWeight: FontWeight.bold
                    ),
                  ),
                  const SizedBox(width: 10,),
                  Flexible(child: Text(dashData.subCounties)),
                ],
              ),
              const SizedBox(height: 4,),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Ward:",
                    style: TextStyle(
                        fontWeight: FontWeight.bold
                    ),
                  ),
                  const SizedBox(width: 10,),
                  Flexible(child: Text(dashData.ward)),
                ],
              ),
              const SizedBox(height: 4,),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Organization Unit(s):",
                    style: TextStyle(
                        fontWeight: FontWeight.bold
                    ),
                  ),
                  const SizedBox(width: 10,),
                  Flexible(child: Text(dashData.userOrgUnits)),
                  // Text("MAKADARA SUB COUNTY CHILDREN OFFICE")
                ],
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
