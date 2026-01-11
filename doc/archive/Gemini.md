# GitHub Copilot: Project Context for "Shopple" (Template Adaptation)

Hello Copilot! You are my expert Flutter development assistant for the "Shopple" project.

**My Goal:** I am adapting a standard Flutter template. Your main job is to help me **replace the template's placeholder content and styling** with the specific features, colors, and text of the "Shopple" app. **Do not suggest changing the existing project file structure.** We will modify the existing screens.

## 1. Core Project Identity

*   **App Name:** Shopple
*   **Tagline:** Personal Shopping & Lifestyle Assistant App
*   **Core Mission:** To solve key pain points for Sri Lankan consumers, including lack of price transparency, expense tracking, and inefficient shopping list management.

## 2. Instructions for You, GitHub Copilot

1.  **Strictly Adhere to the Design System:** This is the top priority. All generated UI code **must** use the `AppColors` and `AppTextStyles` classes defined below. When I ask you to "style this button," use these definitions.
2.  **Focus on Transformation, Not Creation:** Your main task is to replace placeholder content. If you see a generic `ListView` of "Items", you should adapt it to display `ShoppingList` objects using the defined `ShoppingListCard` widget.
3.  **Use the Provided Data Models:** When we need to display data, use the data models defined in Section 5. Assume these models are available throughout the app.
4.  **State Management:** When state management is needed for a screen (like updating a list), please use **Riverpod**. Generate the necessary `Providers` and wrap widgets with `Consumer` or use `ConsumerWidget`.

---

## 3. Design System & UI Kit (The "Shopple" Look)

This is the visual identity we need to apply to the template.

### 3.1. Color Palette

I will create a file at `lib/theme/app_colors.dart` (or similar). Please use this class for all color references.

```dart
// lib/theme/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryGreen = Color(0xFF33FF99); // The main vibrant green for buttons, FABs, active indicators
  static const Color accentGreen = Color(0xFFBFFFB3); // Lighter green for highlights (e.g., budget box background)
  static const Color background = Color(0xFF000000); // Pure black background for Scaffolds
  static const Color surface = Color(0xFF1C1C1E); // Off-black for Cards, Dialogs, BottomSheet backgrounds
  static const Color darkGreenBackground = Color(0xFF1A4331); // Dark green for specific sections or backgrounds
  static const Color primaryText = Color(0xFFFFFFFF); // White for primary text (headings, important info)
  static const Color secondaryText = Color(0xFFEBEBF5); // Slightly off-white for secondary info, subtitles
  static const Color error = Color(0xFFFF453A); // For error messages
  static const Color inactive = Color(0xFF8E8E93); // For disabled elements, placeholder text, inactive icons
}
```

### 3.2. Typography

We will use the **Poppins** font (you can help me add it from `google_fonts`). Create a file `lib/theme/app_text_styles.dart`.

```dart
// lib/theme/app_text_styles.dart
import 'package.flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart'; // Make sure this path is correct

class AppTextStyles {
  static TextStyle heading1 = GoogleFonts.poppins(
    fontSize: 48,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryText,
  );

  static TextStyle heading2 = GoogleFonts.poppins(
    fontSize: 34,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryText,
  );

  static TextStyle bodyL = GoogleFonts.poppins(
    fontSize: 17,
    fontWeight: FontWeight.normal,
    color: AppColors.primaryText,
  );
  
  static TextStyle bodyM = GoogleFonts.poppins(
    fontSize: 15,
    fontWeight: FontWeight.normal,
    color: AppColors.secondaryText,
  );

  static TextStyle button = GoogleFonts.poppins(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: AppColors.background, // Black text on green button
  );
}
```

---

Here is a brief, high-level explanation of the Shopple app and its features, formatted in markdown. 

# Shopple App: Core Concept & Features

## Project Vision
Shopple is a mobile app designed to revolutionize the grocery shopping experience for consumers in **Sri Lanka**. It acts as a smart shopping assistant that helps users save money, stay on budget, and collaborate with their household.

## The Core Problem
Sri Lankan consumers currently face several challenges:
*   **Price Opacity:** It's difficult to know which supermarket (e.g., Keells, Cargills, Arpico) has the best price for a specific item without visiting them all.
*   **Budget Overruns:** Shoppers often lose track of their total cart value while in the store, leading to overspending.
*   **Inefficient Collaboration:** Sharing paper lists or text messages within a family is clumsy and often results in missed items or duplicate purchases.

## Key Features & Functionality

The app solves these problems with the following core features:

### 1. Centralized Price Comparison
*   The app maintains its own **daily-updated price database** for major Sri Lankan supermarket chains.
*   Users can see and compare the prices of products across different stores before or during their shopping trip.
*   This data is acquired through independent web scraping, not relying on official store APIs.

### 2. Budget-Conscious Shopping
*   Users can set a **budget** for each shopping list.
*   As items are added to the list, the app provides **real-time expense tracking**, showing the current total.
*   The app will **alert users** when they are approaching or have exceeded their set budget, preventing overspending.

### 3. Seamless Collaboration
*   Shopping lists can be **shared with family members** or household members.
*   The lists feature **real-time synchronization**, so when one person checks an item off, it updates for everyone instantly.
*   This helps coordinate shopping trips and prevent duplicate purchases.

