import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopple/values/values.dart';
import 'package:shopple/models/shopping_lists/shopping_list_model.dart';
import 'package:shopple/services/user_service.dart';
import 'package:shopple/services/user/user_profile_stream_service.dart';
import 'package:shopple/services/presence/presence_service.dart';
import 'package:shopple/models/user_presence_status.dart';
import 'package:shopple/widgets/unified_profile_avatar.dart';
import 'package:shopple/bottom_sheets/bottom_sheets.dart';
import 'package:shopple/services/user/other_user_details_service.dart';

/// Modern member avatars with dynamic presence-based sorting.
/// Owner displayed separately, then collaborators sorted by online status.
/// Online members animate to the front when they come online.
Widget buildMemberAvatars(
  ShoppingList list, {
  int maxVisible = 4,
  bool compact = false,
}) {
  final ownerId = list.createdBy;
  final others = list.memberIds.where((m) => m != ownerId).toList();
  final visible = others.take(maxVisible).toList();
  final overflow = others.length - visible.length;

  // Prefetch owner and visible member profiles
  unawaited(
    UserProfileStreamService.instance.prefetchUsers({
      if (ownerId.isNotEmpty) ownerId,
      ...visible.where((e) => e.isNotEmpty),
    }),
  );
  
  return DynamicMemberAvatars(
    list: list,
    ownerId: ownerId,
    memberIds: visible,
    overflow: overflow,
    maxVisible: maxVisible,
    compact: compact,
  );
}

/// Stateful widget to handle dynamic presence-based member sorting
class DynamicMemberAvatars extends StatefulWidget {
  final ShoppingList list;
  final String ownerId;
  final List<String> memberIds;
  final int overflow;
  final int maxVisible;
  final bool compact;
  
  const DynamicMemberAvatars({
    super.key,
    required this.list,
    required this.ownerId,
    required this.memberIds,
    required this.overflow,
    required this.maxVisible,
    required this.compact,
  });
  
  @override
  State<DynamicMemberAvatars> createState() => _DynamicMemberAvatarsState();
}

class _DynamicMemberAvatarsState extends State<DynamicMemberAvatars> {
  // Track online status for each member
  final Map<String, bool> _onlineStatus = {};
  final Map<String, StreamSubscription<UserPresenceStatus>> _presenceSubs = {};
  
  @override
  void initState() {
    super.initState();
    _subscribeToPresence();
  }
  
