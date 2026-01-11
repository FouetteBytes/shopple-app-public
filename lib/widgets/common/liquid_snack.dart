import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shopple/widgets/common/liquid_glass.dart';
import 'package:shopple/values/values.dart';

class LiquidSnack {
  static void show({
    required String title,
    required String message,
    Color? accentColor,
    IconData? icon,
    int durationSeconds = 3,
    SnackPosition position = SnackPosition.TOP,
  }) {
    final color = accentColor ?? AppColors.primaryAccentColor;
    
    Get.showSnackbar(
      GetSnackBar(
        backgroundColor: Colors.transparent,
        snackPosition: position,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: EdgeInsets.zero, 
        borderRadius: 24,
        duration: Duration(seconds: durationSeconds),
        animationDuration: const Duration(milliseconds: 600),
        isDismissible: true,
        dismissDirection: DismissDirection.horizontal,

        titleText: Container(), 
        messageText: LiquidGlass(
          enableBlur: true,
          borderRadius: 20,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          gradientColors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.05),
          ],
          borderColor: color.withValues(alpha: 0.3),
          borderWidth: 1,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
          child: Row(
            children: [
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void success({required String title, required String message}) {
    show(
      title: title,
      message: message,
      accentColor: AppColors.primaryGreen, // Or a success green
      icon: Icons.check_circle_rounded,
    );
  }

  static void error({required String title, required String message}) {
    show(
      title: title,
      message: message,
      accentColor: AppColors.error,
      icon: Icons.error_rounded,
    );
  }
  
  static void info({required String title, required String message}) {
    show(
      title: title,
      message: message,
      accentColor: AppColors.primaryAccentColor,
      icon: Icons.info_rounded,
    );
  }
}
