import 'package:flutter/material.dart';
import '../../values/values.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopple/screens/profile/edit_profile.dart';
import 'package:shopple/widgets/profile/text_outlined_button.dart'; // Now this import is used!
import 'package:shopple/widgets/dummy/profile_dummy.dart';

import 'back_button.dart';

class DefaultNav extends StatelessWidget {
  final String title;
  final ProfileDummyType? type;
  const DefaultNav({super.key, this.type, required this.title});

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for dynamic sizing
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppBackButton(), // This is the actual back button
        // Center title with responsive font size
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(
              fontSize:
                  screenWidth * 0.05, // Dynamic font size (5% of screen width)
              color: AppColors.primaryText,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Builder(
          builder: (context) {
            if (type == ProfileDummyType.icon) {
              return ProfileDummy(
                color: HexColor.fromHex("93F0F0"),
                dummyType: ProfileDummyType.image,
                image: "assets/man-head.png",
                scale: 1.2,
              );
            } else if (type == ProfileDummyType.image) {
              return ProfileDummy(
                color: HexColor.fromHex("9F69F9"),
                dummyType: ProfileDummyType.icon,
                scale: 1.0,
              );
            } else if (type == ProfileDummyType.button) {
              // Now using the OutlinedButtonWithText widget - fixing the unused import!
              return SizedBox(
                width:
                    screenWidth * 0.2, // Constrain the width for top navigation
                height:
                    screenHeight *
                    0.045, // Smaller height for navigation context
                child: OutlinedButtonWithText(
                  content: "Edit",
                  onPressed: () {
                    Get.to(() => EditProfilePage());
                  },
                ),
              );
            } else {
              return Container(
                width:
                    screenWidth *
                    0.2, // Maintain spacing balance even when empty
              );
            }
          },
        ),
      ],
    );
  }
}

/*
 * DefaultNav - Reusable Navigation Header Widget
 * 
 * Purpose: Provides a consistent top navigation bar across the entire app
 * 
 * Structure:
 * - Left: AppBackButton (back navigation)
 * - Center: Dynamic title text (responsive font size)
 * - Right: Customizable content based on 'type' parameter
 * 
 * Type Options:
 * - ProfileDummyType.icon: Shows profile image on right
 * - ProfileDummyType.image: Shows profile icon on right  
 * - ProfileDummyType.button: Shows "Edit" button on right
 * - null: Shows empty container for spacing balance
 * 
 * Common Use Cases:
 * - Profile screens: DefaultNav(title: "Profile", type: ProfileDummyType.icon)
 * - Settings screens: DefaultNav(title: "Settings", type: ProfileDummyType.button)
 * - Team screens: DefaultNav(title: "My Team", type: ProfileDummyType.image)
 * - Simple screens: DefaultNav(title: "About", type: null)
 * 
 * Features:
 * - Fully responsive design (adapts to all screen sizes)
 * - Consistent styling across the app
 * - Flexible right-side content
 * - Dynamic font sizing and spacing
 * - Maintains visual balance with proper
*/
