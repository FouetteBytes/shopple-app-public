import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../animated_diff_number.dart';
import '../../../models/shopping_lists/shopping_list_model.dart';
import '../../common/liquid_glass.dart';
import 'budget_ring.dart';
import 'collaborator_action_row.dart';
import '../../../values/values.dart';

/// Ultra-compact, modern header used inside the shopping list detail screen.
class ModernListHeader extends StatelessWidget {
  final ShoppingList list;
  final int completedItems;
  final int totalItems;
  final double percentComplete;
  final double displayedEstimate;
  final double budgetLimit;
  final double budgetRemaining;
  final bool overBudget;
  final double projectedOver;
  final Widget? statusChip;
  final List<Widget> extraBadges;
  final List<Widget> quickActions;
  final Widget activityFeed;
  final VoidCallback onShareTap;
  final VoidCallback onActivityTap;
  final VoidCallback onHistoryTap;
  final VoidCallback onManageMembersTap;
  final String? description;

  const ModernListHeader({
    super.key,
    required this.list,
    required this.completedItems,
    required this.totalItems,
    required this.percentComplete,
    required this.displayedEstimate,
    required this.budgetLimit,
    required this.budgetRemaining,
    required this.overBudget,
    required this.projectedOver,
    required this.statusChip,
    required this.extraBadges,
    required this.quickActions,
    required this.activityFeed,
    required this.onShareTap,
    required this.onActivityTap,
    required this.onHistoryTap,
    required this.onManageMembersTap,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = list.themeColor;
    final totalText = '$completedItems/$totalItems';
    final hasQuickActions =
        (statusChip != null) ||
        extraBadges.isNotEmpty ||
        quickActions.isNotEmpty;

    return LiquidGlass(
      borderRadius: 16,
      enableBlur: true,
      blurSigmaX: 10,
      blurSigmaY: 14,
      gradientColors: [
        themeColor.withValues(alpha: 0.12),
        HexColor.fromHex('2A2D35').withValues(alpha: 0.95),
      ],
      borderColor: Colors.white.withValues(alpha: 0.06),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Compact metrics row with progress + budget ring integrated
            _CompactMetricsRow(
              completedText: totalText,
              percentComplete: percentComplete,
              displayedEstimate: displayedEstimate,
              budgetLimit: budgetLimit,
              overBudget: overBudget,
              themeColor: themeColor,
            ),
            const SizedBox(height: 10),

            // Activity feed chip
            activityFeed,

            // Collaborator row (horizontally scrollable) or Share CTA
            if (list.isShared) ...[
              const SizedBox(height: 10),
              CollaboratorActionRow(
                key: const ValueKey('collaborator-row'),
                list: list,
                onActivityTap: onActivityTap,
                onHistoryTap: onHistoryTap,
                onManageMembersTap: onManageMembersTap,
                avatarRadius: 20,
              ),
            ] else ...[
              const SizedBox(height: 10),
              _CompactShareCTA(
                key: const ValueKey('share-cta'),
                onTap: onShareTap,
              ),
            ],

            // Quick actions in a single scrollable row
            if (hasQuickActions) ...[
              const SizedBox(height: 10),
              _UnifiedQuickActions(
                statusChip: statusChip,
                extraBadges: extraBadges,
                quickActions: quickActions,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Ultra-compact metrics row with progress bar and budget ring in a single line
class _CompactMetricsRow extends StatelessWidget {
  final String completedText;
  final double percentComplete;
  final double displayedEstimate;
  final double budgetLimit;
  final bool overBudget;
  final Color themeColor;

  const _CompactMetricsRow({
    required this.completedText,
    required this.percentComplete,
    required this.displayedEstimate,
    required this.budgetLimit,
    required this.overBudget,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    final showBudget = budgetLimit > 0;

    return Row(
      children: [
        // Compact budget ring (only if budget exists)
        if (showBudget) ...[
          BudgetRing(
            current: displayedEstimate,
            limit: budgetLimit,
            color: overBudget ? Colors.redAccent : themeColor,
          ),
          const SizedBox(width: 12),
        ],

        // Progress info and spend amount
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Progress text + Amount in one line
              Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 14,
                    color: AppColors.primaryAccentColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    completedText,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 14,
                    color: themeColor,
                  ),
                  const SizedBox(width: 6),
                  AnimatedDiffNumber(
                    value: displayedEstimate,
                    suffix: ' Rs',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutCubic,
                  tween: Tween(begin: 0, end: percentComplete.clamp(0.0, 1.0)),
                  builder: (context, value, _) {
                    return LinearProgressIndicator(
                      value: value,
                      minHeight: 6,
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                    );
                  },
                ),
              ),

              // Budget info below progress bar (if budget exists)
              if (showBudget) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      'Budget: ',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.white54,
                      ),
                    ),
                    AnimatedDiffNumber(
                      value: displayedEstimate,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: overBudget
                            ? Colors.redAccent
                            : Colors.greenAccent,
                      ),
                    ),
                    Text(
                      ' / ',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.white54,
                      ),
                    ),
                    AnimatedDiffNumber(
                      value: budgetLimit,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                      ),
                    ),
                    if (overBudget) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.warning_amber_rounded,
                        size: 12,
                        color: Colors.redAccent,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Over!',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ] else ...[
                      const SizedBox(width: 8),
                      AnimatedDiffNumber(
                        value: (budgetLimit - displayedEstimate).clamp(
                          0,
                          double.infinity,
                        ),
                        suffix: ' left',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.lightGreenAccent,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Compact share CTA that doesn't take much vertical space
class _CompactShareCTA extends StatelessWidget {
  final VoidCallback onTap;

  const _CompactShareCTA({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              AppColors.primaryAccentColor.withValues(alpha: 0.15),
              AppColors.primaryAccentColor.withValues(alpha: 0.08),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          border: Border.all(
            color: AppColors.primaryAccentColor.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.group_add_rounded,
              color: AppColors.primaryAccentColor,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Share to collaborate',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.primaryAccentColor,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}

/// Unified quick actions row with consistent styling
class _UnifiedQuickActions extends StatelessWidget {
  final Widget? statusChip;
  final List<Widget> extraBadges;
  final List<Widget> quickActions;

  const _UnifiedQuickActions({
    required this.statusChip,
    required this.extraBadges,
    required this.quickActions,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          if (statusChip != null) ...[statusChip!, const SizedBox(width: 8)],
          ...extraBadges.map(
            (badge) =>
                Padding(padding: const EdgeInsets.only(right: 8), child: badge),
          ),
          ...quickActions.map(
            (action) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: action,
            ),
          ),
        ],
      ),
    );
  }
}
