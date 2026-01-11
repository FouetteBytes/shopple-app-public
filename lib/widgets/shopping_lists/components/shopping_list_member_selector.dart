import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopple/widgets/common/liquid_glass.dart';
import 'package:shopple/widgets/unified_profile_avatar.dart';
import 'package:shopple/services/presence/presence_service.dart';
import 'package:shopple/models/user_presence_status.dart';
import 'package:shopple/services/user/user_profile_stream_service.dart';
import 'package:shopple/values/values.dart';

class ShoppingListMemberSelector extends StatefulWidget {
  final List<dynamic> friends; // Using dynamic to handle the Friend model
  final Function(List<dynamic>) onFriendsSelected;
  final List<String> currentlyAssigned;

  const ShoppingListMemberSelector({
    super.key,
    required this.friends,
    required this.onFriendsSelected,
    required this.currentlyAssigned,
  });

  @override
  State<ShoppingListMemberSelector> createState() => _ShoppingListMemberSelectorState();
}

class _ShoppingListMemberSelectorState extends State<ShoppingListMemberSelector> {
  final Set<dynamic> _selectedFriends = {};
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  Timer? _prefetchDebounce;

  @override
  void dispose() {
    _prefetchDebounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: LiquidGlass(
        borderRadius: 20,
        enableBlur: true,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Add Friends to List',
                    style: GoogleFonts.lato(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Telegram-like quick search
              TextField(
                controller: _searchCtrl,
                onChanged: (v) {
                  setState(() => _query = v.trim().toLowerCase());
                  // Debounced prefetch on search input to warm upcoming results
                  _prefetchDebounce?.cancel();
                  _prefetchDebounce = Timer(
                    const Duration(milliseconds: 180),
                    () {
                      _prefetchVisibleFriends();
                    },
                  );
                },
                style: GoogleFonts.lato(color: Colors.white),
                cursorColor: Colors.white70,
                decoration: InputDecoration(
                  hintText: 'Search friends...',
                  hintStyle: GoogleFonts.lato(color: Colors.white38),
                  prefixIcon: const Icon(Icons.search, color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.08),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _buildFriendsList(),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onFriendsSelected(_selectedFriends.toList());
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryAccentColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    'Add ${_selectedFriends.length} Friends',
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFriendsList() {
    final filtered = widget.friends.where((f) {
      final name = f.displayName.toString().toLowerCase();
      return name.contains(_query);
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Text(
          'No friends found',
          style: GoogleFonts.lato(color: Colors.white54),
        ),
      );
    }

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final friend = filtered[index];
        final isSelected = _selectedFriends.contains(friend);
        final isAlreadyAssigned = widget.currentlyAssigned.contains(friend.displayName);

        return ListTile(
          onTap: isAlreadyAssigned
              ? null
              : () {
                  setState(() {
                    if (isSelected) {
                      _selectedFriends.remove(friend);
                    } else {
                      _selectedFriends.add(friend);
                    }
                  });
                },
          leading: Stack(
            children: [
              UnifiedProfileAvatar(
                userId: friend.userId,
                radius: 20,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: StreamBuilder<UserPresenceStatus>(
                  stream: PresenceService.getUserPresenceStream(friend.userId),
                  builder: (context, snapshot) {
                    final isOnline = snapshot.data?.isOnline == true;
                    return Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: isOnline ? Colors.green : Colors.grey,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 1.5),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          title: Text(
            friend.displayName,
            style: GoogleFonts.lato(
              color: isAlreadyAssigned ? Colors.white38 : Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            isAlreadyAssigned ? 'Already added' : (friend.email ?? ''),
            style: GoogleFonts.lato(color: Colors.white38, fontSize: 12),
          ),
          trailing: isAlreadyAssigned
              ? const Icon(Icons.check, color: Colors.white38)
              : Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? AppColors.primaryAccentColor : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? AppColors.primaryAccentColor : Colors.white38,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
        );
      },
    );
  }

  void _prefetchVisibleFriends() {
    final filtered = widget.friends.where((f) {
      final name = (f.displayName ?? '').toString().toLowerCase();
      final email = (f.email ?? '').toString().toLowerCase();
      if (_query.isEmpty) return true;
      return name.contains(_query) || email.contains(_query);
    }).toList();
    
    final ids = filtered
        .map((f) => f.userId)
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet();
        
    if (ids.isEmpty) return;
    // Fire and forget warming; the centralized service will dedupe subscriptions
    UserProfileStreamService.instance.prefetchUsers(ids);
  }
}
