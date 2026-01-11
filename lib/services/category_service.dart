import 'package:shopple/utils/app_logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Firebase Categories Service.
/// Handles all category-related operations with read-only access.
/// Based on DATABASE_DOCUMENTATION_FOR_MOBILE_DEVELOPERS.md.
class CategoryService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Complete category mappings from database documentation.
  /// Display Name -> Database ID mapping for all 36 categories.
  static const Map<String, String> categoryMappings = {
    // Food Categories (29 categories).
    "Rice & Grains": "rice_grains",
    "Lentils & Pulses": "lentils_pulses",
    "Spices & Seasonings": "spices_seasonings",
    "Coconut Products": "coconut_products",
    "Canned Food": "canned_food",
    "Snacks": "snacks",
    "Beverages": "beverages",
    "Dairy": "dairy",
    "Meat": "meat",
    "Seafood": "seafood",
    "Dried Seafood": "dried_seafood",
    "Frozen Food": "frozen_food",
    "Salt": "salt",
    "Sugar": "sugar",
    "Vegetables": "vegetables",
    "Fruits": "fruits",
    "Dried Fruits": "dried_fruits",
    "Bread & Bakery": "bread_bakery",
    "Noodles & Pasta": "noodles_pasta",
    "Instant Foods": "instant_foods",
    "Oil & Vinegar": "oil_vinegar",
    "Condiments & Sauces": "condiments_sauces",
    "Pickles & Preserves": "pickles_preserves",
    "Sweets & Desserts": "sweets_desserts",
    "Tea & Coffee": "tea_coffee",
    "Flour & Baking": "flour_baking",
    "Nuts & Seeds": "nuts_seeds",
    "Eggs": "eggs",
    "Baby Food": "baby_food",
    "Cereal": "cereal",
    // Non-Food Categories (6 categories).
    "Health & Supplements": "health_supplements",
    "Household Items": "household_items",
    "Paper Products": "paper_products",
    "Cleaning Supplies": "cleaning_supplies",
    "Personal Care": "personal_care",
    "Pet Food & Supplies": "pet_food_supplies",
  };

  /// Category icons for UI display.
  static const Map<String, String> categoryIcons = {
    "rice_grains": "🌾",
    "lentils_pulses": "🫘",
    "spices_seasonings": "🌶️",
    "coconut_products": "🥥",
    "canned_food": "🥫",
    "snacks": "🍿",
    "beverages": "🥤",
    "dairy": "🥛",
    "meat": "🥩",
    "seafood": "🐟",
    "dried_seafood": "🦐",
    "frozen_food": "🧊",
    "salt": "🧂",
    "sugar": "🍯",
    "vegetables": "🥬",
    "fruits": "🍎",
    "dried_fruits": "🍇",
    "bread_bakery": "🍞",
    "noodles_pasta": "🍝",
    "instant_foods": "🍜",
    "oil_vinegar": "🫒",
    "condiments_sauces": "🍅",
    "pickles_preserves": "🥒",
    "sweets_desserts": "🍰",
    "tea_coffee": "☕",
    "flour_baking": "🥞",
    "nuts_seeds": "🥜",
    "eggs": "🥚",
    "baby_food": "🍼",
    "cereal": "🥣",
    "health_supplements": "💊",
    "household_items": "🏠",
    "paper_products": "📄",
    "cleaning_supplies": "🧽",
    "personal_care": "🧴",
    "pet_food_supplies": "🐕",
  };

  /// Food vs Non-Food classification.
  static const Set<String> foodCategories = {
    "rice_grains",
    "lentils_pulses",
    "spices_seasonings",
    "coconut_products",
    "canned_food",
    "snacks",
    "beverages",
    "dairy",
    "meat",
    "seafood",
    "dried_seafood",
    "frozen_food",
    "salt",
    "sugar",
    "vegetables",
    "fruits",
    "dried_fruits",
    "bread_bakery",
    "noodles_pasta",
    "instant_foods",
    "oil_vinegar",
    "condiments_sauces",
    "pickles_preserves",
    "sweets_desserts",
    "tea_coffee",
    "flour_baking",
    "nuts_seeds",
    "eggs",
    "baby_food",
    "cereal",
  };

  static const Set<String> nonFoodCategories = {
    "health_supplements",
    "household_items",
    "paper_products",
    "cleaning_supplies",
    "personal_care",
    "pet_food_supplies",
  };

  /// Dart model for Categories (Based on Database Documentation).
  static Category fromFirestore(Map<String, dynamic> data, String id) {
    return Category(
      id: id,
      displayName: data['display_name'] ?? '',
      description: data['description'] ?? '',
      isFood: data['is_food'] ?? true,
      sortOrder: data['sort_order'] ?? 0,
      createdAt: data['created_at'] as Timestamp,
      updatedAt: data['updated_at'] as Timestamp,
    );
  }

  /// Get all categories ordered by sortOrder (READ-ONLY).
  static Future<List<Category>> getAllCategories() async {
    try {
      final querySnapshot = await _firestore
          .collection('categories')
          .orderBy('sort_order')
          .get();

      return querySnapshot.docs
          .map((doc) => fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      AppLogger.e('Error fetching categories', error: e);
      return [];
    }
  }

  /// Get only food categories (READ-ONLY).
  static Future<List<Category>> getFoodCategories() async {
    try {
      final querySnapshot = await _firestore
          .collection('categories')
          .where('is_food', isEqualTo: true)
          .orderBy('sort_order')
          .get();

      return querySnapshot.docs
          .map((doc) => fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      AppLogger.e('Error fetching food categories', error: e);
      return [];
    }
  }

  /// Get only non-food categories (READ-ONLY).
  static Future<List<Category>> getNonFoodCategories() async {
    try {
      final querySnapshot = await _firestore
          .collection('categories')
          .where('is_food', isEqualTo: false)
          .orderBy('sort_order')
          .get();

      return querySnapshot.docs
          .map((doc) => fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      AppLogger.e('Error fetching non-food categories', error: e);
      return [];
    }
  }

  /// Get specific category by ID (READ-ONLY).
  static Future<Category?> getCategory(String categoryId) async {
    try {
      final docSnapshot = await _firestore
          .collection('categories')
          .doc(categoryId)
          .get();

      if (docSnapshot.exists) {
        return fromFirestore(docSnapshot.data()!, docSnapshot.id);
      }
      return null;
    } catch (e) {
      AppLogger.e('Error fetching category $categoryId', error: e);
      return null;
    }
  }

  /// Validate that a category ID exists in the database.
  static Future<bool> validateCategoryExists(String categoryId) async {
    try {
      final docSnapshot = await _firestore
          .collection('categories')
          .doc(categoryId)
          .get();
      return docSnapshot.exists;
    } catch (e) {
      AppLogger.e('Error validating category $categoryId', error: e);
      return false;
    }
  }

  /// Get display name from category ID.
  static String getDisplayName(String categoryId) {
    // Reverse lookup in categoryMappings.
    for (var entry in categoryMappings.entries) {
      if (entry.value == categoryId) {
        return entry.key;
      }
    }
    return categoryId; // Fallback to ID if not found.
  }

  /// Get category ID from display name.
  static String getCategoryId(String displayName) {
    return categoryMappings[displayName] ??
        displayName.toLowerCase().replaceAll(' ', '_');
  }

  /// Get icon for category.
  static String getCategoryIcon(String categoryId) {
    return categoryIcons[categoryId] ?? '📦';
  }

  /// Check if category is food category.
  static bool isFoodCategory(String categoryId) {
    return foodCategories.contains(categoryId);
  }

  /// Check if category is non-food category.
  static bool isNonFoodCategory(String categoryId) {
    return nonFoodCategories.contains(categoryId);
  }

  /// Get all category IDs as list.
  static List<String> getAllCategoryIds() {
    return categoryMappings.values.toList();
  }

  /// Get all display names as list.
  static List<String> getAllDisplayNames() {
    return categoryMappings.keys.toList();
  }

  /// Get categories for dropdown/selection UI.
  static List<Map<String, String>> getCategoriesForUI({
    bool includeAll = true,
  }) {
    final categories = <Map<String, String>>[];

    if (includeAll) {
      categories.add({'id': 'all', 'name': 'All Products', 'icon': '🛒'});
    }

    for (var entry in categoryMappings.entries) {
      categories.add({
        'id': entry.value,
        'name': entry.key,
        'icon': getCategoryIcon(entry.value),
      });
    }

    return categories;
  }

  /// Get smart search suggestions for categories.
  static List<String> getSearchSuggestions(String query) {
    if (query.isEmpty) return [];

    final suggestions = <String>[];
    final lowercaseQuery = query.toLowerCase();

    // Search in display names.
    for (var displayName in categoryMappings.keys) {
      if (displayName.toLowerCase().contains(lowercaseQuery)) {
        suggestions.add(displayName);
      }
    }

    // Search in category IDs.
    for (var categoryId in categoryMappings.values) {
      if (categoryId.toLowerCase().contains(lowercaseQuery)) {
        suggestions.add(getDisplayName(categoryId));
      }
    }

    return suggestions.take(5).toList(); // Limit to 5 suggestions.
  }
}

/// Category data model based on Firebase Firestore structure.
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

  /// Convert to JSON for API calls.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'display_name': displayName,
      'description': description,
      'is_food': isFood,
      'sort_order': sortOrder,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  /// Get icon for this category.
  String get icon => CategoryService.getCategoryIcon(id);

  /// Check if this is a food category.
  bool get isFoodCategory => CategoryService.isFoodCategory(id);

  @override
  String toString() {
    return 'Category(id: $id, displayName: $displayName, isFood: $isFood, sortOrder: $sortOrder)';
  }
}
