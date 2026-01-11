import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../values/values.dart';

class ContactPermissionCard extends StatelessWidget {
  final VoidCallback onRequestPermission;

  const ContactPermissionCard({super.key, required this.onRequestPermission});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryAccentColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primaryAccentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(
              FontAwesomeIcons.addressBook,
              size: 32,
              color: AppColors.primaryAccentColor,
            ),
          ),
          AppSpaces.verticalSpace20,
          Text(
            "Find Your Friends",
            style: GoogleFonts.lato(
              color: AppColors.primaryText,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          AppSpaces.verticalSpace10,
          Text(
            "Allow access to your contacts to find friends who are already using Shopple. We protect your privacy by only storing encrypted contact data.",
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(
              color: AppColors.primaryText70,
              fontSize: 16,
              height: 1.5,
            ),
          ),
          AppSpaces.verticalSpace20,
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: onRequestPermission,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryAccentColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(FontAwesomeIcons.unlock, size: 16),
                  SizedBox(width: 8),
                  Text(
                    "Allow Contact Access",
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AppSpaces.verticalSpace10,
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                FontAwesomeIcons.shield,
                size: 14,
                color: AppColors.primaryText30,
              ),
              SizedBox(width: 6),
              Text(
                "Your contacts are encrypted and secure",
                style: GoogleFonts.lato(
                  color: AppColors.primaryText30,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
