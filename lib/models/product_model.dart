import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final String originalName;
  final String brandName;
  final String category;
  final String variety;
  final int size;
  final String sizeRaw;
  final String sizeUnit;
  final String imageUrl;
  final bool isActive;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  Product({
    required this.id,
    required this.name,
    required this.originalName,
    required this.brandName,
    required this.category,
    required this.variety,
    required this.size,
    required this.sizeRaw,
    required this.sizeUnit,
    required this.imageUrl,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      name: data['name'] ?? '',
      originalName: data['original_name'] ?? '',
      brandName: data['brand_name'] ?? '',
      category: data['category'] ?? '',
      variety: data['variety'] ?? '',
      size: (data['size'] ?? 0).toInt(), // Fix: Convert to int
      sizeRaw: data['sizeRaw'] ?? '',
      sizeUnit: data['sizeUnit'] ?? '',
      imageUrl: data['image_url'] ?? '',
      isActive: data['is_active'] ?? false,
      createdAt: data['created_at'] ?? Timestamp.now(),
      updatedAt: data['updated_at'] ?? Timestamp.now(),
    );
  }

  factory Product.fromMap(Map<String, dynamic> data) {
    int toInt(dynamic v) {
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is String) {
        final i = int.tryParse(v);
        if (i != null) return i;
        final d = double.tryParse(v);
        if (d != null) return d.toInt();
      }
      return 0;
    }

    bool toBool(dynamic v, {bool defaultValue = true}) {
      if (v is bool) return v;
      if (v is int) return v != 0;
      if (v is String) {
        final s = v.toLowerCase();
        if (s == 'true' || s == '1' || s == 'yes') return true;
        if (s == 'false' || s == '0' || s == 'no') return false;
      }
      return defaultValue;
    }

    Timestamp toTimestamp(dynamic v) {
      if (v is Timestamp) return v;
      if (v is DateTime) return Timestamp.fromDate(v);
      // Firestore JSON from callable can be map-like
      if (v is Map) {
        // Possible shapes: {seconds: x, nanoseconds: y} or {_seconds: x, _nanoseconds: y}
        final seconds = v['seconds'] ?? v['_seconds'];
        final nanos = v['nanoseconds'] ?? v['_nanoseconds'] ?? 0;
        if (seconds is int) {
          return Timestamp(seconds, nanos is int ? nanos : 0);
        }
        // ISO string under 'iso' or 'toDate'
        final iso = v['iso'] ?? v['toDate'];
        if (iso is String) {
          final dt = DateTime.tryParse(iso);
          if (dt != null) return Timestamp.fromDate(dt);
        }
      }
      if (v is int) {
        // Heuristic: milliseconds if >= 1e12, else seconds
        if (v >= 1000000000000) {
          return Timestamp.fromMillisecondsSinceEpoch(v);
        }
        return Timestamp.fromMillisecondsSinceEpoch(v * 1000);
      }
      if (v is double) {
        final asInt = v.round();
        if (asInt >= 1000000000000) {
          return Timestamp.fromMillisecondsSinceEpoch(asInt);
        }
        return Timestamp.fromMillisecondsSinceEpoch(asInt * 1000);
      }
      if (v is String) {
        // Try parse ISO string
        final dt = DateTime.tryParse(v);
        if (dt != null) return Timestamp.fromDate(dt);
        // Try parse numeric string
        final i = int.tryParse(v);
        if (i != null) {
          if (i >= 1000000000000) {
            return Timestamp.fromMillisecondsSinceEpoch(i);
          }
          return Timestamp.fromMillisecondsSinceEpoch(i * 1000);
        }
      }
      return Timestamp.now();
    }

    return Product(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      originalName: data['original_name'] ?? '',
      brandName: data['brand_name'] ?? '',
      category: data['category'] ?? '',
      variety: data['variety'] ?? '',
      size: toInt(data['size'] ?? 0),
      sizeRaw: data['sizeRaw'] ?? '',
      sizeUnit: data['sizeUnit'] ?? '',
      imageUrl: data['image_url'] ?? '',
      isActive: toBool(data['is_active'], defaultValue: true),
      createdAt: toTimestamp(
        data['created_at'] ?? data['createdAt'] ?? Timestamp.now(),
      ),
      updatedAt: toTimestamp(
        data['updated_at'] ?? data['updatedAt'] ?? Timestamp.now(),
      ),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'original_name': originalName,
      'brand_name': brandName,
      'category': category,
      'variety': variety,
      'size': size,
      'sizeRaw': sizeRaw,
      'sizeUnit': sizeUnit,
      'image_url': imageUrl,
      'is_active': isActive,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

class Category {
  final String id;
  final String displayName;
  final String description;
  final bool isFood;
  final int sortOrder;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  Category({
    required this.id,
    required this.displayName,
    required this.description,
    required this.isFood,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Category.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Category(
      id: doc.id,
      displayName: data['display_name'] ?? '',
      description: data['description'] ?? '',
      isFood: data['is_food'] ?? false,
      sortOrder: data['sort_order'] ?? 0,
      createdAt: data['created_at'] ?? Timestamp.now(),
      updatedAt: data['updated_at'] ?? Timestamp.now(),
    );
  }
}

class CurrentPrice {
  final String id;
  final String supermarketId;
  final String productId;
  final double price;
  final String priceDate;
  final String lastUpdated;

  CurrentPrice({
    required this.id,
    required this.supermarketId,
    required this.productId,
    required this.price,
    required this.priceDate,
    required this.lastUpdated,
  });

  String get store {
    switch (supermarketId) {
      case 'keells':
        return 'Keells';
      case 'cargills':
        return 'Cargills';
      case 'arpico':
        return 'Arpico';
      default:
        return supermarketId;
    }
  }

  factory CurrentPrice.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CurrentPrice(
      id: doc.id,
      supermarketId: data['supermarketId'] ?? '',
      productId: data['productId'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      priceDate: data['priceDate'] ?? '',
      lastUpdated: data['lastUpdated'] ?? '',
    );
  }
}

class ProductWithPrices {
  final Product product;
  final Map<String, CurrentPrice> prices;

  ProductWithPrices({required this.product, required this.prices});

  CurrentPrice? getBestPrice() {
    if (prices.isEmpty) return null;
    return prices.values.reduce((a, b) => a.price < b.price ? a : b);
  }

  CurrentPrice? getWorstPrice() {
    if (prices.isEmpty) return null;
    return prices.values.reduce((a, b) => a.price > b.price ? a : b);
  }

  String getPriceComparison() {
    if (prices.length <= 1) return '';

    final bestPrice = getBestPrice();
    final worstPrice = getWorstPrice();

    if (bestPrice == null || worstPrice == null) return '';

    final difference = worstPrice.price - bestPrice.price;
    final percentSaving = (difference / worstPrice.price * 100).round();

    return 'Save Rs. ${difference.toStringAsFixed(2)} ($percentSaving%)';
  }

  List<CurrentPrice> getAllPrices() {
    return prices.values.toList()..sort((a, b) => a.price.compareTo(b.price));
  }

  List<String> getAvailableStores() {
    return prices.keys.toList();
  }

  bool isAvailableAt(String supermarketId) {
    return prices.containsKey(supermarketId);
  }

  String getStoreDisplayName(String supermarketId) {
    switch (supermarketId) {
      case 'keells':
        return 'Keells Super';
      case 'cargills':
        return 'Cargills Food City';
      case 'arpico':
        return 'Arpico Supercenter';
      default:
        return supermarketId;
    }
  }
}
