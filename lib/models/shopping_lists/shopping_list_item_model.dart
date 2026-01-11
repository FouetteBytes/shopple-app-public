import 'package:cloud_firestore/cloud_firestore.dart';

class ShoppingListItem {
  final String id;
  final String listId;
  final String? productId;
  final String name;
  final int quantity;
  final String unit;
  final String notes;
  final bool isCompleted;
  final double estimatedPrice;
  final String category;
  final int order;
  final String addedBy;
  final DateTime addedAt;
  final DateTime? completedAt;
  final DateTime updatedAt;

  ShoppingListItem({
    required this.id,
    required this.listId,
    this.productId,
    required this.name,
    this.quantity = 1,
    this.unit = 'items',
    this.notes = '',
    this.isCompleted = false,
    this.estimatedPrice = 0.0,
    this.category = 'other',
    this.order = 0,
    required this.addedBy,
    required this.addedAt,
    this.completedAt,
    required this.updatedAt,
  });

  factory ShoppingListItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    DateTime toDate(dynamic v, {DateTime? fallback}) {
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      return fallback ?? DateTime.now();
    }

    return ShoppingListItem(
      id: doc.id,
      listId: data['listId'] ?? '',
      productId: data['productId'],
      name: data['name'] ?? '',
      quantity: data['quantity'] ?? 1,
      unit: data['unit'] ?? 'items',
      notes: data['notes'] ?? '',
      isCompleted: data['isCompleted'] ?? false,
      estimatedPrice: (data['estimatedPrice'] ?? 0.0).toDouble(),
      category: data['category'] ?? 'other',
      order: data['order'] ?? 0,
      addedBy: data['addedBy'] ?? '',
      addedAt: toDate(data['addedAt']),
      completedAt: data['completedAt'] != null
          ? toDate(data['completedAt'])
          : null,
      updatedAt: toDate(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'listId': listId,
      'productId': productId,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'notes': notes,
      'isCompleted': isCompleted,
      'estimatedPrice': estimatedPrice,
      'category': category,
      'order': order,
      'addedBy': addedBy,
      'addedAt': Timestamp.fromDate(addedAt),
      'completedAt': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  String get displayName => name;
  double get totalPrice => estimatedPrice * quantity;
  bool get isFromProduct => productId != null;

  ShoppingListItem copyWith({
    String? id,
    String? listId,
    String? productId,
    String? name,
    int? quantity,
    String? unit,
    String? notes,
    bool? isCompleted,
    double? estimatedPrice,
    String? category,
    int? order,
    String? addedBy,
    DateTime? addedAt,
    DateTime? completedAt,
    DateTime? updatedAt,
  }) {
    return ShoppingListItem(
      id: id ?? this.id,
      listId: listId ?? this.listId,
      productId: productId ?? this.productId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      notes: notes ?? this.notes,
      isCompleted: isCompleted ?? this.isCompleted,
      estimatedPrice: estimatedPrice ?? this.estimatedPrice,
      category: category ?? this.category,
      order: order ?? this.order,
      addedBy: addedBy ?? this.addedBy,
      addedAt: addedAt ?? this.addedAt,
      completedAt: completedAt ?? this.completedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