### 4. Simplified Product Management
*   The app makes adding items to a list easy and intuitive through multiple methods:
    *   **AI-powered Camera Detection:** Point the camera at a product, and the app will identify it and add it to the list.
    *   **Barcode Scanning:** A quick and accurate way to add specific items.
    *   **Voice-activated List Creation:** Simply speak the items you want to add.
    *   **Manual Search & Add:** Traditional text-based search.


    # 📱 Database Documentation for Mobile App Developers

## � IMPORTANT: READ-ONLY ACCESS ONLY

**⚠️ CRITICAL NOTICE FOR MOBILE DEVELOPERS:**
- **📖 READ-ONLY**: Your mobile app can only **READ** data from the database
- **🚫 NO WRITES**: You cannot create, update, or delete any records
- **🔄 AUTOMATIC UPDATES**: All price data is automatically updated by backend crawlers
- **🛡️ SECURITY**: This ensures data integrity and prevents unauthorized modifications

## �📋 Overview

This document provides comprehensive information about the Firebase Firestore database structure for the **Sri Lankan Supermarket Price Comparison Application**. The database is designed for optimal performance, cost efficiency, and real-time price tracking across multiple supermarket chains.

### 🎯 Application Purpose
- **Real-time price comparison** across Keells, Cargills, and Arpico supermarkets
- **Historical price tracking** and trend analysis
- **AI-powered product classification** and categorization
- **Mobile-first design** for Flutter applications with read-only access

---

## 🗄️ Database Architecture

The database consists of **4 interconnected Firebase Firestore collections**:

```
📁 categories (Foundation)
    ↓ References
📁 products 
    ↓ References  
📁 current_prices    📁 price_history_monthly
```

### 🔗 Relationship Summary:
- **Categories → Products:** One-to-Many (each product belongs to one category)
- **Products → Current Prices:** One-to-Many (each product has prices across multiple stores)
- **Products → Price History:** One-to-Many (each product has historical data)
- **Current Prices ↔ Price History:** Related (history tracks price changes)

---

## 📊 COLLECTION 1: CATEGORIES

### **Collection Name:** `categories`

### **Purpose:** 
Master catalog of all 33 product categories used for organization and filtering. This is the foundation collection that all products reference.

### **Document ID Format:**
Normalized category names (lowercase, underscore-separated)
- `fruits`
- `vegetables` 
- `rice_grains`
- `dairy_products`
- `meat_seafood`
- `household_items`

### **Document Structure:**
```dart
// Dart model for Categories (Based on Actual Database)
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
}
```

### **Actual Document Structure (From Firebase):**
```javascript
// Document ID: baby_food
{
  "created_at": "July 10, 2025 at 11:22:45 AM UTC+5:30",  // Timestamp
  "description": "Infant formula, baby cereals, baby food, and child nutrition products",  // String
  "display_name": "Baby Food",  // String
  "id": "baby_food",  // String
  "is_food": true,  // Boolean
  "sort_order": 29,  // Number
  "updated_at": "July 10, 2025 at 11:22:45 AM UTC+5:30"  // Timestamp
}
```

### **Field Descriptions:**
- **`id`** (String): Unique identifier, lowercase with underscores (`baby_food`, `meat`, `dairy`)
- **`display_name`** (String): Human-readable category name ("Baby Food", "Fresh Meat")
- **`description`** (String): Detailed description of what products belong to this category
- **`is_food`** (Boolean): Whether this category contains food items (true/false)
- **`sort_order`** (Number): Display order for UI sorting (1-33)
- **`created_at`** (Timestamp): When the category was created
- **`updated_at`** (Timestamp): When the category was last modified

### **Flutter Queries for Categories:**

#### **Get All Categories (Sorted)**
```dart
// Get all categories ordered by sortOrder
Future<List<Category>> getAllCategories() async {
  final querySnapshot = await FirebaseFirestore.instance
      .collection('categories')
      .orderBy('sortOrder')
      .get();
  
  return querySnapshot.docs
      .map((doc) => Category.fromFirestore(doc.data(), doc.id))
      .toList();
}
```

#### **Get Food Categories Only**
```dart
// Get only food categories
Future<List<Category>> getFoodCategories() async {
  final querySnapshot = await FirebaseFirestore.instance
      .collection('categories')
      .where('isFood', isEqualTo: true)
      .orderBy('sortOrder')
      .get();
  
  return querySnapshot.docs
      .map((doc) => Category.fromFirestore(doc.data(), doc.id))
      .toList();
}
```

#### **Get Single Category**
```dart
// Get specific category by ID
Future<Category?> getCategory(String categoryId) async {
  final docSnapshot = await FirebaseFirestore.instance
      .collection('categories')
      .doc(categoryId)
      .get();
  
  if (docSnapshot.exists) {
    return Category.fromFirestore(docSnapshot.data()!, docSnapshot.id);
  }
  return null;
}
```

---

## 🛒 COLLECTION 2: PRODUCTS

### **Collection Name:** `products`

### **Purpose:** 
Master product catalog containing all unique products with their classification details, brand information, and category references.

### **Document ID Format:**
Smart algorithm-generated IDs using pattern: `{brand}_{productname}_{size}`
- `bairaha_bairahachickensausages_500g`
- `anchor_milk_1l`
- `sunlight_dishwash_500ml`

### **Document Structure:**
```dart
// Dart model for Products (Based on Actual Database)
class Product {
  final String id;
  final String name;
  final String originalName;
  final String brandName;
  final String category;  // References categories collection
  final int size;
  final String sizeRaw;
  final String sizeUnit;
  final String variety;
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
    required this.size,
    required this.sizeRaw,
    required this.sizeUnit,
    required this.variety,
    required this.imageUrl,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });
}
```

