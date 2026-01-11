import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopple/values/values.dart';
import 'package:shopple/models/budget/budget_analytics_model.dart';
import 'package:shopple/widgets/budget/budget_format_utils.dart';

class FrequentPurchasesCard extends StatelessWidget {
  const FrequentPurchasesCard({super.key, required this.purchases});

  final List<FrequentPurchase> purchases;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryBackgroundColor,
        borderRadius: const BorderRadius.all(Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Frequent Purchases',
            style: GoogleFonts.lato(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            purchases.isEmpty
                ? 'Complete items to build a history.'
                : 'Your most common completed items',
            style: GoogleFonts.lato(
              fontSize: 13,
              color: AppColors.primaryText.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          if (purchases.isEmpty)
            _EmptyState()
          else
            Column(
              children: purchases.take(5).map((item) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withValues(alpha: 0.15),
                          borderRadius: const BorderRadius.all(
                            Radius.circular(12),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            item.occurrences.toString(),
                            style: GoogleFonts.lato(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.label,
                              style: GoogleFonts.lato(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryText,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Average ${formatCurrency(item.averageSpend)} • Total ${formatCurrency(item.totalSpend)}',
                              style: GoogleFonts.lato(
                                fontSize: 12,
                                color: AppColors.primaryText.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        border: Border.all(
          color: AppColors.primaryText.withValues(alpha: 0.08),
        ),
      ),
      child: Center(
        child: Text(
          'No completed purchases yet.',
          style: GoogleFonts.lato(
            color: AppColors.primaryText.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}
