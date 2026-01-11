import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopple/bottom_sheets/bottom_sheets.dart';
import 'package:shopple/constants/constants.dart';
import 'package:shopple/data/data_model.dart';
import 'package:shopple/values/values.dart';
import 'package:shopple/widgets/buttons/primary_tab_buttons.dart';
import 'package:shopple/widgets/dark_background/dark_radial_background.dart';
import 'package:shopple/widgets/dashboard/in_bottomsheet_subtitle.dart';
import 'package:shopple/widgets/navigation/app_header.dart';
import 'package:shopple/widgets/projects/project_card_vertical.dart';
import 'package:shopple/widgets/team/more_team_details_sheet.dart';
import 'package:shopple/widgets/table_calendar.dart';

import 'my_team.dart';

class TeamDetails extends StatelessWidget {
  final String title;
  const TeamDetails({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final settingsButtonTrigger = ValueNotifier(0);

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShoppleAppHeader(
                    title: "$tabSpace $title Team",
                    widget: InkWell(
                      onTap: () {
                        showAppBottomSheet(
                          Padding(
                            padding: MediaQuery.of(context).viewInsets,
                            child: SizedBox(
                              height: Utils.screenHeight * 0.9,
                              child: MoreTeamDetailsSheet(),
                            ),
                          ),
                          isScrollControlled: true,
                        );
                      },
                      child: Icon(
                        Icons.more_horiz,
                        size: 30,
                        color: AppColors.primaryText,
                      ),
                    ),
                  ),
                  AppSpaces.verticalSpace40,
                  //tab indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      PrimaryTabButton(
                        buttonText: "Overview",
                        itemIndex: 0,
                        notifier: settingsButtonTrigger,
                      ),
                      PrimaryTabButton(
                        buttonText: "Calendar",
                        itemIndex: 1,
                        notifier: settingsButtonTrigger,
                      ),
                    ],
                  ),

                  AppSpaces.verticalSpace40,
                  TeamStory(
                    teamTitle: title,
                    numberOfMembers: "12",
                    noImages: "8",
                  ),
                  AppSpaces.verticalSpace10,
                  InBottomSheetSubtitle(
                    title:
                        "We're a growing family of 371,521 designers and \nmakers from around the world.",
                    textStyle: GoogleFonts.lato(
                      fontSize: 15,
                      color: AppColors.primaryText70,
                    ),
                  ),
                  AppSpaces.verticalSpace40,
                  ValueListenableBuilder(
                    valueListenable: settingsButtonTrigger,
                    builder: (BuildContext context, _, _) {
                      return settingsButtonTrigger.value == 0
                          ? Expanded(child: TeamProjectOverview())
                          : CalendarView();
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TeamProjectOverview extends StatelessWidget {
  const TeamProjectOverview({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        //change
        crossAxisCount: 2,
        mainAxisSpacing: 10,

        //change height 125
        mainAxisExtent: 220,
        crossAxisSpacing: 10,
      ),
      itemBuilder: (_, index) => ProjectCardVertical(
        projectName: AppData.productData[index]['projectName'],
        category: AppData.productData[index]['category'],
        color: AppData.productData[index]['color'],
        ratingsUpperNumber: AppData.productData[index]['ratingsUpperNumber'],
        ratingsLowerNumber: AppData.productData[index]['ratingsLowerNumber'],
      ),
      itemCount: 4,
    );
  }
}
