import 'package:flutter/material.dart';
import '../../values/values.dart';
import 'package:google_fonts/google_fonts.dart';

class PostBottomWidget extends StatelessWidget {
  final String label;
  const PostBottomWidget({required this.label, super.key});

  @override
  Widget build(BuildContext context) {
    // Return plain container; parent (Stack/Align) decides positioning.
    return Container(
      padding: const EdgeInsets.only(left: 20),
      width: Utils.screenWidth,
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.primaryBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Transform.rotate(
            angle: 195.2,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.primaryAccentColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.attach_file,
                color: AppColors.primaryText,
                size: 26,
              ),
            ),
          ),
          AppSpaces.horizontalSpace20,
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.lato(
                color: AppColors.primaryText,
                fontSize: 15,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
