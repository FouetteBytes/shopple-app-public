import 'package:equatable/equatable.dart';

/// Model representing channel/conversation settings
class ChatChannelModel extends Equatable {
  final String id;
  final String name;
  final String? imageUrl;
  final List<String> memberIds;
  final DateTime? lastMessageAt;
  final String? lastMessage;
  final int unreadCount;
  final bool isMuted;
  final String type; // 'direct', 'group', 'friends_group'
  final String? createdBy;
  final DateTime createdAt;

  const ChatChannelModel({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.memberIds,
    this.lastMessageAt,
    this.lastMessage,
    this.unreadCount = 0,
    this.isMuted = false,
    this.type = 'direct',
    this.createdBy,
    required this.createdAt,
  });

  factory ChatChannelModel.empty() => ChatChannelModel(
    id: '',
    name: '',
    memberIds: const [],
    createdAt: DateTime.now(),
  );

  bool get isGroupChat => memberIds.length > 2;
  bool get hasUnreadMessages => unreadCount > 0;

  ChatChannelModel copyWith({
    String? id,
    String? name,
    String? imageUrl,
    List<String>? memberIds,
    DateTime? lastMessageAt,
    String? lastMessage,
    int? unreadCount,
    bool? isMuted,
    String? type,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return ChatChannelModel(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      memberIds: memberIds ?? this.memberIds,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      isMuted: isMuted ?? this.isMuted,
      type: type ?? this.type,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'imageUrl': imageUrl,
    'memberIds': memberIds,
    'lastMessageAt': lastMessageAt?.toIso8601String(),
    'lastMessage': lastMessage,
    'unreadCount': unreadCount,
    'isMuted': isMuted,
    'type': type,
    'createdBy': createdBy,
    'createdAt': createdAt.toIso8601String(),
  };

  factory ChatChannelModel.fromJson(Map<String, dynamic> json) =>
      ChatChannelModel(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        imageUrl: json['imageUrl'] as String?,
        memberIds: (json['memberIds'] as List<dynamic>?)?.cast<String>() ?? [],
        lastMessageAt: json['lastMessageAt'] != null
            ? DateTime.tryParse(json['lastMessageAt'] as String)
            : null,
        lastMessage: json['lastMessage'] as String?,
        unreadCount: json['unreadCount'] as int? ?? 0,
        isMuted: json['isMuted'] as bool? ?? false,
        type: json['type'] as String? ?? 'direct',
        createdBy: json['createdBy'] as String?,
        createdAt:
            DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now(),
      );

  @override
  List<Object?> get props => [
    id,
    name,
    imageUrl,
    memberIds,
    lastMessageAt,
    lastMessage,
    unreadCount,
    isMuted,
    type,
    createdBy,
    createdAt,
  ];
}
