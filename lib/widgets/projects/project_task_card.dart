import 'package:flutter/material.dart';
import 'package:shopple/values/values.dart';
import 'package:shopple/widgets/projects/project_task_active_card.dart';
import 'package:shopple/widgets/projects/project_task_inactive_card.dart';

class ProjectTaskCard extends StatelessWidget {
  final bool activated;
  final String header;
  final String backgroundColor;
  final String image;
  final String date;
  const ProjectTaskCard({
    super.key,
    required this.date,
    required this.activated,
    required this.header,
    required this.image,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final bool newBool = activated;
    ValueNotifier<bool> totalDueTrigger = ValueNotifier(newBool);
    return ValueListenableBuilder(
      valueListenable: totalDueTrigger,
      builder: (BuildContext context, _, __) {
        return totalDueTrigger.value
            ? Column(
                children: [
                  ProjectTaskInActiveCard(
                    header: header,
                    backgroundColor: backgroundColor,
                    notifier: totalDueTrigger,
                    date: date,
                    image: image,
                  ),
                  AppSpaces.verticalSpace10,
                ],
              )
            : Column(
                children: [
                  ProjectTaskActiveCard(
                    header: header,
                    backgroundColor: backgroundColor,
                    notifier: totalDueTrigger,
                    date: date,
                    image: image,
                  ),
                  AppSpaces.verticalSpace10,
                ],
              );
      },
    );
  }
}
