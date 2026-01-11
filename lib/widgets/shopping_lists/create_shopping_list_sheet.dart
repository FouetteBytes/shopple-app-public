// Project/task themed shopping list creation bottom sheet (clean rebuilt)
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shopple/values/values.dart';
import 'package:shopple/widgets/adaptive/keyboard_adaptive_body.dart';
import 'package:shopple/widgets/pickers/color_picker_widget.dart';
import 'package:shopple/widgets/unified_profile_avatar.dart';
import 'package:shopple/services/presence/presence_service.dart';
import 'package:shopple/models/user_presence_status.dart';
import 'package:shopple/bottom_sheets/bottom_sheets.dart';
import 'package:shopple/widgets/common/liquid_glass.dart';
import 'package:shopple/widgets/common/liquid_text_field.dart';
import 'package:shopple/models/budget/budget_cadence.dart';
import 'package:shopple/models/budget/budget_period.dart';
import '../../services/shopping_lists/shopping_list_service.dart';
import '../../services/shopping_lists/shopping_list_cache.dart';
import '../../models/shopping_lists/shopping_list_model.dart';
import 'package:firebase_auth/firebase_auth.dart'
    hide UserInfo; // hide Firebase's UserInfo to avoid clash with local model
import '../../services/friends/friend_service.dart';
import '../common/date_range_picker.dart';
import 'package:shopple/utils/app_logger.dart';

import 'package:shopple/constants/shopping_list_icons.dart';
import 'package:shopple/widgets/shopping_lists/components/shopping_list_icon_picker.dart';

import 'package:shopple/widgets/shopping_lists/components/shopping_list_member_selector.dart';

class CreateShoppingListSheet extends StatefulWidget {
  const CreateShoppingListSheet({super.key});
  @override
  State<CreateShoppingListSheet> createState() =>
      _CreateShoppingListSheetState();
}

class _CreateShoppingListSheetState extends State<CreateShoppingListSheet> {
  final List<dynamic> _assignedFriends = []; // Store actual friend objects
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController();
  bool _submitting = false;
  String _colorHex = '#4CAF50';
  String _iconId = 'shopping_cart';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _hasBudget = false;
  BudgetCadence _budgetCadence = BudgetCadence.none;
  DateTime _budgetAnchor = DateTime.now();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');
      final budgetLimit = double.tryParse(_budgetController.text.trim()) ?? 0.0;
      final cadence = budgetLimit > 0 ? _budgetCadence : BudgetCadence.none;
      final period = budgetLimit > 0 ? _currentBudgetPeriod() : null;
      final anchor = period?.start ?? _budgetAnchor;

      // Prepare actual member data based on assigned friends
      final memberIds = <String>[
        currentUser.uid,
      ]; // Always include current user as owner
      final memberRoles = <String, String>{currentUser.uid: 'owner'};

      // Add assigned friends to the member lists
      for (final friend in _assignedFriends) {
        memberIds.add(friend.userId);
        memberRoles[friend.userId] = 'member'; // Default role for added friends
      }

      final now = DateTime.now();
      final id = await ShoppingListService.createShoppingList(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        iconId: _iconId,
        colorTheme: _colorHex,
        budgetLimit: budgetLimit,
        budgetCadence: cadence,
        budgetAnchor: anchor,
        memberIds: memberIds,
        memberRoles: memberRoles,
        startDate: _startDate,
        endDate: _endDate,
      );

      // Optimistic local insert so list appears immediately with correct blank state
      final optimistic = ShoppingList(
        id: id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        iconId: _iconId,
        colorTheme: _colorHex,
        createdBy: currentUser.uid,
        createdAt: now,
        updatedAt: now,
        lastActivity: now,
        budgetLimit: budgetLimit,
        budgetCadence: cadence,
        budgetAnchor: anchor,
        memberIds: memberIds,
        memberRoles: memberRoles,
        startDate: _startDate,
        endDate: _endDate,
      );

      ShoppingListCache.instance.optimisticInsert(optimistic);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _onBudgetChanged(String value) {
    final amount = double.tryParse(value.trim()) ?? 0.0;
    final hasBudget = amount > 0;
    if (hasBudget == _hasBudget) {
      return;
    }
    setState(() {
      _hasBudget = hasBudget;
      if (!hasBudget) {
        _budgetCadence = BudgetCadence.none;
      } else if (_budgetCadence == BudgetCadence.none) {
        _budgetCadence = BudgetCadence.oneTime;
        _budgetAnchor = DateTime.now();
      }
    });
  }

  void _selectBudgetCadence(BudgetCadence cadence) {
    setState(() {
      _budgetCadence = cadence;
      final now = DateTime.now();
      switch (cadence) {
        case BudgetCadence.none:
        case BudgetCadence.oneTime:
          _budgetAnchor = now;
          break;
        case BudgetCadence.weekly:
          _budgetAnchor = _startOfWeek(now);
          break;
        case BudgetCadence.monthly:
          _budgetAnchor = DateTime(now.year, now.month, 1);
          break;
      }
    });
  }

