import 'package:flutter/material.dart';
import '../../values/values.dart';
import 'package:google_fonts/google_fonts.dart';

// ignore: must_be_immutable
class ProfileTextOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final double? margin;
  final VoidCallback? onTap;
  final Widget? trailing;

  const ProfileTextOption({
    super.key,
    required this.label,
    required this.icon,
    this.margin,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF262A34),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                vertical: margin ?? 10.0,
              ), // 8.0 as default margin.
              child: ListTile(
                title: Row(
                  children: [
                    Icon(icon, color: AppColors.primaryText, size: 24),
                    Text(
                      label,
                      style: GoogleFonts.lato(
                        fontSize: 18,
                        color: AppColors.primaryText,
                      ),
                    ),
                  ],
                ),
                trailing: trailing ?? (onTap != null 
                    ? Icon(
                        Icons.chevron_right,
                        color: AppColors.inactive,
                      )
                    : SizedBox()),
              ),
            ),
            Divider(height: 1, color: HexColor.fromHex("353742")),
            // Divider(height: 1, color: HexColor.fromHex("616575"))
          ],
        ),
      ),
    );
  }
}
