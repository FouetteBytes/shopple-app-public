import 'package:flutter/material.dart';
import 'package:shopple/values/values.dart';
import 'package:shopple/widgets/buttons/primary_buttons.dart';
import 'package:shopple/widgets/buttons/text_button.dart';
import 'package:shopple/widgets/onboarding/toggle_option.dart';

class DashboardSettingsBottomSheet extends StatelessWidget {
  final ValueNotifier<bool> totalTaskNotifier;
  final ValueNotifier<bool> totalDueNotifier;
  final ValueNotifier<bool> totalCompletedNotifier;
  final ValueNotifier<bool> workingOnNotifier;
  const DashboardSettingsBottomSheet({
    super.key,
    required this.totalTaskNotifier,
    required this.totalDueNotifier,
    required this.totalCompletedNotifier,
    required this.workingOnNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppSpaces.verticalSpace10,
        AppSpaces.verticalSpace20,
        ToggleLabelOption(
          label: '    Shopping Lists',
          notifierValue: totalTaskNotifier,
          icon: Icons.shopping_cart_outlined,
        ),
        ToggleLabelOption(
          label: '    Low Stock Alert',
          notifierValue: totalDueNotifier,
          icon: Icons.inventory_2,
        ),
        ToggleLabelOption(
          label: '    Items Purchased',
          notifierValue: totalCompletedNotifier,
          icon: Icons.check_circle,
        ),
        ToggleLabelOption(
          label: '    Budget Tracker',
          notifierValue: workingOnNotifier,
          icon: Icons.monetization_on,
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.only(right: 20.0, left: 20.0, bottom: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: AppTextButton(buttonText: 'Clear All', buttonSize: 16),
              ),
              const SizedBox(width: 12),
              Flexible(
                flex: 2,
                child: AppPrimaryButton(
                  buttonHeight: 60,
                  buttonWidth: 160,
                  buttonText: "Save Changes",
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
