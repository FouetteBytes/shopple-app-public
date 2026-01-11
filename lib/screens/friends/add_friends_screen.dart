import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/friends/friend_service.dart';
import '../../services/user/user_search_service.dart';
import '../../models/contact_models.dart';
import '../../values/values.dart';
import '../../widgets/search/search_result_tile.dart';
import '../../widgets/common/liquid_glass.dart';

import 'package:shopple/widgets/common/liquid_glass_button.dart';

class AddFriendsScreen extends StatefulWidget {
  const AddFriendsScreen({super.key});

  @override
  State<AddFriendsScreen> createState() => _AddFriendsScreenState();
}

class _AddFriendsScreenState extends State<AddFriendsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<UserSearchResult> _searchResults = [];
  List<UserSearchResult> _suggestions = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  bool _showSuggestions = false;
  
  // Cache button states.
  final Map<String, String> _buttonStateCache = {};

  @override
  void initState() {
    super.initState();
    
    // Preload user data.
    UserSearchService.preloadRecentUsers();
    
    // Listen to search changes.
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchFocusNode.removeListener(_onFocusChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text;
    _performInstantSearch(query);
    _loadSuggestions(query);
  }

  void _onFocusChanged() {
    setState(() {
      _showSuggestions = _searchFocusNode.hasFocus && 
          _searchController.text.isNotEmpty && 
          _suggestions.isNotEmpty;
    });
  }

  Future<void> _loadSuggestions(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }
    
    final suggestions = await UserSearchService.getSuggestions(query, limit: 5);
    if (mounted && _searchController.text == query) {
      setState(() {
        _suggestions = suggestions;
        _showSuggestions = _searchFocusNode.hasFocus && suggestions.isNotEmpty;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(
          'Add Friends',
          style: GoogleFonts.lato(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildSearchSection(),
          Expanded(child: _buildSearchResults()),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          _buildSearchBar(),
          if (_showSuggestions) _buildSuggestionsOverlay(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return LiquidGlass(
      borderRadius: 14,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      gradientColors: [
        Colors.white.withValues(alpha: 0.08),
        Colors.white.withValues(alpha: 0.04),
      ],
      child: Row(
        children: [
          Icon(
            Icons.search,
            color: _searchFocusNode.hasFocus 
                ? AppColors.primaryAccentColor 
                : Colors.grey[400],
          ),
          SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              style: GoogleFonts.lato(color: Colors.white, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Search by name, email, or phone...',
                hintStyle: GoogleFonts.lato(color: Colors.grey[500], fontSize: 15),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          if (_isSearching)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.primaryAccentColor,
                ),
              ),
            )
          else if (_searchController.text.isNotEmpty)
            IconButton(
              icon: Icon(Icons.clear, color: Colors.grey[400], size: 20),
              onPressed: _clearSearch,
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(minWidth: 32, minHeight: 32),
            ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsOverlay() {
    return Container(
      margin: EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _suggestions.map((suggestion) {
            return SearchSuggestionTile(
              user: suggestion,
              query: _searchController.text,
              onTap: () {
                _searchController.text = suggestion.name;
                _searchFocusNode.unfocus();
                _performInstantSearch(suggestion.name);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchResults.clear();
      _suggestions.clear();
      _hasSearched = false;
      _showSuggestions = false;
    });
  }

  Widget _buildSearchResults() {
    if (!_hasSearched) {
      return _buildEmptyState();
    }

    if (_isSearching && _searchResults.isEmpty) {
      return SearchResultShimmer(itemCount: 5);
    }

    if (_searchResults.isEmpty) {
      return _buildNoResults();
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 20),
      physics: BouncingScrollPhysics(),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        return _buildUserTile(user);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primaryAccentColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_add_alt_1_rounded,
                size: 48,
                color: AppColors.primaryAccentColor,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Find Friends',
              style: GoogleFonts.lato(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Start typing to search for friends by name, email, or phone number.',
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                color: Colors.grey[400],
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_search_rounded,
                size: 48,
                color: Colors.orange,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'No Users Found',
              style: GoogleFonts.lato(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Try a different search term or check the spelling.',
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                color: Colors.grey[400],
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserTile(UserSearchResult user) {
    return SearchResultTile(
      user: user,
      matchScore: user.matchScore,
      showPrivacyMasking: true,
      trailing: _buildCachedActionButton(user),
    );
  }

  Widget _buildCachedActionButton(UserSearchResult user) {
    // Use cached state if available for instant display
    final cachedState = _buttonStateCache[user.uid];
    
    if (cachedState != null) {
      return _buildActionButton(cachedState, user);
    }

    return FutureBuilder<String>(
      future: _getButtonState(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            width: 60,
            height: 32,
            child: Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primaryAccentColor,
                  ),
                ),
              ),
            ),
          );
        }

        final state = snapshot.data ?? 'add';
        // Cache the state
        _buttonStateCache[user.uid] = state;
        
        return _buildActionButton(state, user);
      },
    );
  }

  Widget _buildActionButton(String state, UserSearchResult user) {
    switch (state) {
      case 'add':
        return _buildStyledButton(
          label: 'Add',
          color: AppColors.primaryAccentColor,
          onPressed: () => _sendFriendRequest(user),
        );

      case 'sent':
        return _buildStyledButton(
          label: 'Sent',
          color: Colors.grey[600]!,
          onPressed: null,
        );

      case 'friends':
        return _buildStyledButton(
          label: 'Friends',
          color: Colors.green[600]!,
          icon: Icons.check,
          onPressed: null,
        );

      case 'accept':
        return _buildStyledButton(
          label: 'Accept',
          color: Colors.green[600]!,
          onPressed: () => _acceptFriendRequest(user.uid),
        );

      default:
        return SizedBox.shrink();
    }
  }

  Widget _buildStyledButton({
    required String label,
    required Color color,
    VoidCallback? onPressed,
    IconData? icon,
  }) {
    return Container(
      constraints: const BoxConstraints(minWidth: 70),
      child: LiquidGlassGradientButton(
        onTap: onPressed,
        gradientColors: [color, color.withValues(alpha: 0.8)],
        borderRadius: 8,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        isDisabled: onPressed == null,
        customChild: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: Colors.white),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: GoogleFonts.lato(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Real-time instant search.
  void _performInstantSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults.clear();
        _hasSearched = false;
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _hasSearched = true;
    });

    try {
      // Use the advanced UserSearchService with instant search
      List<UserSearchResult> results = await UserSearchService.instantSearch(
        query,
        limit: 20,
        onStreamResults: (streamResults) {
          // Update UI with streaming results for ultra-fast UX
          if (mounted && _searchController.text == query) {
            setState(() {
              _searchResults = streamResults;
              _isSearching = false;
            });
          }
        },
      );

      if (mounted && _searchController.text == query) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  Future<String> _getButtonState(String userId) async {
    try {
      // Check if already friends
      final isFriend = await FriendService.isFriend(userId);
      if (isFriend) return 'friends';

      // Check if request already sent
      final hasSentRequest = await FriendService.hasSentFriendRequest(userId);
      if (hasSentRequest) return 'sent';

      // Check if received request from this user
      final hasReceivedRequest = await FriendService.hasReceivedFriendRequest(userId);
      if (hasReceivedRequest) return 'accept';

      return 'add';
    } catch (e) {
      return 'add';
    }
  }

  void _sendFriendRequest(UserSearchResult user) async {
    // Update cache immediately for instant feedback
    setState(() {
      _buttonStateCache[user.uid] = 'sent';
    });

    try {
      await FriendService.sendFriendRequest(
        targetUserId: user.uid,
        targetUserName: user.name,
        targetUserEmail: user.email ?? '',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Text('Friend request sent!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      // Revert cache on error
      setState(() {
        _buttonStateCache[user.uid] = 'add';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending friend request'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _acceptFriendRequest(String userId) async {
    // Update cache immediately
    setState(() {
      _buttonStateCache[userId] = 'friends';
    });

    try {
      await FriendService.acceptFriendRequestByUserId(userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.celebration, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Text('Friend request accepted!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      // Revert cache on error
      setState(() {
        _buttonStateCache[userId] = 'accept';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error accepting friend request'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
