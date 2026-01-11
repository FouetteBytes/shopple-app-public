import 'package:flutter/material.dart';
import 'package:shopple/values/values.dart';

import 'active_project_selectable_container.dart';
import 'inactive_project_selectable_container.dart';

class ProjectSelectableContainer extends StatelessWidget {
  final bool activated;
  final String header;

  const ProjectSelectableContainer({
    super.key,
    required this.activated,
    required this.header,
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
                  InactiveProjectSelectableContainer(
                    header: header,
                    notifier: totalDueTrigger,
                  ),
                  AppSpaces.verticalSpace10,
                ],
              )
            : Column(
                children: [
                  ActiveProjectSelectableContainer(
                    header: header,
                    notifier: totalDueTrigger,
                  ),
                  AppSpaces.verticalSpace10,
                ],
              );
      },
    );
  }
}