  @override
  void didUpdateWidget(DynamicMemberAvatars oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_listEquals(oldWidget.memberIds, widget.memberIds)) {
      _unsubscribeAll();
      _subscribeToPresence();
    }
  }
  
  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
  
  void _subscribeToPresence() {
    for (final memberId in widget.memberIds) {
      if (memberId.isEmpty) continue;
      _presenceSubs[memberId] = PresenceService.getUserPresenceStream(memberId)
          .listen((status) {
        final wasOnline = _onlineStatus[memberId] ?? false;
        final isOnline = status.isOnline;
        if (wasOnline != isOnline) {
          setState(() {
            _onlineStatus[memberId] = isOnline;
          });
        }
      });
    }
  }
  
  void _unsubscribeAll() {
    for (final sub in _presenceSubs.values) {
      sub.cancel();
    }
    _presenceSubs.clear();
  }
  
  @override
  void dispose() {
    _unsubscribeAll();
    super.dispose();
  }
  
  /// Sort members by online status (online first), maintaining original order within groups
  List<String> _getSortedMemberIds() {
    final online = <String>[];
    final offline = <String>[];
    
    for (final id in widget.memberIds) {
      if (_onlineStatus[id] == true) {
        online.add(id);
      } else {
        offline.add(id);
      }
    }
    
    return [...online, ...offline];
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: UserService.revision,
      builder: (context, _, __) {
        final owner = widget.ownerId.isNotEmpty 
            ? UserService.maybeGet(widget.ownerId) 
            : null;
        
        // Get sorted member IDs (online first)
        final sortedIds = _getSortedMemberIds();
        final memberInfos = [
          for (final id in sortedIds)
            if (id != widget.ownerId) UserService.maybeGet(id),
        ].whereType<UserInfo>().toList();
        
        final totalExpected = widget.memberIds.length + (owner != null ? 1 : 0);
        
        return LayoutBuilder(
          builder: (context, constraints) {
            double maxWidth = constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : 120;
            int dynamicVisible = memberInfos.length;
            double size = widget.compact ? 32 : 40;
            double overlap = 9;
            final double fixedOwnerSize = widget.compact ? 44 : 56;
            double ownerSize = fixedOwnerSize;
            
            double stackWidth(int count) => count == 0
                ? 0
                : size +
                      (count - 1) * (size - overlap) +
                      (widget.overflow > 0 ? size - overlap : 0);
            double totalWidth(int count) =>
                (widget.ownerId.isNotEmpty ? ownerSize + 4 : 0) + stackWidth(count);
            
            while (totalWidth(dynamicVisible) > maxWidth && size > 18) {
              size -= 2;
              overlap = (size * 0.28).clamp(4, size * 0.5);
              ownerSize = fixedOwnerSize;
            }
            
            while (totalWidth(dynamicVisible) > maxWidth && dynamicVisible > 1) {
              dynamicVisible--;
            }
            
            if (totalWidth(dynamicVisible) > maxWidth) {
              dynamicVisible = 0;
            }
            
            if (ownerSize > maxWidth) {
              ownerSize = maxWidth;
            }
            
            final showList = memberInfos.take(dynamicVisible).toList();
            final localOverflow = (memberInfos.length - showList.length) + widget.overflow;
            final width = stackWidth(showList.length);
            
            return SizedBox(
              width: maxWidth,
              child: Row(
                children: [
                  if (owner != null)
                    SizedBox(
                      width: ownerSize,
                      height: ownerSize,
                      child: OwnerAvatar(user: owner, size: ownerSize),
                    )
                  else if (widget.ownerId.isNotEmpty)
                    initialAvatar(widget.ownerId, ownerSize),
                  if (showList.isNotEmpty)
                    GestureDetector(
                      onTap: () => showMembersModal(context, widget.list),
                      child: SizedBox(
                        width: width,
                        height: size,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            for (int i = 0; i < showList.length; i++)
                              AnimatedPositioned(
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeOutCubic,
                                left: i * (size - overlap),
                                child: AnimatedMemberAvatar(
                                  key: ValueKey(showList[i].id),
                                  user: showList[i],
                                  role: roleFor(widget.list, showList[i].id),
                                  size: size,
                                  isOnline: _onlineStatus[showList[i].id] ?? false,
                                ),
                              ),
                            if (localOverflow > 0)
                              AnimatedPositioned(
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeOutCubic,
                                left: showList.length * (size - overlap),
                                child: Container(
                                  width: size,
                                  height: size,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white10,
                                    border: Border.all(
                                      color: Colors.white24,
                                      width: 1.2,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '+$localOverflow',
                                    style: GoogleFonts.lato(
                                      fontSize: (size * 0.34).clamp(8, 12),
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            if (showList.length < dynamicVisible &&
                                showList.length < totalExpected)
                              Positioned(
                                left: showList.length * (size - overlap),
                                child: initialAvatar('?', size),
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// Animated member avatar with presence indicator
class AnimatedMemberAvatar extends StatelessWidget {
  final UserInfo user;
  final String role;
  final double size;
  final bool isOnline;
  
  const AnimatedMemberAvatar({
    super.key,
    required this.user,
    required this.role,
    required this.size,
    required this.isOnline,
  });
  
  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: role,
      child: Semantics(
        label: 'Member ${user.displayName}, role $role${isOnline ? ", online" : ""}',
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 2),
              ),
              child: ClipOval(
                child: UnifiedProfileAvatar(
                  userId: user.id,
                  radius: size / 2,
                  enableCache: true,
                ),
              ),
            ),
            // Presence indicator with animation
            Positioned(
              right: -1,
              bottom: -1,
              child: AnimatedScale(
                scale: isOnline ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
                child: Container(
                  width: (size * 0.28).clamp(8, 12),
                  height: (size * 0.28).clamp(8, 12),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget initialAvatar(String id, double size) {
  final letter = id.isNotEmpty ? id[0].toUpperCase() : '?';
  return Container(
    width: size,
    height: size,
    margin: const EdgeInsets.only(left: 2),
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white10,
      border: Border.all(color: Colors.white24, width: 1.1),
    ),
    alignment: Alignment.center,
    child: Text(
      letter,
      style: TextStyle(
        fontSize: (size * 0.42).clamp(8, 14),
        fontWeight: FontWeight.w600,
        color: Colors.white70,
      ),
    ),
  );
}

class OwnerAvatar extends StatefulWidget {
  final UserInfo user;
  final double size;
  const OwnerAvatar({super.key, required this.user, this.size = 36});
  @override
  State<OwnerAvatar> createState() => _OwnerAvatarState();
}

class _OwnerAvatarState extends State<OwnerAvatar>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _fade;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fade = CurvedAnimation(parent: _c, curve: Curves.easeIn);
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final double size = widget.size;
    return FadeTransition(
      opacity: _fade,
      child: Tooltip(
        message: 'Owner',
        child: Semantics(
          label: 'Owner ${user.displayName}',
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Use UnifiedProfileAvatar directly so alignment/cropping matches Profile screen
                UnifiedProfileAvatar(
                  userId: user.id,
                  radius: size / 2,
                  enableCache: true,
                ),
                Positioned(
                  right: -1,
                  bottom: -1,
                  child: StreamBuilder<UserPresenceStatus>(
                    stream: PresenceService.getUserPresenceStream(user.id),
                    builder: (context, snap) {
                      final online = snap.data?.isOnline == true;
                      if (!online) return const SizedBox.shrink();
                      return Container(
                        width: (size * 0.28).clamp(10, 14),
                        height: (size * 0.28).clamp(10, 14),
                        decoration: BoxDecoration(
                          color: Colors.greenAccent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void showMembersModal(BuildContext context, ShoppingList list) {
  // Use the shared LiquidGlass animated bottom sheet for consistent visuals
  showAppBottomSheet(
    Padding(
      padding: const EdgeInsets.all(16),
      child: FutureBuilder<List<UserInfo>>(
        future: batchedUserFetch([
          if (list.createdBy.isNotEmpty) list.createdBy,
          ...list.memberIds.where((m) => m != list.createdBy),
        ]),
        builder: (context, snap) {
          final users = snap.data ?? [];
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Members',
                style: GoogleFonts.lato(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              ...users.map((u) {
                final role = roleFor(list, u.id);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 42,
                        height: 42,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // Avatar
                            UnifiedProfileAvatar(
                              userId: u.id,
                              radius: 21,
                              enableCache: true,
                            ),
                            // Small role badge positioned slightly outside to avoid blocking the face
                            Positioned(
                              left: -6,
                              top: -6,
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: Colors.black87,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  role.substring(0, 1).toUpperCase(),
                                  style: GoogleFonts.lato(
                                    fontSize: 9,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              right: -1,
                              bottom: -1,
                              child: StreamBuilder<UserPresenceStatus>(
                                stream: PresenceService.getUserPresenceStream(
                                  u.id,
                                ),
                                builder: (context, snap) {
                                  final online = snap.data?.isOnline == true;
                                  if (!online) return const SizedBox.shrink();
                                  return Container(
                                    width: 11,
                                    height: 11,
                                    decoration: BoxDecoration(
                                      color: Colors.greenAccent,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 1.5,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              u.displayName,
                              style: GoogleFonts.lato(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(
                                  role,
                                  style: GoogleFonts.lato(
                                    color: HexColor.fromHex('9CA3AF'),
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Presence status text only (dot shown on avatar overlay)
                                StreamBuilder<UserPresenceStatus>(
                                  stream: PresenceService.getUserPresenceStream(
                                    u.id,
                                  ),
                                  builder: (context, snap) {
                                    final pres = snap.data;
                                    final online = pres?.isOnline ?? false;
                                    return Text(
                                      pres?.displayText ?? 'Offline',
                                      style: GoogleFonts.lato(
                                        fontSize: 11,
                                        color: online
                                            ? Colors.green
                                            : HexColor.fromHex('9CA3AF'),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          );
        },
      ),
    ),
    isScrollControlled: false,
    maxHeightFactor: 0.38,
  );
}

// Fetch actual user details from Firestore instead of placeholder names.
// Uses OtherUserDetailsService for consistent user data across the app.
Future<List<UserInfo>> batchedUserFetch(List<String> ids) async {
  final detailsService = OtherUserDetailsService.instance;
  final futures = ids.map((id) async {
    try {
      final details = await detailsService.getUserDetails(id);
      if (details == null) {
        return UserInfo(id: id, displayName: 'Unknown', email: id);
      }
      final displayName = details.displayName;
      final email = details.email ?? '';
      // Seed cache so future maybeGet works
      final info = UserInfo(id: id, displayName: displayName, email: email);
      UserService.seed(info);
      return info;
    } catch (_) {
      return UserInfo(id: id, displayName: 'Unknown', email: id);
    }
  });
  return Future.wait(futures);
}

String roleFor(ShoppingList list, String userId) {
  if (userId == list.createdBy) return 'owner';
  return list.memberRoles[userId] ?? 'member';
}
