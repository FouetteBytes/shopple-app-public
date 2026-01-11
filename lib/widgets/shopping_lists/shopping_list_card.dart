import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../values/values.dart';
import '../../models/shopping_lists/shopping_list_model.dart';

class ShoppingListCard extends StatelessWidget {
  final ShoppingList shoppingList;
  final bool isGridView;
  final VoidCallback? onTap;

  const ShoppingListCard({
    super.key,
    required this.shoppingList,
    this.isGridView = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: shoppingList.themeColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: isGridView ? _buildGridLayout() : _buildListLayout(),
      ),
    );
  }

  Widget _buildGridLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [_buildIcon(), _buildMoreButton()],
        ),
        SizedBox(height: 12),
        _buildTitle(),
        SizedBox(height: 8),
        _buildStats(),
        SizedBox(height: 12),
        _buildProgressBar(),
        SizedBox(height: 8),
        _buildFooter(),
      ],
    );
  }

  Widget _buildListLayout() {
    return Row(
      children: [
        _buildIcon(),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: _buildTitle()),
                  _buildMoreButton(),
                ],
              ),
              SizedBox(height: 8),
              _buildStats(),
              SizedBox(height: 8),
              _buildProgressBar(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIcon() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: shoppingList.themeColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        _getIconData(shoppingList.iconId),
        color: shoppingList.themeColor,
        size: 24,
      ),
    );
  }

  Widget _buildMoreButton() {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.all(4),
        child: Icon(Icons.more_vert, color: Colors.grey[400], size: 20),
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          shoppingList.name,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (shoppingList.description.isNotEmpty) ...[
          SizedBox(height: 4),
          Text(
            shoppingList.description,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[400]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _buildStats() {
    // Smart display logic: show distinct product count by default,
    // but show both counts when there are products with quantity > 1
    final bool hasMultipleQuantities =
        shoppingList.totalItems > shoppingList.distinctProducts;

    return Row(
      children: [
        Icon(Icons.check_circle_outline, size: 14, color: Colors.grey[400]),
        SizedBox(width: 4),
        if (hasMultipleQuantities) ...[
          // Show both counts in a compact, modern way
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${shoppingList.distinctCompleted}/${shoppingList.distinctProducts}',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey[300],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 4),
                Container(width: 1, height: 10, color: Colors.grey[600]),
                SizedBox(width: 4),
                Text(
                  '${shoppingList.completedItems}/${shoppingList.totalItems}',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey[400],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          // Show only product count when all quantities are 1
          Text(
            '${shoppingList.distinctCompleted}/${shoppingList.distinctProducts}',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[400],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        if (shoppingList.budgetLimit > 0) ...[
          SizedBox(width: 16),
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 14,
            color: Colors.grey[400],
          ),
          SizedBox(width: 4),
          Text(
            'Rs ${shoppingList.estimatedTotal.toStringAsFixed(0)}',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: shoppingList.estimatedTotal > shoppingList.budgetLimit
                  ? Colors.red
                  : Colors.grey[400]!,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProgressBar() {
    final progress = shoppingList.completionPercentage / 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500]),
            ),
            Text(
              '${shoppingList.completionPercentage.toStringAsFixed(0)}%',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.grey[400],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[800],
          valueColor: AlwaysStoppedAnimation<Color>(
            progress == 1.0 ? Colors.green : shoppingList.themeColor,
          ),
          minHeight: 4,
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          _getTimeAgo(shoppingList.lastActivity),
          style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[500]),
        ),
        _buildStatusChip(),
      ],
    );
  }

  Widget _buildStatusChip() {
    Color chipColor = shoppingList.themeColor;
    String chipText = 'Active';

    switch (shoppingList.status) {
      case ListStatus.completed:
        chipColor = Colors.green;
        chipText = 'Completed';
        break;
      case ListStatus.archived:
        chipColor = Colors.grey;
        chipText = 'Archived';
        break;
      case ListStatus.active:
        // chipText remains 'Active' as initialized above
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        chipText,
        style: GoogleFonts.poppins(
          fontSize: 9,
          color: chipColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  IconData _getIconData(String iconId) {
    const iconMap = {
      'shopping_cart': Icons.shopping_cart,
      'local_grocery_store': Icons.local_grocery_store,
      'restaurant': Icons.restaurant,
      'local_pharmacy': Icons.local_pharmacy,
      'pets': Icons.pets,
      'build': Icons.build,
      'home': Icons.home,
      'work': Icons.work,
    };

    return iconMap[iconId] ?? Icons.shopping_cart;
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
