import 'package:flutter/material.dart';
import '../../values/values.dart';
import 'package:google_fonts/google_fonts.dart';

class RectPrimaryButtonWithIcon extends StatelessWidget {
  final String buttonText;
  final IconData? icon;
  final int itemIndex;
  final ValueNotifier<int> notifier;
  final VoidCallback? callback;
  const RectPrimaryButtonWithIcon({
    super.key,
    this.callback,
    this.icon,
    required this.notifier,
    required this.buttonText,
    required this.itemIndex,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: notifier,
      builder: (BuildContext context, _, __) {
        return ElevatedButton(
          onPressed: () {
            notifier.value = itemIndex;
            if (callback != null) {
              callback!();
            }
          },
          style: ButtonStyle(
            backgroundColor: notifier.value == itemIndex
                ? WidgetStateProperty.all<Color>(AppColors.primaryGreen)
                : WidgetStateProperty.all<Color>(AppColors.surface),
            shape: WidgetStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
                side: notifier.value == itemIndex
                    ? BorderSide(color: AppColors.primaryGreen)
                    : BorderSide(color: AppColors.surface),
              ),
            ),
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) Icon(icon!, color: AppColors.primaryText),
                Flexible(
                  child: Text(
                    "   $buttonText",
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      color: AppColors.primaryText,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
