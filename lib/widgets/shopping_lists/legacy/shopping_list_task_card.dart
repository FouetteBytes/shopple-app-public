import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../values/values.dart';
import '../../../models/shopping_lists/shopping_list_item_model.dart';

class ShoppingListTaskCard extends StatefulWidget {
  final ShoppingListItem item;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const ShoppingListTaskCard({
    super.key,
    required this.item,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<ShoppingListTaskCard> createState() => _ShoppingListTaskCardState();
}

class _ShoppingListTaskCardState extends State<ShoppingListTaskCard> {
  bool _active = true;

  @override
  void initState() {
    super.initState();
    _active = !widget.item.isCompleted;
  }

  void _flipVisual() => setState(() => _active = !_active);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        widget.onEdit();
      },
      onLongPress: _flipVisual,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _active
              ? AppColors.primaryBackgroundColor
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: _active
              ? null
              : Border.all(color: AppColors.primaryBackgroundColor, width: 3),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: widget.onToggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.item.isCompleted
                      ? AppColors.accentGreen
                      : Colors.black,
                  border: Border.all(color: AppColors.accentGreen, width: 2),
                ),
                child: widget.item.isCompleted
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
            ),
            AppSpaces.horizontalSpace20,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.lato(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: widget.item.isCompleted
                                ? AppColors.accentGreen
                                : AppColors.primaryText,
                            decoration: widget.item.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                      if (widget.item.totalPrice > 0)
                        Text(
                          'Rs ${widget.item.totalPrice.toStringAsFixed(0)}',
                          style: GoogleFonts.lato(
                            fontSize: 12,
                            color: HexColor.fromHex('EA9EEE'),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _chip(
                        '${widget.item.quantity} ${widget.item.unit}',
                        widget.item.isCompleted ? '8ECA84' : 'EA9EEE',
                      ),
                      if (widget.item.category.isNotEmpty)
                        _chip(widget.item.category, '94F0F1'),
                      if (widget.item.notes.isNotEmpty) _chip('note', 'FCA4FF'),
                    ],
                  ),
                  if (widget.item.notes.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      widget.item.notes,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.lato(
                        fontSize: 12,
                        color: HexColor.fromHex('626677'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            PopupMenuButton<String>(
              color: HexColor.fromHex('262A34'),
              icon: const Icon(Icons.more_horiz, color: Colors.white),
              onSelected: (val) {
                switch (val) {
                  case 'edit':
                    widget.onEdit();
                    break;
                  case 'toggle':
                    widget.onToggle();
                    break;
                  case 'delete':
                    widget.onDelete();
                    break;
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit Item')),
                PopupMenuItem(
                  value: 'toggle',
                  child: Text(
                    widget.item.isCompleted ? 'Mark Active' : 'Mark Completed',
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    'Delete',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String text, String hex) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: HexColor.fromHex(hex).withValues(alpha: .15),
      ),
      child: Text(
        text,
        style: GoogleFonts.lato(fontSize: 11, color: HexColor.fromHex(hex)),
      ),
    );
  }
}
