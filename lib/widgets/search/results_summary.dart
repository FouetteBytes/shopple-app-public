import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopple/values/values.dart';

class ResultsSummary extends StatelessWidget {
  final bool isLoading;
  final int resultsCount;
  final String sortBy;
  final ValueChanged<String> onChangeSort;
  final VoidCallback onOpenFilter;

  const ResultsSummary({
    super.key,
    required this.isLoading,
    required this.resultsCount,
    required this.sortBy,
    required this.onChangeSort,
    required this.onOpenFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          isLoading ? 'Searching...' : '$resultsCount products found',
          style: GoogleFonts.lato(color: AppColors.primaryText70, fontSize: 14),
        ),
        if (!isLoading && resultsCount > 0)
          Row(
            children: [
              DropdownButton<String>(
                value: sortBy,
                dropdownColor: AppColors.surface,
                style: GoogleFonts.lato(color: AppColors.primaryText),
                underline: Container(),
                items: const [
                  DropdownMenuItem(
                    value: 'relevance',
                    child: Text('Relevance'),
                  ),
                  DropdownMenuItem(
                    value: 'price_low',
                    child: Text('Price: Low to High'),
                  ),
                  DropdownMenuItem(
                    value: 'price_high',
                    child: Text('Price: High to Low'),
                  ),
                  DropdownMenuItem(value: 'name', child: Text('Name A-Z')),
                  DropdownMenuItem(value: 'brand', child: Text('Brand A-Z')),
                ],
                onChanged: (value) {
                  if (value != null) onChangeSort(value);
                },
              ),
              const SizedBox(width: 6),
              IconButton(
                tooltip: 'Sort & Filter',
                icon: Icon(
                  Icons.tune_rounded,
                  color: AppColors.primaryAccentColor,
                ),
                onPressed: onOpenFilter,
              ),
            ],
          ),
      ],
    );
  }
}