  BudgetPeriod? _currentBudgetPeriod() {
    if (!_hasBudget) return null;
    final normalizedAnchor = DateTime(
      _budgetAnchor.year,
      _budgetAnchor.month,
      _budgetAnchor.day,
    );
    switch (_budgetCadence) {
      case BudgetCadence.none:
        return null;
      case BudgetCadence.oneTime:
        return BudgetPeriod(
          start: normalizedAnchor,
          end: null,
          cadence: BudgetCadence.oneTime,
        );
      case BudgetCadence.weekly:
        final start = _startOfWeek(normalizedAnchor);
        return BudgetPeriod(
          start: start,
          end: start.add(const Duration(days: 7)),
          cadence: BudgetCadence.weekly,
        );
      case BudgetCadence.monthly:
        final start = DateTime(normalizedAnchor.year, normalizedAnchor.month);
        final end = DateTime(start.year, start.month + 1);
        return BudgetPeriod(
          start: start,
          end: end,
          cadence: BudgetCadence.monthly,
        );
    }
  }

  DateTime _startOfWeek(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return normalized.subtract(Duration(days: normalized.weekday - 1));
  }

  @override
  Widget build(BuildContext context) {
    final periodPreview = _currentBudgetPeriod();
    final accentColor = HexColor.fromHex(_colorHex.replaceFirst('#', ''));
    final form = Form(
      key: _formKey,
      child: Column(
        children: [
          const KbGap(10, minSize: 4),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderFields(),
                const KbGap(20, minSize: 10),
                LiquidTextField(
                  controller: _descriptionController,
                  maxLines: 2,
                  hintText: 'Description (optional)',
                  accentColor: accentColor,
                ),
                const KbGap(20, minSize: 12),
                Text(
                  'DATE RANGE (OPTIONAL)',
                  style: GoogleFonts.lato(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const KbGap(10, minSize: 6),
                _dateRangeSelector(context),
                const KbGap(20, minSize: 12),
                Text(
                  'BUDGET (OPTIONAL)',
                  style: GoogleFonts.lato(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const KbGap(10, minSize: 6),
                LiquidTextField(
                  controller: _budgetController,
                  keyboardType: TextInputType.number,
                  hintText: 'Enter budget limit (Rs)',
                  accentColor: accentColor,
                  onChanged: _onBudgetChanged,
                  prefixIcon: Icon(
                    Icons.account_balance_wallet_outlined,
                    color: accentColor,
                  ),
                ),
                if (_hasBudget) ...[
                  const KbGap(12, minSize: 8),
                  Text(
                    'BUDGET CADENCE',
                    style: GoogleFonts.lato(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const KbGap(10, minSize: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        [
                          BudgetCadence.oneTime,
                          BudgetCadence.weekly,
                          BudgetCadence.monthly,
                        ].map((cadence) {
                          return ChoiceChip(
                            label: Text(
                              cadence.displayLabel,
                              style: GoogleFonts.lato(color: Colors.white),
                            ),
                            selected: _budgetCadence == cadence,
                            selectedColor: accentColor.withValues(alpha: 0.2),
                            backgroundColor: HexColor.fromHex('181A1F'),
                            onSelected: (_) => _selectBudgetCadence(cadence),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(
                              color: _budgetCadence == cadence
                                  ? accentColor
                                  : HexColor.fromHex('343840'),
                            ),
                          );
                        }).toList(),
                  ),
                  const KbGap(8, minSize: 6),
                  if (periodPreview != null)
                    Text(
                      'Current period: ${periodPreview.formattedLabel()}',
                      style: GoogleFonts.lato(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                ],
                const KbGap(20, minSize: 12),
                Text(
                  'ASSIGN PEOPLE (OPTIONAL)',
                  style: GoogleFonts.lato(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const KbGap(10, minSize: 6),
                _buildAssignPeoplePlaceholder(),
                const KbGap(20, minSize: 12),
                Text(
                  'COLOR THEME',
                  style: GoogleFonts.lato(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const KbGap(10, minSize: 6),
                ColorPickerWidget(
                  selectedColor: _colorHex,
                  onColorSelected: (hex) => setState(() => _colorHex = hex),
                ),
                const KbGap(20, minSize: 12),
                Text(
                  'ICON',
                  style: GoogleFonts.lato(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const KbGap(10, minSize: 6),
                _iconPickerLauncher(),
                const KbGap(40, minSize: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: HexColor.fromHex(
                        _colorHex.replaceFirst('#', ''),
                      ),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Create List',
                            style: GoogleFonts.lato(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    return KeyboardAdaptiveBody(
      padding: const EdgeInsets.only(bottom: 12),
      scrollWhenKeyboardOnly: true,
      child: form,
    );
  }

  Widget _iconPickerLauncher() {
    return InkWell(
      onTap: _openFullIconBrowser,
      borderRadius: BorderRadius.circular(16),
      child: LiquidGlass(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        borderRadius: 16,
        enableBlur: true,
        gradientColors: [
          Colors.white.withValues(alpha: 0.05),
          Colors.white.withValues(alpha: 0.02),
        ],
        borderColor: Colors.white.withValues(alpha: 0.1),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: HexColor.fromHex('24272F'),
                border: Border.all(color: HexColor.fromHex('343840')),
              ),
              child: Icon(
                _resolveIcon(_iconId),
                color: HexColor.fromHex(_colorHex.replaceFirst('#', '')),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Browse & search icons',
                style: GoogleFonts.lato(color: Colors.white70, fontSize: 14),
              ),
            ),
            Icon(
              Icons.search,
              color: HexColor.fromHex(_colorHex.replaceFirst('#', '')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateRangeSelector(BuildContext context) {
    final display = _startDate == null
        ? 'Set dates'
        : (_endDate == null
              ? _formatShort(_startDate!)
              : '${_formatShort(_startDate!)} - ${_formatShort(_endDate!)}');
    return InkWell(
      onTap: _openUnifiedPicker,
      borderRadius: BorderRadius.circular(14),
      child: LiquidGlass(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        borderRadius: 14,
        enableBlur: true,
        gradientColors: [
          Colors.white.withValues(alpha: 0.05),
          Colors.white.withValues(alpha: 0.02),
        ],
        borderColor: Colors.white.withValues(alpha: 0.1),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              color: HexColor.fromHex(_colorHex.replaceFirst('#', '')),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                display,
                style: GoogleFonts.lato(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              'Change',
              style: GoogleFonts.lato(
                color: HexColor.fromHex(_colorHex.replaceFirst('#', '')),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatShort(DateTime d) {
    const m = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${d.day} ${m[d.month - 1]}';
  }

  void _openUnifiedPicker() {
    final themeColor = HexColor.fromHex(_colorHex.replaceFirst('#', ''));
    showModernDateRangePickerSheet(
      context,
      themeColor: themeColor,
      initialStart: _startDate,
      initialEnd: _endDate,
    ).then((res) {
      if (res == null) return;
      setState(() {
        _startDate = res.start;
        _endDate = res.end;
      });
    });
  }

  void _openFullIconBrowser() {
    final searchCtrl = TextEditingController();
    int page = 0;
    const int pageSize = 60; // icons per page

    showAppBottomSheet(
      StatefulBuilder(
        builder: (ctx, setSheet) {
          final query = searchCtrl.text.toLowerCase();
          final allFiltered = ShoppingListIcons.all.where((i) {
            if (query.isEmpty) return true;
            return i.toString().toLowerCase().contains(query);
          }).toList();
          final visibleCount = ((page + 1) * pageSize).clamp(
            0,
            allFiltered.length,
          );
          final filtered = allFiltered.take(visibleCount).toList();
          return Column(
            children: [
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                child: LiquidTextField(
                  controller: searchCtrl,
                  onChanged: (_) {
                    page = 0;
                    setSheet(() {});
                  },
                  hintText: 'Search icons...',
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Colors.white54,
                  ),
                  accentColor: HexColor.fromHex(_colorHex.replaceFirst('#', '')),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _modernIconGridCustom(filtered, setSheet),
                      const SizedBox(height: 12),
                      if (visibleCount < allFiltered.length)
                        TextButton(
                          onPressed: () => setSheet(() {
                            page++;
                          }),
                          child: Text(
                            'Load more (${allFiltered.length - visibleCount} more)',
                            style: GoogleFonts.lato(
                              color: HexColor.fromHex(
                                _colorHex.replaceFirst('#', ''),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: HexColor.fromHex(
                          _colorHex.replaceFirst('#', ''),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Done',
                        style: GoogleFonts.lato(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      title: 'Browse Icons',
      isScrollControlled: true,
      height: MediaQuery.of(context).size.height * 0.82,
    );
  }

  Widget _buildHeaderFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LiquidTextField(
          controller: _nameController,
          hintText: 'List name',
          accentColor: HexColor.fromHex(_colorHex.replaceFirst('#', '')),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Name required';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildAssignPeoplePlaceholder() {
    // Show current user as owner + add button for friends + any assigned
    final currentUser = FirebaseAuth.instance.currentUser;

    return FutureBuilder<Map<String, dynamic>?>(
      future: _getCurrentUserInfo(),
      builder: (context, snap) {
        final avatars = <Widget>[];

        // Add current user as owner
        if (snap.hasData && snap.data != null) {
          final userData = snap.data!;
          final displayName = userData['displayName'] ?? 'You';
          final userId = userData['userId'] ?? '';
          avatars.add(_avatarChip(displayName, userId, isOwner: true));
        } else if (currentUser != null) {
          // Fallback to Firebase Auth data
          final displayName = currentUser.displayName ?? 'You';
          avatars.add(_avatarChip(displayName, currentUser.uid, isOwner: true));
        }

        // Add assigned friends
        for (final friend in _assignedFriends) {
          avatars.add(_avatarChip(friend.displayName, friend.userId));
        }

        // Add friends button
        avatars.add(_addFriendsButton());

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: avatars
                .map(
                  (w) => Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: w,
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>?> _getCurrentUserInfo() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return null;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;

        // Build proper display name
        String displayName = currentUser.displayName ?? 'You';
        final firstName = userData['firstName'] as String?;
        final lastName = userData['lastName'] as String?;

        if (firstName != null && firstName.isNotEmpty) {
          if (lastName != null && lastName.isNotEmpty) {
            displayName = '$firstName $lastName';
          } else {
            displayName = firstName;
          }
        }

        return {
          'userId': currentUser.uid,
          'displayName': displayName,
          'email': userData['email'] ?? currentUser.email,
          'photoURL':
              userData['customPhotoURL'] ??
              userData['photoURL'] ??
              currentUser.photoURL,
        };
      }
    } catch (e) {
      AppLogger.e('Error fetching user info: $e');
    }

    return {
      'userId': currentUser.uid,
      'displayName': currentUser.displayName ?? 'You',
      'email': currentUser.email,
      'photoURL': currentUser.photoURL,
    };
  }

  Widget _avatarChip(String label, String id, {bool isOwner = false}) {
    return LiquidGlass(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      borderRadius: 40,
      enableBlur: true,
      gradientColors: [
        Colors.white.withValues(alpha: 0.08),
        Colors.white.withValues(alpha: 0.04),
      ],
      borderColor: Colors.white.withValues(alpha: 0.1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              SizedBox(
                width: 32,
                height: 32,
                child: UnifiedProfileAvatar(
                  userId: id,
                  radius: 16,
                  enableCache: true,
                ),
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: StreamBuilder<UserPresenceStatus>(
                  stream: PresenceService.getUserPresenceStream(id),
                  builder: (context, snap) {
                    final online = snap.data?.isOnline == true;
                    if (!online) return const SizedBox.shrink();
                    return Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: Colors.greenAccent,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.2),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(width: 6),
          Text(
            label.split(' ').first,
            style: GoogleFonts.lato(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _addFriendsButton() {
    return InkWell(
      onTap: _showAddFriendsDialog,
      borderRadius: BorderRadius.circular(30),
      child: SizedBox(
        width: 44,
        height: 44,
        child: LiquidGlass(
          borderRadius: 22,
          enableBlur: true,
          gradientColors: [
            Colors.white.withValues(alpha: 0.08),
            Colors.white.withValues(alpha: 0.04),
          ],
          borderColor: Colors.white.withValues(alpha: 0.1),
          child: Icon(Icons.add, color: AppColors.primaryAccentColor),
        ),
      ),
    );
  }

  void _showAddFriendsDialog() async {
    try {
      // Get user's friends using the existing FriendService
      final friendsStream = FriendService.getFriendsStream();
      final friends = await friendsStream.first;

      if (friends.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'You have no friends to add. Add some friends first!',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Show friend selection dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => ShoppingListMemberSelector(
            friends: friends,
            onFriendsSelected: (selectedFriends) {
              setState(() {
                // Add selected friends to the assigned list
                for (final friend in selectedFriends) {
                  if (!_assignedFriends.any((f) => f.userId == friend.userId)) {
                    _assignedFriends.add(friend);
                  }
                }
              });
            },
            currentlyAssigned: _assignedFriends
                .map((f) => f.displayName.toString())
                .toList(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading friends: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _modernIconGridCustom(List<IconData> icons, StateSetter setSheet) {
    return ShoppingListIconPicker(
      selectedIconId: _iconId,
      onIconSelected: (id) {
        setSheet(() {
          _iconId = id;
        });
      },
      selectedColor: HexColor.fromHex(_colorHex.replaceFirst('#', '')),
    );
  }

  IconData _resolveIcon(String id) {
    final code = int.tryParse(id);
    if (code != null) {
      for (final icon in ShoppingListIcons.all) {
        if (icon.codePoint == code) return icon;
      }
    }
    switch (id) {
      case 'shopping_cart':
        return Icons.shopping_cart;
      default:
        return Icons.shopping_cart;
    }
  }
}

// Friend Selection Dialog Widget