### **Actual Document Structure (From Firebase):**
```javascript
// Document ID: bairaha_bairahachickensausages_500g
{
  "brand_name": "Bairaha",  // String
  "category": "meat",  // String - References categories collection
  "created_at": "July 12, 2025 at 11:53:27 PM UTC+5:30",  // Timestamp
  "id": "bairaha_bairahachickensausages_500g",  // String
  "image_url": "https://cargillsonline.com/VendorItems/MenuItems/FF31803_1.jpg",  // String
  "is_active": true,  // Boolean
  "name": "Bairaha Chicken Sausages",  // String
  "original_name": "Bairaha Chicken Sausages - 500 g",  // String
  "size": 500,  // Number
  "sizeRaw": "500g",  // String
  "sizeUnit": "g",  // String
  "updated_at": "July 12, 2025 at 11:53:27 PM UTC+5:30",  // Timestamp
  "variety": "Chicken Sausages"  // String
}
```

### **Field Descriptions:**
- **`id`** (String): Unique identifier generated as `{brand}_{productname}_{size}`
- **`name`** (String): Clean product name ("Bairaha Chicken Sausages")
- **`original_name`** (String): Original scraped name ("Bairaha Chicken Sausages - 500 g")
- **`brand_name`** (String): Product brand ("Bairaha", "Anchor", "Sunlight")
- **`category`** (String): **CRITICAL REFERENCE** - Must match a document ID in `categories` collection
- **`size`** (Number): Numeric size value (500, 1, 250)
- **`sizeRaw`** (String): Original size text ("500g", "1L", "250ml")
- **`sizeUnit`** (String): Unit of measurement ("g", "L", "ml", "kg")
- **`variety`** (String): Product variant/flavor ("Chicken Sausages", "Full Cream")
- **`image_url`** (String): Product image URL from supermarket website
- **`is_active`** (Boolean): Whether product is currently available
- **`created_at`** (Timestamp): When product was first added
- **`updated_at`** (Timestamp): When product was last modified

### **ID Generation Algorithm:**
```dart
// How product IDs are generated
String generateProductId(String brand, String productName, String size) {
  // Convert to lowercase, remove special characters, join with underscores
  final cleanBrand = brand.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  final cleanName = productName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  final cleanSize = size.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  
  return '${cleanBrand}_${cleanName}_${cleanSize}';
}

// Example: generateProductId("Bairaha", "Chicken Sausages", "500g")
// Result: "bairaha_chickensausages_500g"
```

### **Products Without Brand Names:**
When products don't have identifiable brand names (generic/unbranded items), the system handles them as follows:

```dart
// Examples of products without brand names
{
  "brand_name": "",  // Empty string for unbranded products
  "category": "fruits",
  "id": "_banana_1kg",  // ID starts with underscore when no brand
  "name": "Banana",
  "original_name": "Banana - 1 kg",
  "size": 1,
  "sizeRaw": "1kg",
  "sizeUnit": "kg",
  "variety": "Fresh Banana"
}

// Document ID Pattern for unbranded products:
// _{productname}_{size}
// Examples:
// "_banana_1kg"
// "_tomato_500g" 
// "_onion_1kg"
// "_bread_400g"
```

### **Handling Unbranded Products in Queries:**
```dart
// Check if product is unbranded
bool isUnbrandedProduct(Product product) {
  return product.brandName.isEmpty || product.id.startsWith('_');
}

// Filter branded vs unbranded products
Future<Map<String, List<Product>>> getBrandedVsUnbrandedProducts(String categoryId) async {
  final allProducts = await getProductsByCategory(categoryId);
  
  final branded = <Product>[];
  final unbranded = <Product>[];
  
  for (final product in allProducts) {
    if (isUnbrandedProduct(product)) {
      unbranded.add(product);
    } else {
      branded.add(product);
    }
  }
  
  return {
    'branded': branded,
    'unbranded': unbranded,
  };
}

// Display logic for product names
String getDisplayName(Product product) {
  if (product.brandName.isEmpty) {
    return product.name; // Just product name for unbranded
  } else {
    return '${product.brandName} ${product.name}'; // Brand + product name
  }
}
```

### **Flutter Queries for Products:**

#### **Get All Products in Category**
```dart
// Get all products in a specific category
Future<List<Product>> getProductsByCategory(String categoryId) async {
  final querySnapshot = await FirebaseFirestore.instance
      .collection('products')
      .where('category', isEqualTo: categoryId)
      .where('is_active', isEqualTo: true)  // Only active products
      .orderBy('name')
      .get();
  
  return querySnapshot.docs
      .map((doc) => Product.fromFirestore(doc.data(), doc.id))
      .toList();
}
```

#### **Search Products by Name**
```dart
// Search products by name (case-insensitive)
Future<List<Product>> searchProducts(String searchTerm) async {
  final querySnapshot = await FirebaseFirestore.instance
      .collection('products')
      .where('is_active', isEqualTo: true)
      .where('name', isGreaterThanOrEqualTo: searchTerm.toLowerCase())
      .where('name', isLessThanOrEqualTo: searchTerm.toLowerCase() + '\uf8ff')
      .limit(20)
      .get();
  
  return querySnapshot.docs
      .map((doc) => Product.fromFirestore(doc.data(), doc.id))
      .toList();
}
```

