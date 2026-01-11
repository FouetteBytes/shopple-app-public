import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopple/values/values.dart';
import 'package:shopple/models/product_model.dart';

class QuickFiltersRow extends StatelessWidget {
  final List<ProductWithPrices> source;
  final ValueChanged<String> onFilterUnit;
  final ValueChanged<String> onFilterBrand;
  final VoidCallback onClear;
  final bool hasActiveFilter;
  final String? activeUnit;
  final String? activeBrand;

  const QuickFiltersRow({
    super.key,
    required this.source,
    required this.onFilterUnit,
    required this.onFilterBrand,
    required this.onClear,
    required this.hasActiveFilter,
    this.activeUnit,
    this.activeBrand,
  });

  @override
  Widget build(BuildContext context) {
    if (source.isEmpty) return const SizedBox.shrink();

    final brands = <String>{};
    final units = <String>{};
    for (final r in source.take(60)) {
      if (r.product.brandName.isNotEmpty) brands.add(r.product.brandName);
      if (r.product.sizeUnit.isNotEmpty) units.add(r.product.sizeUnit);
    }

    final chips = <Widget>[];

    if (hasActiveFilter) {
      chips.add(_clearButton(onClear));
    }

    for (final u in units.take(6)) {
      chips.add(
        _pillButton(
          context,
          label: 'Unit: $u',
          active: activeUnit != null && activeUnit == u,
          onTap: () => onFilterUnit(u),
        ),
      );
    }
    for (final b in brands.take(8)) {
      chips.add(
        _pillButton(
          context,
          label: b,
          active: activeBrand != null && activeBrand == b,
          onTap: () => onFilterBrand(b),
        ),
      );
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: chips
            .map(
              (w) =>
                  Padding(padding: const EdgeInsets.only(right: 8), child: w),
            )
            .toList(),
      ),
    );
  }

  Widget _pillButton(
    BuildContext context, {
    required String label,
    IconData? icon,
    required VoidCallback onTap,
    required bool active,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.primaryGreen : AppColors.surface,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: active ? AppColors.primaryGreen : AppColors.surface,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: AppColors.primaryText),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _clearButton(VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(32),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: AppColors.primaryText.withValues(alpha: 0.08),
          ),
        ),
        child: Icon(
          Icons.close_rounded,
          size: 16,
          color: AppColors.primaryText,
        ),
      ),
    );
  }
}
