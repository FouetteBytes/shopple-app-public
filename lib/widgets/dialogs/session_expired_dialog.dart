import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopple/values/values.dart';
import 'package:shopple/widgets/common/liquid_glass_button.dart';

class SessionExpiredDialog extends StatelessWidget {
  final VoidCallback onLoginAgain;
  final String reason;

  const SessionExpiredDialog({
    super.key,
    required this.onLoginAgain,
    required this.reason,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // prevent back button dismiss
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface, // Use existing app color
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF000000).withValues(alpha: 0.3),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 8),

              // Session expired icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_clock,
                  color: AppColors.primaryGreen,
                  size: 40,
                ),
              ),

              SizedBox(height: 24),

              // Title
              Text(
                "Session Expired",
                style: GoogleFonts.lato(
                  color: AppColors.primaryText,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 12),

              // Message
              Text(
                "Your session has expired for security reasons.",
                style: GoogleFonts.lato(
                  color: AppColors.primaryText,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 8),

              // Reason
              Text(
                "Reason: $reason",
                style: GoogleFonts.lato(
                  color: AppColors.inactive,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 32),

              // Login Again Button - Use existing app button style
              SizedBox(
                width: double.infinity,
                height: 50,
                child: LiquidGlassGradientButton(
                  onTap: onLoginAgain,
                  gradientColors: [AppColors.primaryGreen, AppColors.primaryGreen.withValues(alpha: 0.8)],
                  borderRadius: 25,
                  text: "Login Again",
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