#### **Get Products by Brand**
```dart
// Get all products from a specific brand
Future<List<Product>> getProductsByBrand(String brandName) async {
  final querySnapshot = await FirebaseFirestore.instance
      .collection('products')
      .where('brand_name', isEqualTo: brandName)
      .where('is_active', isEqualTo: true)
      .orderBy('name')
      .get();
  
  return querySnapshot.docs
      .map((doc) => Product.fromFirestore(doc.data(), doc.id))
      .toList();
}
```

#### **Get Single Product by ID**
```dart
// Get specific product by exact ID
Future<Product?> getProduct(String productId) async {
  final docSnapshot = await FirebaseFirestore.instance
      .collection('products')
      .doc(productId)  // Uses exact product ID like "bairaha_bairahachickensausages_500g"
      .get();
  
  if (docSnapshot.exists) {
    final data = docSnapshot.data()!;
    if (data['is_active'] == true) {  // Only return if active
      return Product.fromFirestore(data, docSnapshot.id);
    }
  }
  return null;
}
```

#### **Get Products with Pagination**
```dart
// Get products with pagination (for efficient loading)
Future<List<Product>> getProductsPaginated({
  DocumentSnapshot? lastDocument,
  int limit = 20,
  String? categoryFilter,
}) async {
  Query query = FirebaseFirestore.instance
      .collection('products')
      .orderBy('name');
  
  if (categoryFilter != null) {
    query = query.where('category', isEqualTo: categoryFilter);
  }
  
  if (lastDocument != null) {
    query = query.startAfterDocument(lastDocument);
  }
  
  final querySnapshot = await query.limit(limit).get();
  
  return querySnapshot.docs
      .map((doc) => Product.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
      .toList();
}
```

---

## 💰 COLLECTION 3: CURRENT_PRICES

### **Collection Name:** `current_prices`

### **Purpose:** 
Store the most recent price for every product at every supermarket location. This enables instant price comparisons across stores and forms the basis for "best price" recommendations.

### **Document ID Format:**
`{supermarketId}_{productId}`
- `cargills_bairaha_bairahachickensausages_500g`
- `keells_bairaha_bairahachickensausages_500g`
- `arpico_anchor_milk_1l`

### **Document Structure:**
```dart
// Dart model for Current Prices (Based on Actual Database)
class CurrentPrice {
  final String id;  // Document ID (supermarketId_productId)
  final String supermarketId;
  final String productId;  // References products collection
  final double price;
  final String priceDate;  // ISO date string
  final String lastUpdated;  // ISO timestamp string

  CurrentPrice({
    required this.id,
    required this.supermarketId,
    required this.productId,
    required this.price,
    required this.priceDate,
    required this.lastUpdated,
  });
}
```

### **Actual Document Structure (From Firebase):**
```javascript
// Document ID: cargills_bairaha_bairahachickensausages_500g
{
  "lastUpdated": "2025-07-12T23:54:02.878098",  // String (ISO timestamp)
  "price": 646,  // Number
  "priceDate": "2025-07-12T00:00:00",  // String (ISO date)
  "productId": "bairaha_bairahachickensausages_500g",  // String - References products collection
  "supermarketId": "cargills"  // String
}
```

### **Field Descriptions:**
- **Document ID**: Auto-generated as `{supermarketId}_{productId}`
- **`supermarketId`** (String): Store identifier (`cargills`, `keells`, `arpico`)
- **`productId`** (String): **CRITICAL REFERENCE** - Must match a document ID in `products` collection
- **`price`** (Number): Current price in LKR (646, 125.50, 89)
- **`priceDate`** (String): Date when price was recorded (ISO format: "2025-07-12T00:00:00")
- **`lastUpdated`** (String): Timestamp when record was last updated (ISO format with milliseconds)

### **Supermarket IDs:**
- `cargills` - Cargills Food City
- `keells` - Keells Super stores  
- `arpico` - Arpico Supercenter

### **Document ID Generation:**
```dart
// How current price document IDs are created
String createCurrentPriceId(String supermarketId, String productId) {
  return '${supermarketId}_${productId}';
}

// Example: createCurrentPriceId("cargills", "bairaha_bairahachickensausages_500g")
// Result: "cargills_bairaha_bairahachickensausages_500g"
```

### **Flutter Queries for Current Prices:**

#### **Get All Current Prices for a Product (Price Comparison)**
```dart
// Get current prices across all supermarkets for a specific product
Future<List<CurrentPrice>> getCurrentPricesForProduct(String productId) async {
  final querySnapshot = await FirebaseFirestore.instance
      .collection('current_prices')
      .where('productId', isEqualTo: productId)
      .orderBy('price', descending: false)  // Cheapest first
      .get();
  
  return querySnapshot.docs
      .map((doc) => CurrentPrice.fromFirestore(doc.data(), doc.id))
      .toList();
}
```

#### **Get Best Price for Product**
```dart
// Get the cheapest current price for a specific product
Future<CurrentPrice?> getBestPriceForProduct(String productId) async {
  final querySnapshot = await FirebaseFirestore.instance
      .collection('current_prices')
      .where('productId', isEqualTo: productId)
      .orderBy('price', descending: false)
      .limit(1)
      .get();
  
  if (querySnapshot.docs.isNotEmpty) {
    final doc = querySnapshot.docs.first;
    return CurrentPrice.fromFirestore(doc.data(), doc.id);
  }
  return null;
}
```

