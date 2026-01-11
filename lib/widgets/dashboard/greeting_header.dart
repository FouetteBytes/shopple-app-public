import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopple/values/values.dart';

class GreetingHeader extends StatelessWidget {
  final String? name;
  const GreetingHeader({super.key, this.name});

  @override
  Widget build(BuildContext context) {
    final h = DateTime.now().hour;
    final greeting = h < 12
        ? 'Good Morning'
        : (h < 17 ? 'Good Afternoon' : 'Good Evening');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name != null && name!.isNotEmpty
              ? '$greeting, ${name!}!'
              : '$greeting!',
          style: GoogleFonts.poppins(
            color: AppColors.primaryText,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'What are you planning to buy today?',
          style: GoogleFonts.inter(
            color: AppColors.primaryText70,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
