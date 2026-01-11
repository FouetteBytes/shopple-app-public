import 'package:flutter/material.dart';

import 'active_employee_card.dart';
import 'inactive_employee_card.dart';

class EmployeeCard extends StatelessWidget {
  final String employeeName;
  final String employeeImage;
  final String employeePosition;
  final Color backgroundColor;
  final bool activated;
  const EmployeeCard({
    super.key,
    required this.employeeName,
    required this.employeeImage,
    required this.backgroundColor,
    required this.employeePosition,
    required this.activated,
  });

  @override
  Widget build(BuildContext context) {
    final bool newBool = activated;
    ValueNotifier<bool> totalDueTrigger = ValueNotifier(newBool);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: ValueListenableBuilder(
        valueListenable: totalDueTrigger,
        builder: (BuildContext context, _, __) {
          return Container(
            child: totalDueTrigger.value
                ? ActiveEmployeeCard(
                    color: backgroundColor,
                    notifier: totalDueTrigger,
                    employeeImage: employeeImage,
                    employeeName: employeeName,
                    employeePosition: employeePosition,
                  )
                : InactiveEmployeeCard(
                    color: backgroundColor,
                    notifier: totalDueTrigger,
                    employeeImage: employeeImage,
                    employeeName: employeeName,
                    employeePosition: employeePosition,
                  ),
          );
        },
      ),
    );
  }
}
