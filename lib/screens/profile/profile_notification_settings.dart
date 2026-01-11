import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopple/constants/constants.dart';
import 'package:shopple/values/values.dart';
import 'package:shopple/widgets/buttons/primary_progress_button.dart';
import 'package:shopple/widgets/dark_background/dark_radial_background.dart';
import 'package:shopple/widgets/navigation/app_header.dart';
import 'package:shopple/widgets/onboarding/labelled_option.dart';
import 'package:shopple/widgets/container_label.dart';

class ProfileNotificationSettings extends StatelessWidget {
  const ProfileNotificationSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final assignmedToMe = ValueNotifier(true);
    final taskCompleted = ValueNotifier(false);
    final mentionedMe = ValueNotifier(true);
    final directMessage = ValueNotifier(false);
    return Scaffold(
      body: Stack(
        children: [
          DarkRadialBackground(
            color: HexColor.fromHex("#181a1f"),
            position: "topLeft",
          ),
          Padding(
            padding: EdgeInsets.only(left: 20, right: 20),
            child: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    ShoppleAppHeader(
                      title: "$tabSpace Shopping Alerts",
                      widget: PrimaryProgressButton(
                        width: 80,
                        height: 40,
                        label: "Done",
                        textStyle: GoogleFonts.lato(
                          color: AppColors.primaryText,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    AppSpaces.verticalSpace40,
                    Container(
                      width: double.infinity,
                      height: Utils.screenHeight * 0.9,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: AppColors.primaryBackgroundColor,
                      ),
                      child: Column(
                        children: [
                          LabelledOption(
                            label: 'Price Drop Alerts',
                            icon: Icons.trending_down,
                          ),
                          LabelledOption(
                            label: 'Shopping Reminders',
                            icon: Icons.alarm,
                          ),
                          LabelledOption(
                            label: 'Budget Warnings',
                            icon: Icons.warning,
                          ),
                          LabelledOption(
                            label: 'Until next 2 days',
                            icon: Icons.calendar_today,
                          ),
                          LabelledOption(
                            label: 'Custom',
                            icon: Icons.calendar_today,
                          ),
                        ],
                      ),
                    ),
                    AppSpaces.verticalSpace40,
                    ContainerLabel(label: "NOTIFY MY ABOUT"),
                    AppSpaces.verticalSpace40,
                    LabelledCheckbox(
                      label: "Task assigned to me",
                      notifierValue: assignmedToMe,
                    ),
                    LabelledCheckbox(
                      label: "Task completed",
                      notifierValue: taskCompleted,
                    ),
                    LabelledCheckbox(
                      label: "Mentioned Me",
                      notifierValue: mentionedMe,
                    ),
                    LabelledCheckbox(
                      label: "Direct Message",
                      notifierValue: directMessage,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LabelledCheckbox extends StatelessWidget {
  final String label;
  final ValueNotifier<bool>? notifierValue;

  const LabelledCheckbox({required this.label, super.key, this.notifierValue});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.lato(color: AppColors.primaryText, fontSize: 17),
        ),
        Theme(
          data: Theme.of(context).copyWith(unselectedWidgetColor: Colors.grey),
          child: ValueListenableBuilder(
            valueListenable: notifierValue!,
            builder: (BuildContext context, _, _) {
              return Checkbox(
                value: notifierValue!.value,
                activeColor: AppColors.primaryAccentColor,
                onChanged: (bool? value) => notifierValue!.value = value!,
              );
            },
          ),
        ),
      ],
    );
  }
}
