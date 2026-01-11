import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// A glassmorphic text field with liquid glass styling.
/// Reusable across the app for consistent text input styling.
class LiquidTextField extends StatelessWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hintText;
  final int minLines;
  final int? maxLines;
  final bool readOnly;
  final bool enabled;
  final bool enableBlur;
  final double borderRadius;
  final Color? accentColor;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onEditingComplete;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final String? prefixText;
  final String? suffixText;
  final EdgeInsetsGeometry? contentPadding;
  final bool autofocus;
  final bool obscureText;
  final List<TextInputFormatter>? inputFormatters;
  final FormFieldValidator<String>? validator;

  const LiquidTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.hintText,
    this.minLines = 1,
    this.maxLines = 1,
    this.readOnly = false,
    this.enabled = true,
    this.enableBlur = true,
    this.borderRadius = 20,
    this.accentColor,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.onEditingComplete,
    this.suffixIcon,
    this.prefixIcon,
    this.prefixText,
    this.suffixText,
    this.contentPadding,
    this.autofocus = false,
    this.obscureText = false,
    this.inputFormatters,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? Colors.white;
    final gradientColors = [
      accent.withValues(alpha: 0.12),
      accent.withValues(alpha: 0.06),
    ];
    final borderColor = accent.withValues(alpha: 0.15);
    final disabledColor = accent.withValues(alpha: 0.05);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Stack(
        children: [
          // Blur effect (optional)
          if (enableBlur)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: const SizedBox.expand(),
              ),
            ),
          // Glass container
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: enabled ? gradientColors : [disabledColor, disabledColor],
              ),
              border: Border.all(
                color: borderColor,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: TextFormField(
                controller: controller,
                focusNode: focusNode,
                minLines: minLines,
                maxLines: maxLines,
                readOnly: readOnly,
                enabled: enabled,
                autofocus: autofocus,
                obscureText: obscureText,
                keyboardType: keyboardType,
                textInputAction: textInputAction,
                inputFormatters: inputFormatters,
                onChanged: onChanged,
                onFieldSubmitted: onSubmitted,
                onEditingComplete: onEditingComplete,
                validator: validator,
                style: GoogleFonts.lato(
                  color: Colors.white,
                  fontSize: 14,
                ),
                cursorColor: accent,
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: GoogleFonts.lato(
                    color: Colors.white54,
                    fontSize: 14,
                  ),
                  filled: false, // We use the gradient container instead
                  contentPadding: contentPadding ?? 
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  suffixIcon: suffixIcon,
                  prefixIcon: prefixIcon,
                  prefixText: prefixText,
                  suffixText: suffixText,
                  prefixStyle: GoogleFonts.lato(color: Colors.white70, fontSize: 14),
                  suffixStyle: GoogleFonts.lato(color: Colors.white70, fontSize: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A variant for multi-line input that expands upwards.
/// Useful for chat-style inputs at the bottom of the screen.
class LiquidExpandingTextField extends StatelessWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hintText;
  final int minLines;
  final int maxLines;
  final bool readOnly;
  final bool enabled;
  final double borderRadius;
  final Color? accentColor;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffixIcon;
  final Widget? prefixIcon;

  const LiquidExpandingTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.hintText,
    this.minLines = 1,
    this.maxLines = 6,
    this.readOnly = false,
    this.enabled = true,
    this.borderRadius = 24,
    this.accentColor,
    this.onChanged,
    this.onSubmitted,
    this.suffixIcon,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? Colors.white;
    final gradientColors = [
      accent.withValues(alpha: 0.10),
      accent.withValues(alpha: 0.05),
    ];
    final borderColor = accent.withValues(alpha: 0.12);
    final disabledBorderColor = accent.withValues(alpha: 0.06);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
            border: Border.all(
              color: enabled ? borderColor : disabledBorderColor,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            minLines: minLines,
            maxLines: maxLines,
            readOnly: readOnly,
            enabled: enabled,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            style: GoogleFonts.lato(
              color: Colors.white,
              fontSize: 14,
            ),
            cursorColor: accent,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: GoogleFonts.lato(
                color: Colors.white54,
                fontSize: 14,
              ),
              filled: false,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 14,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              suffixIcon: suffixIcon,
              prefixIcon: prefixIcon,
            ),
          ),
        ),
      ),
    );
  }
}
