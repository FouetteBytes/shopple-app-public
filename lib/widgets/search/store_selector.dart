import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopple/values/values.dart';

class StoreSelector extends StatelessWidget {
  final Set<String> selectedStores;
  final ValueChanged<String> onToggle;
  final List<Map<String, String>> stores;

  const StoreSelector({
    super.key,
    required this.selectedStores,
    required this.onToggle,
    this.stores = const [
      {'id': 'cargills', 'name': 'Cargills'},
      {'id': 'keells', 'name': 'Keells'},
    ],
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: stores.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final s = stores[index];
          final selected = selectedStores.contains(s['id']);
          return InkWell(
            onTap: () => onToggle(s['id']!),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected
                      ? AppColors.primaryAccentColor.withValues(alpha: 0.5)
                      : AppColors.primaryText.withValues(alpha: 0.08),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    selected ? Icons.check_circle : Icons.circle_outlined,
                    size: 14,
                    color: selected
                        ? AppColors.primaryAccentColor
                        : AppColors.primaryText70,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    s['name']!,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: selected
                          ? AppColors.primaryAccentColor
                          : AppColors.primaryText70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
