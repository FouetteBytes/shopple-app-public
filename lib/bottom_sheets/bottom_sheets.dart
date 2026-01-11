import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopple/widgets/common/liquid_glass.dart';
import 'package:shopple/widgets/common/liquid_glass_button.dart';
import 'package:shopple/widgets/bottom_sheets/project_detail_sheet.dart';
import 'package:shopple/widgets/bottom_sheets/bottom_sheet_holder.dart';

class ShoppleBottomSheet {
  // static const MethodChannel _channel = MethodChannel('shoppleBottomSheet');
}

dynamic showSettingsBottomSheet() =>
    showAppBottomSheet(ProjectDetailBottomSheet());

Future showAppBottomSheet(
  Widget child, {
  String? title,
  bool isScrollControlled = false,
  bool popAndShow = false,
  double? height,
  double maxHeightFactor = 0.88,
  Duration duration = const Duration(milliseconds: 380),
  Curve curve = Curves.easeOutCubic,
  double blurSigma = 18,
}) async {
  if (popAndShow) Get.back();
  final context = Get.context!;
  return showModalBottomSheet(
    context: context,
    isScrollControlled: isScrollControlled,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (_) {
      return _AnimatedBlurSheet(
        title: title,
        duration: duration,
        curve: curve,
        blurSigma: blurSigma,
        maxHeightFactor: maxHeightFactor,
        child: height == null ? child : SizedBox(height: height, child: child),
      );
    },
  );
}

class _AnimatedBlurSheet extends StatefulWidget {
  final Widget child;
  final String? title;
  final Duration duration;
  final Curve curve;
  final double blurSigma;
  final double maxHeightFactor;
  const _AnimatedBlurSheet({
    required this.child,
    this.title,
    required this.duration,
    required this.curve,
    required this.blurSigma,
    required this.maxHeightFactor,
  });
  @override
  State<_AnimatedBlurSheet> createState() => _AnimatedBlurSheetState();
}

class _AnimatedBlurSheetState extends State<_AnimatedBlurSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _anim;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..forward();
    _anim = CurvedAnimation(parent: _controller, curve: widget.curve);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final bottomInset = media.viewInsets.bottom;
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final t = _anim.value;
        final slide = (1 - t) * 60; // slide up amount
        final radius = 30 * t; // animate curvature
        return Stack(
          children: [
            // Subtle backdrop blur above barrier color
            Positioned.fill(
              child: IgnorePointer(
                ignoring: true,
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: widget.blurSigma * t,
                    sigmaY: widget.blurSigma * t,
                  ),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Transform.translate(
                offset: Offset(0, slide + (bottomInset > 0 ? 0 : 0)),
                child: Opacity(
                  opacity: t,
                  child: SafeArea(
                    top: false,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        // Fixed height factor, not affected by keyboard
                        maxHeight: media.size.height * widget.maxHeightFactor,
                      ),
                      child: LiquidGlass(
                        borderRadius: radius,
                        enableBlur: true,
                        blurSigmaX: 10 * t + 2,
                        blurSigmaY: 20 * t + 4,
                        gradientColors: [
                          Colors.white.withValues(alpha: 0.07 * t),
                          Colors.white.withValues(alpha: 0.03 * t),
                        ],
                        borderColor: Colors.white.withValues(alpha: 0.10 * t),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.28 * t),
                            blurRadius: 28,
                            offset: const Offset(0, -6),
                          ),
                        ],
                        child: AnimatedPadding(
                          duration: const Duration(milliseconds: 260),
                          curve: Curves.easeOutCubic,
                          padding: EdgeInsets.only(bottom: bottomInset),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 8),
                              const BottomSheetHolder(),
                              if (widget.title != null)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          widget.title!,
                                          style: GoogleFonts.lato(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                            letterSpacing: -.2,
                                          ),
                                        ),
                                      ),
                                      LiquidGlassButton.icon(
                                        onTap: () => Navigator.of(context).pop(),
                                        icon: Icons.close,
                                        size: 32,
                                        iconSize: 18,
                                        accentColor: Colors.black,
                                        iconColor: Colors.white70,
                                      ),
                                    ],
                                  ),
                                ),
                              Flexible(
                                child: Stack(
                                  children: [
                                    _MaybeScrollable(child: widget.child),
                                    if (widget.title == null)
                                      Positioned(
                                        top: 12,
                                        right: 12,
                                        child: LiquidGlassButton.icon(
                                          onTap: () => Navigator.of(context).pop(),
                                          icon: Icons.close,
                                          size: 32,
                                          iconSize: 18,
                                          accentColor: Colors.black,
                                          iconColor: Colors.white70,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
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

/// Wraps child and adds SingleChildScrollView only if content wants more than available height.
class _MaybeScrollable extends StatelessWidget {
  final Widget child;
  const _MaybeScrollable({required this.child});
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use an IntrinsicHeight measurement attempt via Offstage to decide if scroll needed would be expensive.
        // Simpler: always wrap in SingleChildScrollView with primary physics but let inner ListView keep its own scroll.
        // If child already scrolls (ListView/CustomScrollView), return directly.
        if (child is ScrollView) return child;
        return SingleChildScrollView(
          padding: const EdgeInsets.only(top: 0),
          child: child,
        );
      },
    );
  }
}
