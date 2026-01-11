import 'package:equatable/equatable.dart';

/// Model representing a user within the chat system
///
/// Contains information about a user's status and permissions
/// in the chat system, separate from their authentication profile.
class ChatUserModel extends Equatable {
  /// Date when the user account was created in ISO format (YYYY-MM-DD)
  final String createdAt;

  /// Whether the user is banned from the chat system
  final bool isUserBanned;

  /// User's ID from Firebase Auth
  final String userId;

  /// User's display name for chat
  final String? displayName;

  /// User's photo URL for chat
  final String? photoUrl;

  const ChatUserModel({
    required this.createdAt,
    required this.isUserBanned,
    required this.userId,
    this.displayName,
    this.photoUrl,
  });

  /// Creates an empty chat user model representing an unauthenticated state
  factory ChatUserModel.empty() => const ChatUserModel(
    createdAt: '',
    isUserBanned: false,
    userId: '',
    displayName: null,
    photoUrl: null,
  );

  /// Checks if this user has a valid connection to the chat system
  bool get isConnected => createdAt.isNotEmpty && userId.isNotEmpty;

  /// Checks if this user can participate in chats
  bool get canParticipate => isConnected && !isUserBanned;

  /// Creates a copy of this model with some fields replaced
  ChatUserModel copyWith({
    String? createdAt,
    bool? isUserBanned,
    String? userId,
    String? displayName,
    String? photoUrl,
  }) {
    return ChatUserModel(
      createdAt: createdAt ?? this.createdAt,
      isUserBanned: isUserBanned ?? this.isUserBanned,
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  /// Converts the model to JSON
  Map<String, dynamic> toJson() => {
    'createdAt': createdAt,
    'isUserBanned': isUserBanned,
    'userId': userId,
    'displayName': displayName,
    'photoUrl': photoUrl,
  };

  /// Creates a model from JSON data
  factory ChatUserModel.fromJson(Map<String, dynamic> json) => ChatUserModel(
    createdAt: json['createdAt'] as String? ?? '',
    isUserBanned: json['isUserBanned'] as bool? ?? false,
    userId: json['userId'] as String? ?? '',
    displayName: json['displayName'] as String?,
    photoUrl: json['photoUrl'] as String?,
  );

  @override
  List<Object?> get props => [
    createdAt,
    isUserBanned,
    userId,
    displayName,
    photoUrl,
  ];
}
