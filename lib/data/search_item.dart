import 'package:cloud_firestore/cloud_firestore.dart';

class SearchItem {
  final String id;
  final String name;
  final String category;
  final String imageUrl;

  SearchItem({
    required this.id,
    required this.name,
    required this.category,
    required this.imageUrl,
  });

  factory SearchItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SearchItem(
      id: doc.id,
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      imageUrl: data['image_url'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {'name': name, 'category': category, 'image_url': imageUrl};
  }
}
