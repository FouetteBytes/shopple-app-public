import 'package:flutter/material.dart';
import 'package:shopple/data/data_model.dart';
import 'package:shopple/values/values.dart';
import 'package:shopple/widgets/dashboard/overview_task_container.dart';
import 'package:shopple/widgets/dashboard/task_progress_card.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';

class DashboardOverview extends StatelessWidget {
  const DashboardOverview({super.key});

  @override
  Widget build(BuildContext context) {
    final dynamic data = AppData.progressIndicatorList;

    List<Widget> cards = List.generate(
      5,
      (index) => TaskProgressCard(
        cardTitle: data[index]['cardTitle'],
        rating: data[index]['rating'],
        progressFigure: data[index]['progress'],
        percentageGap: int.parse(data[index]['progressBar']),
      ),
    );

    return Column(
      children: [
        SizedBox(
          height: 150,
          child: CardSwiper(
            // Updated widget
            cardsCount: cards.length,
            cardBuilder:
                (
                  context,
                  index,
                  horizontalThresholdPercentage,
                  verticalThresholdPercentage,
                ) {
                  return cards[index];
                },
          ),
        ),
        AppSpaces.verticalSpace10,
        Column(
          children: [
            OverviewTaskContainer(
              cardTitle: "Shopping Lists",
              numberOfItems: "4",
              imageUrl: "assets/orange_pencil.png",
              backgroundColor: HexColor.fromHex("EFA17D"),
            ),
            OverviewTaskContainer(
              cardTitle: "Items Purchased",
              numberOfItems: "24",
              imageUrl: "assets/green_pencil.png",
              backgroundColor: HexColor.fromHex("7FBC69"),
            ),
            OverviewTaskContainer(
              cardTitle: "Budget Saved",
              numberOfItems: "Rs.1,250",
              imageUrl: "assets/cone.png",
              backgroundColor: HexColor.fromHex("EDA7FA"),
            ),
          ],
        ),
      ],
    );
  }
}
