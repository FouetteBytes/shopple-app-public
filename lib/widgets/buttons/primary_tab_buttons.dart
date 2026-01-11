import 'package:flutter/material.dart';
import '../../values/values.dart';
import 'package:google_fonts/google_fonts.dart';

class PrimaryTabButton extends StatelessWidget {
  final String buttonText;
  final int itemIndex;
  final ValueNotifier<int> notifier;
  final VoidCallback? callback;
  const PrimaryTabButton({
    super.key,
    this.callback,
    required this.notifier,
    required this.buttonText,
    required this.itemIndex,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 5),
      child: ValueListenableBuilder(
        valueListenable: notifier,
        builder: (BuildContext context, _, __) {
          return ElevatedButton(
            onPressed: () {
              notifier.value = itemIndex;
              if (callback != null) {
                callback!();
              }
            },
            style:
                theme.elevatedButtonTheme.style?.copyWith(
                  minimumSize: WidgetStateProperty.all(const Size(0, 40)),
                  padding: WidgetStateProperty.all(
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                  backgroundColor: notifier.value == itemIndex
                      ? null // use themed primary when active
                      : WidgetStateProperty.all<Color>(AppColors.surface),
                ) ??
                ButtonStyle(
                  minimumSize: WidgetStateProperty.all(const Size(0, 40)),
                  padding: WidgetStateProperty.all(
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                  backgroundColor: WidgetStateProperty.all<Color>(
                    notifier.value == itemIndex
                        ? theme.colorScheme.primary
                        : AppColors.surface,
                  ),
                ),
            child: Text(
              buttonText,
              style:
                  theme.textTheme.labelLarge ??
                  GoogleFonts.lato(fontSize: 16, color: AppColors.primaryText),
            ),
          );
        },
      ),
    );
  }
}