#### **Get Price at Specific Store**
```dart
// Get current price for a product at a specific supermarket
Future<CurrentPrice?> getPriceAtStore(String supermarketId, String productId) async {
  final docId = '${supermarketId}_${productId}';
  final docSnapshot = await FirebaseFirestore.instance
      .collection('current_prices')
      .doc(docId)
      .get();
  
  if (docSnapshot.exists) {
    return CurrentPrice.fromFirestore(docSnapshot.data()!, docSnapshot.id);
  }
  return null;
}
```

#### **Get All Prices from Specific Supermarket**
```dart
// Get all current prices from one supermarket (e.g., for store comparison)
Future<List<CurrentPrice>> getPricesFromSupermarket(String supermarketId) async {
  final querySnapshot = await FirebaseFirestore.instance
      .collection('current_prices')
      .where('supermarketId', isEqualTo: supermarketId)
      .orderBy('lastUpdated', descending: true)
      .get();
  
  return querySnapshot.docs
      .map((doc) => CurrentPrice.fromFirestore(doc.data(), doc.id))
      .toList();
}
```

#### **Get Recent Price Updates**
```dart
// Get recently updated prices (useful for "what's new" features)
Future<List<CurrentPrice>> getRecentPriceUpdates({int hoursBack = 24}) async {
  final cutoffTime = DateTime.now().subtract(Duration(hours: hoursBack));
  final cutoffString = cutoffTime.toIso8601String();
  
  final querySnapshot = await FirebaseFirestore.instance
      .collection('current_prices')
      .where('lastUpdated', isGreaterThan: cutoffString)
      .orderBy('lastUpdated', descending: true)
      .limit(50)
      .get();
  
  return querySnapshot.docs
      .map((doc) => CurrentPrice.fromFirestore(doc.data(), doc.id))
      .toList();
}
```

---

## 📈 COLLECTION 4: PRICE_HISTORY_MONTHLY

### **Collection Name:** `price_history_monthly`

### **Purpose:** 
Store historical price data organized by month with pre-calculated analytics. This collection enables efficient trend analysis, price volatility calculations, and chart generation without expensive real-time computations.

### **Document ID Format:**
`{supermarketId}_{productId}_{YYYY}_{MM}`
- `cargills_bairaha_bairahachickensausages_500g_2025_07` (July 2025)
- `keells_bairaha_bairahachickensausages_500g_2025_08` (August 2025)
- `arpico_anchor_milk_1l_2025_12` (December 2025)

### **Document Structure:**
```dart
// Dart model for Monthly Price History (Based on Actual Database)
class MonthlyPriceHistory {
  final String id;  // Document ID
  final String productId;  // References products collection
  final String supermarketId;
  final int year;
  final int month;
  final Map<String, double> dailyPrices;  // Date string -> price
  final MonthSummary monthSummary;
  final String lastUpdated;  // ISO timestamp string

  MonthlyPriceHistory({
    required this.id,
    required this.productId,
    required this.supermarketId,
    required this.year,
    required this.month,
    required this.dailyPrices,
    required this.monthSummary,
    required this.lastUpdated,
  });
}

// Dart model for Month Summary Analytics
class MonthSummary {
  final double avgPrice;
  final String bestBuyDay;  // Date string "2025-07-12"
  final double closingPrice;
  final int daysWithData;
  final double maxPrice;
  final double minPrice;
  final double openingPrice;
  final double priceRange;
  final double priceStabilityScore;  // 0-10 scale
  final double priceVolatility;
  final double totalChangePercent;
  final String trendDirection;  // "upward", "downward", "stable"

  MonthSummary({
    required this.avgPrice,
    required this.bestBuyDay,
    required this.closingPrice,
    required this.daysWithData,
    required this.maxPrice,
    required this.minPrice,
    required this.openingPrice,
    required this.priceRange,
    required this.priceStabilityScore,
    required this.priceVolatility,
    required this.totalChangePercent,
    required this.trendDirection,
  });
}
```

### **Actual Document Structure (From Firebase):**
```javascript
// Document ID: cargills_bairaha_bairahachickensausages_500g_2025_07
{
  "daily_prices": {  // Map
    "2025-07-12": 646  // Date string -> Number (price)
  },
  "last_updated": "2025-07-12T23:54:03.198145",  // String (ISO timestamp)
  "month": 7,  // Number
  "month_summary": {  // Map
    "avg_price": 646,  // Number
    "best_buy_day": "2025-07-12",  // String (date)
    "closing_price": 646,  // Number
    "days_with_data": 1,  // Number
    "max_price": 646,  // Number
    "min_price": 646,  // Number
    "opening_price": 646,  // Number
    "price_range": 0,  // Number
    "price_stability_score": 10,  // Number (0-10)
    "price_volatility": 0,  // Number (percentage)
    "total_change_percent": 0,  // Number (percentage)
    "trend_direction": "stable"  // String ("upward"/"downward"/"stable")
  },
  "productId": "bairaha_bairahachickensausages_500g",  // String - References products collection
  "supermarketId": "cargills",  // String
  "year": 2025  // Number
}
```

