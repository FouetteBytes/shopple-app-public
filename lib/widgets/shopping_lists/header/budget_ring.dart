import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Compact circular budget indicator used in the shopping list header.
class BudgetRing extends StatelessWidget {
  final double current;
  final double limit;
  final Color color;

  const BudgetRing({
    super.key,
    required this.current,
    required this.limit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = limit <= 0
        ? 0.0
        : (current / limit).clamp(0.0, 2.0); // allow over 100%
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0, end: pct),
      builder: (context, animatedPct, _) {
        return SizedBox(
          width: 48,
          height: 48,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                strokeWidth: 4,
                value: animatedPct > 1 ? 1 : animatedPct,
                backgroundColor: Colors.white.withValues(alpha: .08),
                valueColor: AlwaysStoppedAnimation<Color>(
                  animatedPct > 1 ? Colors.redAccent : color,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(animatedPct * 100).clamp(0, 200).toStringAsFixed(0)}%',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'budget',
                    style: GoogleFonts.poppins(
                      fontSize: 8,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
