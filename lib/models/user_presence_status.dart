class UserPresenceStatus {
  final bool isOnline;
  final DateTime? lastSeen;
  final String? customStatus;
  final String? statusEmoji;

  UserPresenceStatus({
    required this.isOnline,
    this.lastSeen,
    this.customStatus,
    this.statusEmoji,
  });

  factory UserPresenceStatus.offline() {
    return UserPresenceStatus(isOnline: false);
  }

  String get displayText {
    if (isOnline) return 'Online';

    if (lastSeen != null) {
      final now = DateTime.now();
      final difference = now.difference(lastSeen!);

      if (difference.inMinutes < 5) return 'Just now';
      if (difference.inHours < 1) return '${difference.inMinutes} min ago';
      if (difference.inDays < 1) return '${difference.inHours} hours ago';
      if (difference.inDays < 7) return '${difference.inDays} days ago';
      return 'Last seen ${lastSeen!.day}/${lastSeen!.month}';
    }

    return 'Offline';
  }
}
