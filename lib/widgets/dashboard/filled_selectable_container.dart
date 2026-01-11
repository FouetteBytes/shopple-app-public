import 'package:flutter/material.dart';
import '../../values/values.dart';
import 'package:google_fonts/google_fonts.dart';

class FilledSelectableContainer extends StatelessWidget {
  const FilledSelectableContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(left: 15.0),
      height: 120,
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                text: TextSpan(
                  text: '6 members ',
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    color: HexColor.fromHex("92EAEA"),
                    fontWeight: FontWeight.bold,
                  ),
                  children: <TextSpan>[
                    TextSpan(
                      text: 'are invited',
                      style: GoogleFonts.lato(
                        color: AppColors.primaryText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                //mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.edit, color: AppColors.primaryText, size: 20),
                  //AppSpaces.horizontalSpace10,
                  IconButton(
                    onPressed: null,
                    icon: Icon(
                      Icons.add,
                      color: AppColors.primaryText,
                      size: 25,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Transform.scale(
            alignment: Alignment.topLeft,
            origin: Offset.zero,
            scale: 0.7,
            child: buildStackedImages(numberOfMembers: "2"),
          ),
        ],
      ),
    );
  }
}
