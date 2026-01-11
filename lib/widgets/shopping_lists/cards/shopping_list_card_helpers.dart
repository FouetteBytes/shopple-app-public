import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopple/values/values.dart';
import 'package:shopple/models/shopping_lists/shopping_list_model.dart';
import 'package:shopple/widgets/animated_diff_number.dart';
import 'package:shopple/services/shopping_lists/shopping_list_service.dart';

Widget buildChip(String label, Color color, {bool minimal = false}) => Container(
  padding: EdgeInsets.symmetric(
    horizontal: minimal ? 10 : 12,
    vertical: minimal ? 4 : 6,
  ),
  decoration: BoxDecoration(
    color: color.withValues(alpha: 0.12),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
  ),
  child: Text(
    label,
    style: GoogleFonts.lato(
      color: color,
      fontSize: minimal ? 10 : 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
    ),
  ),
);

Widget buildBudgetChip({
  required double estimate,
  required double budget,
  required Color accent,
  bool compact = false,
}) {
  final over = estimate > budget;
  final base = over ? Colors.redAccent : accent;
  final bg = over
      ? Colors.redAccent.withValues(alpha: .14)
      : base.withValues(alpha: .16);
  final border = over
      ? Colors.redAccent.withValues(alpha: .6)
      : base.withValues(alpha: .55);
  final textColor = over ? Colors.redAccent : Colors.white;
  final fontSize = compact ? 10.0 : 11.0;
  return Container(
    padding: EdgeInsets.symmetric(
      horizontal: compact ? 8 : 10,
      vertical: compact ? 4 : 6,
    ),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: border, width: 1),
      boxShadow: [
        BoxShadow(
          color: base.withValues(alpha: .18),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.payments_outlined,
          size: compact ? 12 : 14,
          color: textColor,
        ),
        const SizedBox(width: 6),
        // Use Flexible to allow the text to shrink when needed
        Flexible(
          child: FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Rs ',
                  style: GoogleFonts.lato(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
                AnimatedDiffNumber(
                  value: estimate,
                  style: GoogleFonts.lato(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
                Text(
                  ' / ${budget.toStringAsFixed(0)}',
                  style: GoogleFonts.lato(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

Widget buildModernChipRow(ShoppingList list, {bool compact = false}) {
  final chips = <Widget>[];

  if (compact) {
    // Minimal elegant chips for compact layout
    chips.add(
      buildChip(
        'Rs ${list.estimatedTotal.toStringAsFixed(0)}',
        HexColor.fromHex('3B82F6'),
        minimal: true,
      ),
    );
    if (list.budgetLimit > 0) {
      final left = (list.budgetLimit - list.estimatedTotal).clamp(
        0,
        list.budgetLimit,
      );
      final isOverBudget = list.estimatedTotal > list.budgetLimit;
      chips.add(
        buildChip(
          isOverBudget ? 'Over budget' : 'Rs ${left.toStringAsFixed(0)} left',
          isOverBudget
              ? HexColor.fromHex('EF4444')
              : HexColor.fromHex('10B981'),
          minimal: true,
        ),
      );
    }
  } else {
    // Full chips with better colors
    chips.add(
      buildChip(
        'Total: Rs ${list.estimatedTotal.toStringAsFixed(0)}',
        HexColor.fromHex('3B82F6'),
      ),
    );
    if (list.budgetLimit > 0) {
      chips.add(
        buildChip(
          'Budget: Rs ${list.budgetLimit.toStringAsFixed(0)}',
          HexColor.fromHex('8B5CF6'),
        ),
      );
      final left = (list.budgetLimit - list.estimatedTotal).clamp(
        0,
        list.budgetLimit,
      );
      final isOverBudget = list.estimatedTotal > list.budgetLimit;
      chips.add(
        buildChip(
          isOverBudget
              ? 'Over budget'
              : 'Rs ${left.toStringAsFixed(0)} remaining',
          isOverBudget
              ? HexColor.fromHex('EF4444')
              : HexColor.fromHex('10B981'),
        ),
      );
    }
  }

  return Wrap(
    spacing: compact ? 6 : 8,
    runSpacing: compact ? 4 : 6,
    children: chips,
  );
}

String timeAgo(DateTime? dateTime) {
  if (dateTime == null) return '';
  final diff = DateTime.now().difference(dateTime);
  if (diff.inDays > 0) return '${diff.inDays}d';
  if (diff.inHours > 0) return '${diff.inHours}h';
  if (diff.inMinutes > 0) return '${diff.inMinutes}m';
  return 'now';
}

IconData getIconFromId(String iconId) {
  // Map from create_shopping_list_sheet.dart icon options
  const iconMap = {
    'shopping_cart': Icons.shopping_cart,
    'local_grocery_store': Icons.local_grocery_store,
    'shopping_bag_outlined': Icons.shopping_bag_outlined,
    'storefront': Icons.storefront,
    'fastfood': Icons.fastfood,
    'local_pizza': Icons.local_pizza,
    'restaurant': Icons.restaurant,
    'egg': Icons.egg,
    'lunch_dining': Icons.lunch_dining,
    'rice_bowl': Icons.rice_bowl,
    'cookie_outlined': Icons.cookie_outlined,
    'cake_outlined': Icons.cake_outlined,
    'icecream': Icons.icecream,
    'coffee': Icons.coffee,
    'local_drink': Icons.local_drink,
    'set_meal': Icons.set_meal,
    'home_outlined': Icons.home_outlined,
    'chair_outlined': Icons.chair_outlined,
    'weekend': Icons.weekend,
    'kitchen': Icons.kitchen,
    'lightbulb_outline': Icons.lightbulb_outline,
    'inventory_2_outlined': Icons.inventory_2_outlined,
    'category_outlined': Icons.category_outlined,
    'devices_other': Icons.devices_other,
    'tv_outlined': Icons.tv_outlined,
    'phone_iphone': Icons.phone_iphone,
    'table_bar': Icons.table_bar,
    'bed_outlined': Icons.bed_outlined,
    'favorite_border': Icons.favorite_border,
    'health_and_safety_outlined': Icons.health_and_safety_outlined,
    'fitness_center': Icons.fitness_center,
    'medication_outlined': Icons.medication_outlined,
    'spa_outlined': Icons.spa_outlined,
    'pets': Icons.pets,
    'cruelty_free': Icons.cruelty_free,
    'baby_changing_station': Icons.baby_changing_station,
  };

  // Try parsing as IconData codePoint first (for dynamic icons)
  final code = int.tryParse(iconId);
  if (code != null) {
    try {
      return IconData(code, fontFamily: 'MaterialIcons');
    } catch (e) {
      // Fall back to default if invalid code
    }
  }

  return iconMap[iconId] ?? Icons.shopping_cart;
}

class StatusBadge extends StatelessWidget {
  final ShoppingList list;
  final String hex;
  const StatusBadge({super.key, required this.list, required this.hex});
  @override
  Widget build(BuildContext context) {
    final status = list.status;
    Color bg = HexColor.fromHex(hex);
    String text = 'Active';
    if (status == ListStatus.completed) {
      bg = Colors.green;
      text = 'Completed';
    } else if (status == ListStatus.archived) {
      bg = Colors.grey;
      text = 'Archived';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: GoogleFonts.lato(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}

class CompleteToggleButton extends StatefulWidget {
  final ShoppingList list;
  final bool compact; // show icon only when compact
  const CompleteToggleButton({super.key, required this.list, this.compact = false});
  @override
  State<CompleteToggleButton> createState() => _CompleteToggleButtonState();
}

class _CompleteToggleButtonState extends State<CompleteToggleButton> {
  bool _busy = false;
  Future<void> _toggle() async {
    if (_busy) return;
    setState(() => _busy = true);
    final list = widget.list;
    final newStatus = list.status == ListStatus.completed
        ? ListStatus.active
        : ListStatus.completed;
    await ShoppingListService.updateShoppingList(
      listId: list.id,
      status: newStatus,
    );
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = widget.list.status == ListStatus.completed;
    final accent = isCompleted
        ? Colors.greenAccent
        : HexColor.fromHex('3B82F6');
    final bg = isCompleted
        ? Colors.green.withValues(alpha: .18)
        : accent.withValues(alpha: .18);
    final label = isCompleted ? 'Completed' : 'Mark Done';
    final icon = isCompleted ? Icons.check_circle : Icons.check;
    final showLabel = !widget.compact;
    return Semantics(
      button: true,
      label: isCompleted ? 'Mark list active' : 'Mark list completed',
      child: InkWell(
        onTap: _toggle,
        borderRadius: BorderRadius.circular(30),
        splashColor: accent.withValues(alpha: .25),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: EdgeInsets.symmetric(
            horizontal: showLabel ? 12 : 8,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: accent.withValues(alpha: .55), width: 1),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: .25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: _busy
              ? SizedBox(
                  width: showLabel ? 18 : 16,
                  height: showLabel ? 18 : 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(accent),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: showLabel ? 16 : 18, color: accent),
                    if (showLabel) ...[
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: accent,
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}
