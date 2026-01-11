import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shopple/bottom_sheets/bottom_sheets.dart';
import 'package:shopple/values/values.dart';
import 'package:shopple/widgets/onboarding/labelled_option.dart';

import '../../widgets/shopping_lists/create_shopping_list_sheet.dart';
import '../../widgets/product_request/product_request_sheet.dart';

class DashboardAddBottomSheet extends StatelessWidget {
  const DashboardAddBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    // Shrink-wrap column; _MaybeScrollable in showAppBottomSheet will allow scroll if needed.
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppSpaces.verticalSpace10,
        AppSpaces.verticalSpace10,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              LabelledOption(
                label: 'Create Shopping List',
                icon: Icons.shopping_cart,
                callback: _createShoppingList,
              ),
              LabelledOption(
                label: 'Add Item to List',
                icon: Icons.add_shopping_cart,
                callback: _addItem,
              ),
              LabelledOption(
                label: 'Request a Product',
                icon: Icons.inventory_2_outlined,
                callback: _requestProduct,
              ),
              LabelledOption(
                label: 'Scan Barcode',
                icon: Icons.qr_code_scanner,
                callback: _scanBarcode,
              ),
              LabelledOption(
                label: 'Price Comparison',
                icon: Icons.compare_arrows,
                callback: _priceComparison,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  void _createShoppingList() {
    showAppBottomSheet(
      const CreateShoppingListSheet(),
      title: 'Create Shopping List',
      isScrollControlled: true,
      popAndShow: true,
    );
  }

  void _addItem() {
    // TODO: Navigate to add item screen
    Get.back();
  }

  void _requestProduct() {
    showAppBottomSheet(
      const ProductRequestSheet(),
      isScrollControlled: true,
      popAndShow: true,
    );
  }

  void _scanBarcode() {
    // TODO: Navigate to barcode scanner
    Get.back();
  }

  void _priceComparison() {
    // TODO: Navigate to price comparison screen
    Get.back();
  }
}
