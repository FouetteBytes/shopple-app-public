import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopple/bottom_sheets/bottom_sheets.dart';
import 'package:shopple/screens/task/set_assignees.dart';
import 'package:shopple/values/values.dart';
import 'package:shopple/widgets/dashboard/sheet_goto_calendar.dart';
import 'package:shopple/widgets/forms/form_input_unlabelled.dart';
import 'package:shopple/widgets/dummy/profile_dummy.dart';

import '../add_sub_icon.dart';
import 'dashboard_add_project_sheet.dart';

// ignore: must_be_immutable
class CreateTaskBottomSheet extends StatefulWidget {
  const CreateTaskBottomSheet({super.key});

  @override
  State<CreateTaskBottomSheet> createState() => _CreateTaskBottomSheetState();
}

class _CreateTaskBottomSheetState extends State<CreateTaskBottomSheet> {
  final TextEditingController _taskNameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          AppSpaces.verticalSpace10,
          AppSpaces.verticalSpace10,
          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.shopping_cart, color: AppColors.primaryText),
                    AppSpaces.horizontalSpace10,
                    Text(
                      "My Shopping List  ",
                      style: GoogleFonts.lato(
                        color: AppColors.primaryText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Icon(Icons.expand_more, color: AppColors.primaryText),
                  ],
                ),
                AppSpaces.verticalSpace20,
                Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        gradient: LinearGradient(
                          colors: [
                            HexColor.fromHex("FD916E"),
                            HexColor.fromHex("FFE09B"),
                          ],
                        ),
                      ),
                    ),
                    AppSpaces.horizontalSpace20,
                    Expanded(
                      child: UnlabelledFormInput(
                        placeholder: "Item Name (e.g., Milk, Rice)....",
                        autofocus: true,
                        keyboardType: "text",
                        controller: _taskNameController,
                        obscureText: false,
                      ),
                    ),
                  ],
                ),
                AppSpaces.verticalSpace20,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: InkWell(
                        onTap: () {
                          Get.to(() => SetAssigneesScreen());
                        },
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ProfileDummy(
                              color: HexColor.fromHex("94F0F1"),
                              dummyType: ProfileDummyType.image,
                              scale: 1.5,
                              image: "assets/man-head.png",
                            ),
                            AppSpaces.horizontalSpace10,
                            Flexible(
                              child: CircularCardLabel(
                                label: 'Share with',
                                value: 'Family Members',
                                color: AppColors.primaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    AppSpaces.horizontalSpace10,
                    Flexible(
                      child: SheetGoToCalendarWidget(
                        cardBackgroundColor: HexColor.fromHex("7DBA67"),
                        textAccentColor: HexColor.fromHex("A9F49C"),
                        value: 'Next shopping trip',
                        label: 'Needed by',
                      ),
                    ),
                  ],
                ),
                // Spacer(),
                AppSpaces.verticalSpace20,

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      width: Utils.screenWidth * 0.6,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          BottomSheetIcon(icon: Icons.local_offer_outlined),
                          BottomSheetIcon(icon: Icons.camera_alt),
                          BottomSheetIcon(icon: Icons.priority_high),
                          BottomSheetIcon(icon: Icons.store),
                        ],
                      ),
                    ),
                    AddSubIcon(
                      scale: 0.8,
                      color: AppColors.primaryAccentColor,
                      callback: _addProject,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _addProject() {
    showAppBottomSheet(
      DashboardAddProjectSheet(),
      isScrollControlled: true,
      popAndShow: true,
    );
  }

  @override
  void dispose() {
    _taskNameController.dispose();
    super.dispose();
  }
}

class BottomSheetIcon extends StatelessWidget {
  final IconData icon;
  const BottomSheetIcon({required this.icon, super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, color: AppColors.primaryText),
      iconSize: 32,
      onPressed: null,
    );
  }
}
