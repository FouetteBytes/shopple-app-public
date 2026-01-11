import 'package:flutter/material.dart';
import 'package:shopple/values/values.dart';
import 'package:shopple/widgets/common/liquid_text_field.dart';

class SearchHeader extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isLoading;
  final void Function(String) onChanged;
  final VoidCallback onCancel;
  final VoidCallback? onCameraTap;

  const SearchHeader({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isLoading,
    required this.onChanged,
    required this.onCancel,
    this.onCameraTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final bool compact = width < 360; // heuristic for very small screens
        const baseHint = 'Search products & brands...';
        final hint = compact
            ? baseHint.substring(0, baseHint.length < 18 ? baseHint.length : 18)
            : baseHint; // avoid RangeError
        return Row(
          children: [
            Expanded(
              child: LiquidTextField(
                controller: controller,
                focusNode: focusNode,
                onChanged: onChanged,
                hintText: hint,
                borderRadius: 16,
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Icon(
                    Icons.search_rounded,
                    color: AppColors.primaryAccentColor,
                    size: 20,
                  ),
                ),
                suffixIcon: isLoading
                    ? Padding(
                        padding: const EdgeInsets.all(14),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primaryAccentColor,
                            ),
                          ),
                        ),
                      )
                    : controller.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Colors.white70,
                              size: 18,
                            ),
                            onPressed: () {
                              controller.clear();
                              onChanged('');
                            },
                          )
                        : IconButton(
                            icon: const Icon(
                              Icons.camera_alt_outlined,
                              color: Colors.white70,
                              size: 20,
                            ),
                            onPressed: onCameraTap,
                          ),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onCancel,
                customBorder: const CircleBorder(),
                child: Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primaryText.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Icon(
                    Icons.arrow_downward_rounded,
                    size: 22,
                    color: AppColors.primaryAccentColor,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
