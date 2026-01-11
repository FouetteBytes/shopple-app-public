import 'package:flutter/material.dart';
import 'package:shopple/values/values.dart';

import 'package:shopple/widgets/search/active_task_card.dart';
import 'package:shopple/widgets/search/inactive_task_card.dart';

class SearchTaskCard extends StatelessWidget {
  final bool activated;
  final String header;
  final String subHeader;
  final String date;
  const SearchTaskCard({
    super.key,
    required this.date,
    required this.activated,
    required this.header,
    required this.subHeader,
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
                  InactiveTaskCard(
                    header: header,
                    notifier: totalDueTrigger,
                    subHeader: subHeader,
                    date: date,
                  ),
                  AppSpaces.verticalSpace10,
                ],
              )
            : Column(
                children: [
                  ActiveTaskCard(
                    header: header,
                    notifier: totalDueTrigger,
                    subHeader: subHeader,
                    date: date,
                  ),
                  AppSpaces.verticalSpace10,
                ],
              );
      },
    );
  }
}