### **Field Descriptions:**
- **Document ID**: Auto-generated as `{supermarketId}_{productId}_{year}_{month}`
- **`productId`** (String): **CRITICAL REFERENCE** - Must match a document ID in `products` collection
- **`supermarketId`** (String): Store identifier (`cargills`, `keells`, `arpico`)
- **`year`** (Number): Year (2025, 2026)
- **`month`** (Number): Month number (1-12, where 7 = July)
- **`daily_prices`** (Map): Date strings mapped to price values
  - Key format: "YYYY-MM-DD" (e.g., "2025-07-12")
  - Value: Price as number (646, 125.50)
- **`month_summary`** (Map): Pre-calculated analytics for the month
- **`last_updated`** (String): ISO timestamp when document was last modified

### **Month Summary Analytics Explained:**
- **`avg_price`**: Average price for the month
- **`best_buy_day`**: Date with the lowest price 
- **`closing_price`**: Price on the last day of data
- **`opening_price`**: Price on the first day of data
- **`max_price`**: Highest price recorded
- **`min_price`**: Lowest price recorded
- **`price_range`**: Difference between max and min price
- **`price_volatility`**: Price volatility percentage (0 = stable, higher = more volatile)
- **`price_stability_score`**: Stability rating 0-10 (10 = very stable, 0 = very volatile)
- **`total_change_percent`**: Percentage change from opening to closing price
- **`trend_direction`**: Overall price trend ("upward", "downward", "stable")
- **`days_with_data`**: Number of days with recorded prices

### **Document ID Generation:**
```dart
// How price history document IDs are created
String createPriceHistoryId(String supermarketId, String productId, DateTime date) {
  final year = date.year;
  final month = date.month.toString().padLeft(2, '0');
  return '${supermarketId}_${productId}_${year}_${month}';
}

// Example: createPriceHistoryId("cargills", "bairaha_bairahachickensausages_500g", DateTime(2025, 7, 12))
// Result: "cargills_bairaha_bairahachickensausages_500g_2025_07"
```
```

### **Flutter Queries for Price History:**

#### **Get Price History for Charts (Multiple Months)**
```dart
// Get 6 months of price history for a product at a specific store
Future<List<MonthlyPriceHistory>> getPriceHistory(
  String supermarketId, 
  String productId, 
  {int monthsBack = 6}
) async {
  final currentDate = DateTime.now();
  final documents = <MonthlyPriceHistory>[];
  
  for (int i = 0; i < monthsBack; i++) {
    final targetDate = DateTime(currentDate.year, currentDate.month - i, 1);
    final year = targetDate.year;
    final month = targetDate.month.toString().padLeft(2, '0');
    
    final docId = '${supermarketId}_${productId}_${year}_${month}';
    
    final docSnapshot = await FirebaseFirestore.instance
        .collection('price_history_monthly')
        .doc(docId)
        .get();
    
    if (docSnapshot.exists) {
      documents.add(MonthlyPriceHistory.fromFirestore(docSnapshot.data()!, docSnapshot.id));
    }
  }
  
  return documents..sort((a, b) => a.year.compareTo(b.year) != 0 
      ? a.year.compareTo(b.year) 
      : a.month.compareTo(b.month));
}
```

#### **Get Current Month Price History**
```dart
// Get current month's daily prices for real-time charts
Future<MonthlyPriceHistory?> getCurrentMonthHistory(
  String supermarketId, 
  String productId
) async {
  final now = DateTime.now();
  final year = now.year;
  final month = now.month.toString().padLeft(2, '0');
  
  final docId = '${supermarketId}_${productId}_${year}_${month}';
  
  final docSnapshot = await FirebaseFirestore.instance
      .collection('price_history_monthly')
      .doc(docId)
      .get();
  
  if (docSnapshot.exists) {
    return MonthlyPriceHistory.fromFirestore(docSnapshot.data()!, docSnapshot.id);
  }
  return null;
}
```

#### **Get Price Trends Across All Stores**
```dart
// Get price trends for a product across all supermarkets
Future<Map<String, MonthSummary>> getPriceTrendsForProduct(
  String productId,
  {int year = 0, int month = 0}
) async {
  final targetYear = year == 0 ? DateTime.now().year : year;
  final targetMonth = month == 0 ? DateTime.now().month : month;
  final monthStr = targetMonth.toString().padLeft(2, '0');
  
  final trends = <String, MonthSummary>{};
  final supermarkets = ['keells', 'cargills', 'arpico'];
  
  for (final supermarket in supermarkets) {
    final docId = '${supermarket}_${productId}_${targetYear}_${monthStr}';
    
    final docSnapshot = await FirebaseFirestore.instance
        .collection('price_history_monthly')
        .doc(docId)
        .get();
    
    if (docSnapshot.exists) {
      final data = docSnapshot.data()!;
      // Use correct field name from Firebase: 'month_summary' (with underscore)
      trends[supermarket] = MonthSummary.fromMap(data['month_summary']);
    }
  }
  
  return trends;
}
```

#### **Get Most Volatile Products**
```dart
// Get products with highest price volatility this month
Future<List<String>> getMostVolatileProducts({int limit = 10}) async {
  final now = DateTime.now();
  final year = now.year;
  final month = now.month;
  
  final querySnapshot = await FirebaseFirestore.instance
      .collection('price_history_monthly')
      .where('year', isEqualTo: year)
      .where('month', isEqualTo: month)
      .orderBy('month_summary.price_volatility', descending: true)  // Corrected field path
      .limit(limit)
      .get();
  
  return querySnapshot.docs
      .map((doc) => doc.data()['productId'] as String)
      .toSet()  // Remove duplicates
      .toList();
}
```

#### **Get Best Buy Days Analysis**
```dart
// Get best buy days for multiple products
Future<Map<String, String>> getBestBuyDays(List<String> productIds) async {
  final now = DateTime.now();
  final year = now.year;
  final month = now.month.toString().padLeft(2, '0');
  
  final bestBuyDays = <String, String>{};
  
  for (final productId in productIds) {
    // Check all supermarkets for this product
    final supermarkets = ['keells', 'cargills', 'arpico'];
    double bestPrice = double.infinity;
    String bestDay = '';
    
    for (final supermarket in supermarkets) {
      final docId = '${supermarket}_${productId}_${year}_${month}';
      
      final docSnapshot = await FirebaseFirestore.instance
          .collection('price_history_monthly')
          .doc(docId)
          .get();
      
      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        // Use correct field name: 'month_summary' (with underscore)
        final monthSummary = data['month_summary'];
        final minPrice = monthSummary['min_price'] as double;  // Corrected field name
        
        if (minPrice < bestPrice) {
          bestPrice = minPrice;
          bestDay = monthSummary['best_buy_day'] as String;  // Corrected field name
        }
      }
    }
    
    if (bestDay.isNotEmpty) {
      bestBuyDays[productId] = bestDay;
    }
  }
  
  return bestBuyDays;
}
```

---

## 🔧 Document ID Generation

### **Utility Functions for Creating Document IDs:**

```dart
// Utility class for generating document IDs
class DocumentIdGenerator {
  
