import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopple/values/values.dart';
import 'package:shopple/services/category_service.dart';

class ProductTypeSelector extends StatelessWidget {
  final List<Map<String, String>> productTypes;
  final String selectedId;
  final ValueChanged<String> onChanged;

  const ProductTypeSelector({
    super.key,
    required this.productTypes,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // If no explicit productTypes passed, pull from CategoryService (includes 'all').
    final List<Map<String, String>> types = productTypes.isNotEmpty
        ? productTypes
        : CategoryService.getCategoriesForUI(includeAll: true);

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: types.length,
        itemBuilder: (context, index) {
          final productType = types[index];
          final isSelected = selectedId == productType['id'];
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    productType['icon'] ?? '',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(
                      productType['name'] ?? '',
                      style: GoogleFonts.inter(
                        color: isSelected
                            ? AppColors.primaryAccentColor
                            : AppColors.primaryText70,
                        fontSize: 11,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              selected: isSelected,
              onSelected: (_) => onChanged(productType['id'] ?? ''),
              backgroundColor: AppColors.surface,
              selectedColor: AppColors.primaryAccentColor.withValues(
                alpha: 0.1,
              ),
              checkmarkColor: AppColors.primaryAccentColor,
              side: BorderSide(
                color: isSelected
                    ? AppColors.primaryAccentColor
                    : AppColors.inactive.withValues(alpha: 0.3),
                width: 1,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
          );
        },
      ),
    );
  }
}
