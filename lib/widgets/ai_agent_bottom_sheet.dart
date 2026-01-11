import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shopple/controllers/ai_agent_controller.dart';
import 'package:shopple/values/values.dart';
import 'package:shopple/services/shopping_lists/shopping_list_cache.dart';
import 'package:shopple/screens/shopping_lists/list_detail_screen.dart';
import 'package:shopple/widgets/common/liquid_snack.dart';
import 'package:shopple/widgets/common/liquid_glass.dart';
import 'package:shopple/widgets/common/liquid_glass_button.dart';
import 'package:shopple/widgets/common/liquid_text_field.dart';
import 'dart:ui';

class AIAgentBottomSheet extends StatefulWidget {
  const AIAgentBottomSheet({super.key});

  @override
  State<AIAgentBottomSheet> createState() => _AIAgentBottomSheetState();
}

class _AIAgentBottomSheetState extends State<AIAgentBottomSheet> {
  final _controller = TextEditingController();
  late AIAgentController _agent;
  bool _showHistory = false;

  @override
  void initState() {
    super.initState();
    _agent = Get.find<AIAgentController>();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _agent.isRunning) return;
    try {
      await _agent.runUserCommand(text);
      if (mounted) {
        setState(() {});
        final result = _agent.lastResult;
        if (result != null) {
          final added = result.addedItems.length;
          final failed = result.failures.length;
          if (added > 0 && failed == 0) {
            LiquidSnack.success(
              title: 'AI Session Complete',
              message: 'Successfully added $added item${added == 1 ? '' : 's'} to your list.',
            );
          } else if (added > 0 && failed > 0) {
            LiquidSnack.info(
              title: 'AI Session Complete',
              message: 'Added $added item${added == 1 ? '' : 's'}, but $failed failed.',
            );
          } else if (failed > 0) {
            LiquidSnack.error(
              title: 'AI Session Failed',
              message: 'Could not add $failed item${failed == 1 ? '' : 's'}.',
            );
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      LiquidSnack.error(
        title: 'Agent Error',
        message: 'Agent failed: $e',
      );
    }
  }

  void _openList() {
    final result = _agent.lastResult;
    if (result?.listId == null) return;
    final list = ShoppingListCache.instance.current.firstWhereOrNull(
      (l) => l.id == result!.listId,
    );
    if (list == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ListDetailScreen(shoppingList: list)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = _agent.lastResult;
    final addedCount = result?.addedItems.length ?? 0;
    final failCount = result?.failures.length ?? 0;

    return _ModernBlurSheet(
      child: LiquidGlass(
        enableBlur: true,
        borderRadius: 24,
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        gradientColors: [
          Colors.white.withValues(alpha: 0.15),
          Colors.white.withValues(alpha: 0.10),
        ],
        borderColor: Colors.white.withValues(alpha: 0.18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
        child: AnimatedBuilder(
          animation: _agent,
          builder: (context, _) {
            final statuses = _agent.itemStatuses;
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Modern handle
                  Center(
                    child: Container(
                      width: 48,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Header with AI branding
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryAccentColor.withValues(
                                alpha: 0.8,
                              ),
                              AppColors.lightMauveBackgroundColor.withValues(
                                alpha: 0.8,
                              ),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AI Shopping Assistant',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                            ),
                            Text(
                              'Smart list management & product discovery',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 12,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      if (_agent.isRunning)
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Input field
                  LiquidTextField(
                    controller: _controller,
                    maxLines: 3,
                    minLines: 1,
                    hintText:
                        'e.g. Create a new list called dinner and add a meat type and coca cola',
                  ),
                  const SizedBox(height: 16),
                  // Action buttons with modern loading
                  Row(
                    children: [
                      Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          child: LiquidGlassGradientButton(
                            onTap: _agent.isRunning ? null : _run,
                            gradientColors: [
                              AppColors.primaryAccentColor,
                              AppColors.primaryAccentColor.withValues(alpha: 0.8)
                            ],
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            customChild: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_agent.isRunning)
                                  const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                else
                                  const Icon(Icons.auto_awesome, size: 18, color: Colors.white),
                                const SizedBox(width: 8),
                                Text(
                                  _agent.isRunning ? 'Processing...' : 'Run AI',
                                  style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (_agent.isRunning) ...[
                        const SizedBox(width: 12),
                        LiquidGlassButton.primary(
                          onTap: _agent.cancelRequested
                              ? null
                              : _agent.requestCancel,
                          gradientColors: [
                            Colors.redAccent.withValues(alpha: 0.9),
                            Colors.redAccent.withValues(alpha: 0.7)
                          ],
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          text: _agent.cancelRequested ? 'Canceling...' : 'Cancel',
                        ),
                      ],
                      if (result?.listId != null) ...[
                        const SizedBox(width: 12),
                        LiquidGlassButton.text(
                          onTap: _openList,
                          text: 'View List',
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                        ),
                      ],
                    ],
                  ),
                  // Modern status chips with step indicators
                  if (statuses.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.timeline,
                                size: 18,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Processing Steps',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: statuses.entries.map((e) {
                              final statusInfo = _getStatusInfo(e.value);
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      statusInfo.color.withValues(alpha: 0.25),
                                      statusInfo.color.withValues(alpha: 0.15),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: statusInfo.color.withValues(
                                      alpha: 0.8,
                                    ),
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: statusInfo.color.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      statusInfo.icon,
                                      size: 14,
                                      color: statusInfo.color,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _truncate(e.key),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: statusInfo.color,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusInfo.color.withValues(
                                          alpha: 0.3,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        e.value,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                  // Results summary
                  if (result != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (addedCount > 0)
                          Text(
                            '$addedCount added',
                            style: const TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        if (failCount > 0) ...[
                          if (addedCount > 0) const SizedBox(width: 12),
                          Text(
                            '$failCount failed',
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                  // History toggle
                  Row(
                    children: [
                      LiquidGlassButton(
                        onTap: () => setState(() => _showHistory = !_showHistory),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _showHistory ? Icons.history_toggle_off : Icons.history,
                              size: 16,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _showHistory ? 'Hide History' : 'Show History',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // History view
                  if (_showHistory)
                    Container(
                      height: 120,
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: ListView.builder(
                        itemCount: _agent.history.length,
                        itemBuilder: (context, i) {
                          final h = _agent.history[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '${h['input']}: +${h['added']} -${h['failed']} (${(h['durationMs'] ?? 0)}ms)',
                              style: const TextStyle(
                                fontSize: 11,
                                height: 1.3,
                                color: Colors.white70,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        },
                      ),
                    ),
                  // Logs view
                  if (_agent.logs.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      height: 160,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: ListView.builder(
                        itemCount: _agent.logs.length,
                        itemBuilder: (context, index) {
                          final log = _agent.logs[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  log.success
                                      ? Icons.check_circle_outline
                                      : Icons.error_outline,
                                  size: 16,
                                  color: log.success
                                      ? Colors.greenAccent
                                      : Colors.redAccent,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${log.type}: ${log.description}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      height: 1.3,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  // Streaming preview
                  if (_agent.isRunning &&
                      _agent.streamingParsePreview.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Parsing (stream):',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white60,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxHeight: 80),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          _agent.streamingParsePreview,
                          style: const TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _truncate(String value, {int max = 18}) =>
      value.length <= max ? value : '${value.substring(0, max - 1)}…';

  _StatusInfo _getStatusInfo(String status) {
    return switch (status) {
      'added' => _StatusInfo(Colors.greenAccent, Icons.check_circle),
      'failed' => _StatusInfo(Colors.redAccent, Icons.error),
      'searching' => _StatusInfo(Colors.amberAccent, Icons.search),
      'pending' => _StatusInfo(Colors.blueGrey, Icons.hourglass_empty),
      'canceled' => _StatusInfo(Colors.orangeAccent, Icons.cancel),
      _ => _StatusInfo(Colors.white54, Icons.help_outline),
    };
  }
}

class _StatusInfo {
  final Color color;
  final IconData icon;

  _StatusInfo(this.color, this.icon);
}

/// Modern blur wrapper for bottom sheets
class _ModernBlurSheet extends StatefulWidget {
  final Widget child;

  const _ModernBlurSheet({required this.child});

  @override
  State<_ModernBlurSheet> createState() => _ModernBlurSheetState();
}

class _ModernBlurSheetState extends State<_ModernBlurSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final progress = _animation.value;
        final slideOffset = (1 - progress) * 80;

        return Stack(
          children: [
            // Backdrop blur
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: 15 * progress,
                  sigmaY: 15 * progress,
                ),
                child: Container(color: Colors.transparent),
              ),
            ),
            // Animated content
            Transform.translate(
              offset: Offset(0, slideOffset),
              child: Opacity(opacity: progress, child: widget.child),
            ),
          ],
        );
      },
    );
  }
}
