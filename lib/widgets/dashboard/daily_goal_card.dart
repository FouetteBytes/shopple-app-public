import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopple/values/values.dart';

class DailyGoalCard extends StatelessWidget {
  const DailyGoalCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.0),
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(20.0)),
        color: AppColors.primaryBackgroundColor,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          //left side
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Daily Goal',
                style: GoogleFonts.lato(
                  color: HexColor.fromHex("616575"),
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                ),
              ),
              AppSpaces.verticalSpace10,
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    height: 25,
                    decoration: BoxDecoration(
                      color: HexColor.fromHex("8ACA72"),
                      borderRadius: BorderRadius.all(Radius.circular(20.0)),
                    ),
                    child: Center(
                      child: Text(
                        '75%',
                        style: GoogleFonts.lato(
                          color: AppColors.primaryText,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  AppSpaces.horizontalSpace10,
                  Text(
                    'Budget Target',
                    style: GoogleFonts.lato(
                      color: AppColors.primaryText,
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              AppSpaces.verticalSpace10,
              Text(
                'You spent Rs.3,750\nof Rs.5,000 budget 💰',
                style: GoogleFonts.lato(
                  color: HexColor.fromHex("616575"),
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                ),
              ),
              AppSpaces.verticalSpace20,
              SizedBox(
                width: 120,
                height: 40,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all<Color>(
                      AppColors.primaryGreen,
                    ),
                    shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50.0),
                        side: BorderSide(color: AppColors.primaryGreen),
                      ),
                    ),
                  ),
                  child: Text(
                    'View Budget',
                    style: GoogleFonts.lato(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryText,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    width: 8,
                    color: HexColor.fromHex("434552"),
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(shape: BoxShape.circle),
                    child: ClipOval(
                      child: Image(
                        fit: BoxFit.contain,
                        image: AssetImage("assets/small-logo.png"),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 5,
                left: 5,
                child: RotatedBox(
                  quarterTurns: 1,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: 0.80),
                    duration: const Duration(milliseconds: 1000),
                    builder: (context, value, _) => SizedBox(
                      width: 90,
                      height: 90,
                      child: CircularProgressIndicator(
                        strokeWidth: 8,
                        value: value,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