  // Generate current price document ID
  static String createCurrentPriceId(String supermarketId, String productId) {
    return '${supermarketId}_${productId}';
  }
  
  // Generate price history document ID
  static String createPriceHistoryId(String supermarketId, String productId, DateTime date) {
    final year = date.year;
    final month = date.month.toString().padLeft(2, '0');
    return '${supermarketId}_${productId}_${year}_${month}';
  }
  
  // Generate product ID from classification data
  static String createProductId(String category, String brand, String productName, String size) {
    return '${_normalize(category)}_${_normalize(brand)}_${_normalize(productName)}_${_normalize(size)}';
  }
  
  // Normalize text for ID generation
  static String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }
}

// Example usage:
// DocumentIdGenerator.createCurrentPriceId('keells', 'fruits_banana_ambul_1kg')
// Result: 'keells_fruits_banana_ambul_1kg'

// DocumentIdGenerator.createPriceHistoryId('cargills', 'dairy_anchor_milk_1l', DateTime.now())
// Result: 'cargills_dairy_anchor_milk_1l_2025_07'
```

---

## ⚠️ Critical Validation Requirements

### **Before Creating/Updating Any Document:**

1. **Product Reference Validation:**
```dart
// Always verify product exists before creating price documents
Future<bool> validateProductExists(String productId) async {
  final docSnapshot = await FirebaseFirestore.instance
      .collection('products')
      .doc(productId)
      .get();
  return docSnapshot.exists;
}
```

2. **Category Reference Validation:**
```dart
// Verify category exists before creating product
Future<bool> validateCategoryExists(String categoryId) async {
  final docSnapshot = await FirebaseFirestore.instance
      .collection('categories')
      .doc(categoryId)
      .get();
  return docSnapshot.exists;
}
```

3. **Supermarket ID Validation:**
```dart
// Validate supermarket ID
bool validateSupermarketId(String supermarketId) {
  const validSupermarkets = ['keells', 'cargills', 'arpico'];
  return validSupermarkets.contains(supermarketId.toLowerCase());
}
```

4. **Price Validation:**
```dart
// Validate price values
bool validatePrice(double price) {
  return price > 0 && price < 999999; // Reasonable price range
}
```

### **Important Note for Mobile Developers:**
**🔒 READ-ONLY ACCESS**: Mobile applications have **read-only** access to all database collections. You cannot create, update, or delete any records. All data modifications are handled by the backend crawler system and admin panel.

### **Error Handling Example:**
```dart
Future<CurrentPrice?> getPriceWithErrorHandling(String supermarketId, String productId) async {
  try {
    // Validation
    if (!validateSupermarketId(supermarketId)) {
      throw Exception('Invalid supermarket ID: $supermarketId');
    }
    
    if (!await validateProductExists(productId)) {
      throw Exception('Product does not exist: $productId');
    }
    
    // Get document (READ-ONLY)
    final docId = DocumentIdGenerator.createCurrentPriceId(supermarketId, productId);
    
    final docSnapshot = await FirebaseFirestore.instance
        .collection('current_prices')
        .doc(docId)
        .get();
    
    if (docSnapshot.exists) {
      return CurrentPrice.fromFirestore(docSnapshot.data()!, docSnapshot.id);
    }
    
    return null;
    
  } catch (e) {
    print('Error fetching current price: $e');
    return null;
  }
}
```

---

## 🚀 Performance Optimization Tips

### **1. Use Composite Indexes:**
Create these composite indexes in Firebase Console:
- `products`: `category` (Ascending), `name` (Ascending)
- `current_prices`: `productId` (Ascending), `price` (Ascending)
- `price_history_monthly`: `productId` (Ascending), `year` (Descending), `month` (Descending)

### **2. Implement Caching:**
```dart
// Cache frequently accessed data
class DatabaseCache {
  static final Map<String, List<Category>> _categoryCache = {};
  static final Map<String, Product> _productCache = {};
  
