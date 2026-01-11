import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FriendGroup {
  final String id;
  final String name;
  final String userId;
  final String? description;
  final String iconName;
  final int colorValue;
  final List<String> memberIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  FriendGroup({
    required this.id,
    required this.name,
    required this.userId,
    this.description,
    required this.iconName,
    required this.colorValue,
    required this.memberIds,
    required this.createdAt,
    required this.updatedAt,
  });

  // Get color as Flutter Color object
  Color get color => Color(colorValue);

  // Predefined group templates
  static List<FriendGroup> getDefaultGroupTemplates(String userId) {
    final now = DateTime.now();
    return [
      FriendGroup(
        id: 'temp_family',
        name: 'Family',
        userId: userId,
        description: 'Family members',
        iconName: 'family_restroom',
        colorValue: Colors.orange.toARGB32(),
        memberIds: [],
        createdAt: now,
        updatedAt: now,
      ),
      FriendGroup(
        id: 'temp_school',
        name: 'School',
        userId: userId,
        description: 'School friends and classmates',
        iconName: 'school',
        colorValue: Colors.blue.toARGB32(),
        memberIds: [],
        createdAt: now,
        updatedAt: now,
      ),
      FriendGroup(
        id: 'temp_work',
        name: 'Work',
        userId: userId,
        description: 'Work colleagues',
        iconName: 'work',
        colorValue: Colors.green.toARGB32(),
        memberIds: [],
        createdAt: now,
        updatedAt: now,
      ),
      FriendGroup(
        id: 'temp_close',
        name: 'Close Friends',
        userId: userId,
        description: 'Best friends',
        iconName: 'favorite',
        colorValue: Colors.red.toARGB32(),
        memberIds: [],
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  factory FriendGroup.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FriendGroup(
      id: doc.id,
      name: data['name'] as String,
      userId: data['userId'] as String,
      description: data['description'] as String?,
      iconName: data['iconName'] as String,
      colorValue: data['colorValue'] as int,
      memberIds: List<String>.from(data['memberIds'] as List),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'userId': userId,
      'description': description,
      'iconName': iconName,
      'colorValue': colorValue,
      'memberIds': memberIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  FriendGroup copyWith({
    String? id,
    String? name,
    String? description,
    String? iconName,
    Color? color,
    List<String>? memberIds,
    DateTime? updatedAt,
  }) {
    return FriendGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      userId: userId,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      colorValue: color?.toARGB32() ?? colorValue,
      memberIds: memberIds ?? this.memberIds,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
