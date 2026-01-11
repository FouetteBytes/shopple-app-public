import 'package:flutter/material.dart';
import 'package:shopple/values/values.dart';
import 'package:shopple/models/product_request_model.dart';

extension RequestTypeColor on RequestType {
  Color get color {
    switch (this) {
      case RequestType.newProduct:
        return AppColors.primaryGreen;
      case RequestType.updateProduct:
        return Colors.blueAccent;
      case RequestType.reportError:
        return Colors.orangeAccent;
      case RequestType.priceUpdate:
        return Colors.purpleAccent;
    }
  }
}