  static Future<List<Category>> getCachedCategories() async {
    if (_categoryCache.isEmpty) {
      final categories = await getAllCategories();
      _categoryCache['all'] = categories;
    }
    return _categoryCache['all']!;
  }
}
```

### **3. Use Pagination:**
```dart
// Always use pagination for large datasets
Future<List<Product>> getProductsPaginated({
  DocumentSnapshot? lastDocument,
  int limit = 20,
}) async {
  Query query = FirebaseFirestore.instance
      .collection('products')
      .orderBy('name')
      .limit(limit);
  
  if (lastDocument != null) {
    query = query.startAfterDocument(lastDocument);
  }
  
  final querySnapshot = await query.get();
  return querySnapshot.docs
      .map((doc) => Product.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
      .toList();
}
```

### **4. Efficient Query Patterns:**
```dart
// Use specific queries instead of broad scans
Future<List<Product>> getProductsEfficiently(String categoryId, {String? brandFilter}) async {
  Query query = FirebaseFirestore.instance
      .collection('products')
      .where('category', isEqualTo: categoryId)
      .where('is_active', isEqualTo: true);
  
  // Add brand filter if specified
  if (brandFilter != null && brandFilter.isNotEmpty) {
    query = query.where('brand_name', isEqualTo: brandFilter);
  }
  
  query = query.orderBy('name').limit(50); // Always limit results
  
  final querySnapshot = await query.get();
  return querySnapshot.docs
      .map((doc) => Product.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
      .toList();
}
```

---

## 📱 Flutter Integration Examples

### **Complete Product Price Comparison Widget:**
```dart
class ProductPriceComparison extends StatefulWidget {
  final String productId;
  
  const ProductPriceComparison({Key? key, required this.productId}) : super(key: key);
  
  @override
  _ProductPriceComparisonState createState() => _ProductPriceComparisonState();
}

class _ProductPriceComparisonState extends State<ProductPriceComparison> {
  List<CurrentPrice> prices = [];
  Product? product;
  bool loading = true;
  
  @override
  void initState() {
    super.initState();
    loadData();
  }
  
  Future<void> loadData() async {
    try {
      // Load product details and current prices in parallel (READ-ONLY)
      final results = await Future.wait([
        getProduct(widget.productId),
        getCurrentPricesForProduct(widget.productId),
      ]);
      
      setState(() {
        product = results[0] as Product?;
        prices = results[1] as List<CurrentPrice>;
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
      });
      // Handle error
    }
  }
  
  String getProductDisplayName() {
    if (product == null) return '';
    
    // Handle unbranded products (empty brand_name or ID starts with '_')
    if (product!.brandName.isEmpty || product!.id.startsWith('_')) {
      return product!.name; // Just product name for unbranded items
    } else {
      return '${product!.brandName} ${product!.name}'; // Brand + product name
    }
  }
  
  Widget buildBrandLabel() {
    if (product == null) return SizedBox.shrink();
    
    if (product!.brandName.isEmpty || product!.id.startsWith('_')) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'UNBRANDED',
          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
        ),
      );
    } else {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.blue[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          product!.brandName.toUpperCase(),
          style: TextStyle(fontSize: 10, color: Colors.blue[800]),
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Center(child: CircularProgressIndicator());
    }
    
    if (product == null) {
      return Center(child: Text('Product not found'));
    }
    
    return Column(
      children: [
        // Product header with brand handling
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                // Product image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    product!.imageUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => 
                        Icon(Icons.image_not_supported, size: 60),
                  ),
                ),
                SizedBox(width: 12),
                
                // Product details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        getProductDisplayName(),
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      SizedBox(height: 4),
                      buildBrandLabel(),
                      SizedBox(height: 4),
                      Text(
                        '${product!.sizeRaw} • ${product!.variety}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Price comparison cards
        ...prices.map((price) => PriceCard(
          supermarket: price.supermarketId,
          price: price.price,
          lastUpdated: price.lastUpdated,
          isBestPrice: price == prices.first, // First item is cheapest
        )).toList(),
        
        // Price history button
        ElevatedButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PriceHistoryScreen(productId: widget.productId),
            ),
          ),
          child: Text('View Price History'),
        ),
      ],
    );
  }
}
```

### **Real-time Price Updates:**
```dart
class RealTimePriceTracker extends StatefulWidget {
  final List<String> productIds;
  
  const RealTimePriceTracker({Key? key, required this.productIds}) : super(key: key);
  
  @override
  _RealTimePriceTrackerState createState() => _RealTimePriceTrackerState();
}

class _RealTimePriceTrackerState extends State<RealTimePriceTracker> {
  late Stream<List<CurrentPrice>> priceStream;
  
  @override
  void initState() {
    super.initState();
    setupPriceStream();
  }
  
  void setupPriceStream() {
    priceStream = FirebaseFirestore.instance
        .collection('current_prices')
        .where('productId', whereIn: widget.productIds)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CurrentPrice.fromFirestore(doc.data(), doc.id))
            .toList());
  }
  
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CurrentPrice>>(
      stream: priceStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }
        
        final prices = snapshot.data!;
        
        return ListView.builder(
          itemCount: prices.length,
          itemBuilder: (context, index) {
            final price = prices[index];
            return ListTile(
              title: Text(price.productId),
              subtitle: Text(price.supermarketId),
              trailing: Text('Rs ${price.price.toStringAsFixed(2)}'),
            );
          },
        );
      },
    );
  }
}
```
