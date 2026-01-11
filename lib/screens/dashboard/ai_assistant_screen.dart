import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:shopple/values/values.dart';
import 'package:shopple/controllers/ai_agent_controller.dart';
import 'package:shopple/models/ai_agent/quick_prompt.dart';
import 'package:shopple/widgets/common/liquid_snack.dart';
import 'package:shopple/widgets/dark_background/dark_radial_background.dart';
import 'package:shopple/widgets/ai/quick_cards_widget.dart';
import 'package:shopple/widgets/common/liquid_glass.dart';
import 'package:shopple/widgets/common/page_header.dart';
import 'package:shopple/widgets/common/rainbow_segmented_button_picker.dart';
import 'package:shopple/services/ai/quick_prompt_service.dart';
import 'package:shopple/bottom_sheets/bottom_sheets.dart';
import 'package:shopple/widgets/bottom_sheets/shopple_ai_info_sheet.dart';
import 'package:shopple/services/shopping_lists/shopping_list_cache.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:shopple/screens/dashboard/ai_assistant/ai_assistant_utils.dart';
import 'package:shopple/screens/dashboard/ai_assistant/ai_assistant_history.dart';
import 'package:shopple/screens/dashboard/ai_assistant/ai_assistant_input.dart';
import 'package:shopple/screens/dashboard/ai_assistant/ai_assistant_activity.dart';

import 'package:shopple/widgets/common/liquid_glass_button.dart';

/// Full-page Applied Intelligence screen (replaces floating button UX).
/// Shows: prompt input, recent history, step timeline of last run, and logs.
/// Styled to match Shopping Alerts page with Google AI rainbow gradients.
class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late AIAgentController _agent;
  final _controller = TextEditingController();
  final FocusNode _inputFocus = FocusNode();
  int _tabIndex = 0; // 0 New, 1 History (Activity integrated into New)
  late TabController _tabController;
  
  // After completion, user can dismiss activity to return to New
  bool _activityDismissed = false;
  
  // Auto-confirm (countdown) for pending items
  bool _autoConfirm = false;
  int _autoConfirmDelaySec = 6; // configurable small delay
  int _autoConfirmRemainingSec = 0; // 0 means idle
  Timer? _autoConfirmTimer;
  
  // If user doesn't press confirm promptly, auto-start the countdown after a short grace
  final int _graceBeforeAutoStartSec = 4;
  Timer? _autoGraceTimer;
  
  Timer? _elapsedTimer;
  bool _timerActive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 2, vsync: this);
    _agent = Get.find<AIAgentController>();
    _controller.addListener(() {
      setState(() {});
    });
    _agent.addListener(_handleAgentChange);
    _loadAutoConfirmPrefs();
    // Also listen to auth changes to reset per-user UI state (notifications, timers)
    FirebaseAuth.instance.authStateChanges().listen((user) {
      // Reset any completion toast guard and countdowns on user switch
      _hasShownCompletionNotification = false;
      _lastNotifiedRunId = null;
      _stopAutoConfirmTimer(persist: false);
      _autoGraceTimer?.cancel();
      _autoGraceTimer = null;
      // Reload prefs (delay/enabled) for the new user
      _loadAutoConfirmPrefs();
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    _autoConfirmTimer?.cancel();
    _elapsedTimer?.cancel();
    _agent.removeListener(_handleAgentChange);
    _controller.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Warm quick cards cache on resume for instant AI tab experience
      QuickPromptService.warmCacheForCurrentUser();
    }
  }

  void _handleAgentChange() {
    final running = _agent.isRunning;
    if (running && !_timerActive) {
      _timerActive = true;
      _elapsedTimer?.cancel();
      _elapsedTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
        if (mounted) setState(() {});
      });
    } else if (!running && _timerActive) {
      _timerActive = false;
      _elapsedTimer?.cancel();
      _elapsedTimer = null;
    }
    // Trigger completion notifier exactly on completion (idle, non-session, has result)
    if (!running && !_agent.sessionActive && _agent.lastResult != null) {
      _showCompletionNotification();
    }
    // If auto-confirm is enabled and agent just became idle with pending items, restart countdown if needed
    if (!running &&
        _autoConfirm &&
        _autoConfirmTimer == null &&
        _agent.sessionPendingItemPhrases.isNotEmpty) {
      _startAutoConfirmTimer();
    }
    // If user hasn't interacted and there are pending items, begin a grace timer to auto-start countdown
    if (!running && _agent.sessionPendingItemPhrases.isNotEmpty) {
      _maybeAutoStartCountdown();
    }
    // Still trigger rebuild on other state changes
    if (mounted) setState(() {});
  }

  Future<void> _run() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _agent.isRunning) return;

    // Reset completion notification flag for new process
    _hasShownCompletionNotification = false;
    _lastNotifiedRunId = null;
    _activityDismissed = false;

    // Ensure we are on the New tab
    if (_tabIndex != 0) {
      setState(() {
        _tabIndex = 0;
        _tabController.animateTo(0);
      });
    }

    await _agent.runUserCommand(text);
  }

  @override
  Widget build(BuildContext context) {
    // Calculate bottom padding for the content above the input
    // This accounts for the input height + nav bar height
    const inputAreaHeight = 120.0; // Input + spacing above nav bar
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          DarkRadialBackground(
            color: AppColors.background,
            position: "topLeft",
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: SafeArea(
              bottom: false, // We handle bottom ourselves
              child: AnimatedBuilder(
                animation: _agent,
                builder: (context, _) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PageHeader(
                        title: "Shopple AI",
                        actions: [
                          LiquidGlassButton.icon(
                            icon: Icons.info_outline,
                            onTap: () {
                              showAppBottomSheet(
                                const ShoppleAiInfoSheet(),
                                isScrollControlled: true,
                                maxHeightFactor: 0.85,
                              );
                            },
                            size: 40,
                            iconSize: 20,
                          ),
                        ],
                      ),
                      AppSpaces.verticalSpace20,
                      RainbowSegmentedButtonPicker(
                        controller: _tabController,
                        gradientColors: aiRainbowGradient,
                        onTap: () =>
                            setState(() => _tabIndex = _tabController.index),
                        tabs: [
                          RainbowSegmentedTabFactory.simple(
                            text: 'New',
                            icon: Icons.auto_awesome,
                          ),
                          RainbowSegmentedTabFactory.simple(
                            text: 'History',
                            icon: Icons.history,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Content area with padding for input
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: inputAreaHeight),
                          child: _buildTabContent(),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          // Fixed input at bottom, above nav bar
          Positioned(
            left: 20,
            right: 20,
            bottom: 100, // Above the nav bar (80px nav + 20px spacing)
            child: AnimatedBuilder(
              animation: _agent,
              builder: (context, _) => AIAssistantInput(
                controller: _controller,
                focusNode: _inputFocus,
                agent: _agent,
                onRun: _run,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    if (_tabIndex == 1) {
      return AIAssistantHistory(
        agent: _agent,
        onRerun: _handleRerun,
      );
    }
    return _buildNewPromptHelp(); // Activity integrated into New
  }

  Widget _buildNewPromptHelp() {
    final showActivityInline =
        (_agent.logs.isNotEmpty || _agent.isRunning) && !_activityDismissed;
    if (showActivityInline) {
      return Column(
        children: [
          Expanded(
            child: AIAssistantActivity(
              agent: _agent,
              autoConfirm: _autoConfirm,
              autoConfirmRemainingSec: _autoConfirmRemainingSec,
              onToggleAutoConfirm: () {
                if (_autoConfirm) {
                  _stopAutoConfirmTimer();
                } else {
                  _startAutoConfirmTimer();
                }
                setState(() {});
              },
              onOpenAutoConfirmSettings: _openAutoConfirmSettings,
              onRunAllRemaining: _runAllRemainingItems,
              onRefreshToNew: _refreshToNew,
            ),
          ),
        ],
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 12),
      children: [
        SizedBox(
          width: double.infinity,
          child: QuickCardsWidget(
            onQuickPromptSelected: _applyQuick,
            inputController: _controller,
            showEmptyState: true,
          ),
        ),
        const SizedBox(height: 16),
        if (_agent.lastResult != null) ...[
          const SizedBox(height: 20),
          Text(
            'Last Run Summary',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          _buildLastResultSummary(),
        ],
      ],
    );
  }

  Widget _buildLastResultSummary() {
    final r = _agent.lastResult!;
    final listId = r.listId;
    String? listName;
    if (listId != null) {
      final list = ShoppingListCache.instance.listenable.value
          .firstWhereOrNull((l) => l.id == listId);
      listName = list?.name;
    }
    // Get images from stored itemImages (independent of list existence)
    final imageUrls = _agent.itemImages.values.where((url) => url.isNotEmpty).toList();

    return LiquidGlass(
      enableBlur: true,
      borderRadius: 20,
      padding: const EdgeInsets.all(14),
      gradientColors: [
        Colors.white.withValues(alpha: .18),
        Colors.white.withValues(alpha: .05),
      ],
      borderColor: Colors.white.withValues(alpha: .22),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .25),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (listName != null) ...[
            Row(
              children: [
                const Icon(
                  Icons.list_alt_rounded,
                  size: 16,
                  color: Colors.lightBlueAccent,
                ),
                const SizedBox(width: 8),
                Text(
                  listName,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              if (imageUrls.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _buildStackedImages(imageUrls, size: 36),
                ),
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    miniInfoChip(
                      Icons.add_task,
                      '${r.addedItems.length} added',
                      Colors.greenAccent,
                    ),
                    if (r.failures.isNotEmpty)
                      miniInfoChip(
                        Icons.error_outline,
                        '${r.failures.length} failed',
                        Colors.redAccent,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build stacked images from stored URLs (independent of list cache)
  Widget _buildStackedImages(List<String> imageUrls, {int maxVisible = 4, double size = 32}) {
    final showImages = imageUrls.take(maxVisible).toList();
    final hasMore = imageUrls.length > maxVisible;
    const overlap = 10.0;
    
    final totalWidth = showImages.length == 1 
        ? size 
        : size + (showImages.length - 1) * (size - overlap) + (hasMore ? (size - overlap) : 0);

    return SizedBox(
      height: size + 4,
      width: totalWidth + 4,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (int i = 0; i < showImages.length; i++)
            Positioned(
              left: i * (size - overlap),
              top: 2,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.5), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: CachedNetworkImage(
                    imageUrl: showImages[i],
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: const Color(0xFF2A2A2A)),
                    errorWidget: (_, __, ___) => Container(
                      color: const Color(0xFF2A2A2A),
                      child: const Icon(Icons.image, size: 14, color: Colors.white38),
                    ),
                  ),
                ),
              ),
            ),
          if (hasMore)
            Positioned(
              left: showImages.length * (size - overlap),
              top: 2,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: const Color(0xFF1E1E1E),
                  border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.5), width: 1),
                ),
                alignment: Alignment.center,
                child: Text(
                  '+${imageUrls.length - maxVisible}',
                  style: GoogleFonts.lato(
                    fontSize: size * 0.35,
                    fontWeight: FontWeight.w700,
                    color: Colors.white70,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _applyQuick(QuickPrompt qp) async {
    if (_agent.isRunning) return;
    setState(() {
      _controller.text = qp.prompt;
    });
    FocusScope.of(context).requestFocus(_inputFocus);
  }

  void _handleRerun(String prompt) {
    _controller.text = prompt;
    // Switch to New tab
    setState(() {
      _tabIndex = 0;
      _tabController.animateTo(0);
    });
    // Focus input
    FocusScope.of(context).requestFocus(_inputFocus);
  }

  void _refreshToNew() {
    setState(() {
      _tabIndex = 0;
      _controller.clear();
      _activityDismissed = true;
    });
  }

  bool _hasShownCompletionNotification = false;
  String? _lastNotifiedRunId;
  void _showCompletionNotification() {
    final runIdLog = _agent.logs.firstWhereOrNull((l) => l.type == 'run_id');
    final runId = runIdLog?.description.replaceFirst('Run: ', '');
    if (_hasShownCompletionNotification && (_lastNotifiedRunId == runId)) {
      return;
    }
    _hasShownCompletionNotification = true;
    _lastNotifiedRunId = runId;
    if (!mounted) return;
    
    LiquidSnack.success(
      title: 'AI Session Complete',
      message: 'All items processed',
    );
  }

  Future<void> _runAllRemainingItems() async {
    final pending = List<String>.from(_agent.sessionPendingItemPhrases);
    for (final p in pending) {
      if (!mounted) break;
      await _agent.executeSessionItemByPhrase(p);
      await Future.delayed(const Duration(milliseconds: 120));
    }
    if (_autoConfirm && _agent.sessionPendingItemPhrases.isNotEmpty) {
      _startAutoConfirmTimer();
    }
    if (mounted) setState(() {});
  }

  void _startAutoConfirmTimer({bool persist = true}) {
    _stopAutoConfirmTimer();
    if (_agent.sessionPendingItemPhrases.isEmpty) return;
    _autoConfirm = true;
    _autoConfirmRemainingSec = _autoConfirmDelaySec;
    if (persist) _saveAutoConfirmPrefs();
    _autoConfirmTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_agent.isRunning) {
        setState(() {});
        return;
      }
      if (_agent.sessionPendingItemPhrases.isEmpty) {
        _stopAutoConfirmTimer();
        setState(() {});
        return;
      }
      _autoConfirmRemainingSec -= 1;
      if (_autoConfirmRemainingSec <= 0) {
        t.cancel();
        _autoConfirmRemainingSec = 0;
        _runAllRemainingItems();
      }
      setState(() {});
    });
  }

  void _stopAutoConfirmTimer({bool persist = true}) {
    _autoConfirmTimer?.cancel();
    _autoConfirmTimer = null;
    _autoConfirmRemainingSec = 0;
    _autoConfirm = false;
    if (persist) _saveAutoConfirmPrefs();
  }

  void _maybeAutoStartCountdown() {
    if (!_agent.isRunning &&
        _agent.sessionPendingItemPhrases.isNotEmpty &&
        !_autoConfirm &&
        _autoConfirmTimer == null &&
        _autoGraceTimer == null) {
      _autoGraceTimer = Timer(Duration(seconds: _graceBeforeAutoStartSec), () {
        _autoGraceTimer = null;
        if (!mounted) return;
        if (!_agent.isRunning &&
            _agent.sessionPendingItemPhrases.isNotEmpty &&
            !_autoConfirm &&
            _autoConfirmTimer == null) {
          _startAutoConfirmTimer(persist: false);
          if (mounted) setState(() {});
        }
      });
    }
  }

  Future<void> _loadAutoConfirmPrefs() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anon';
      final prefs = await SharedPreferences.getInstance();
      _autoConfirm = prefs.getBool('ai_auto_confirm_enabled_$uid') ?? false;
      _autoConfirmDelaySec =
          prefs.getInt('ai_auto_confirm_delay_$uid') ?? _autoConfirmDelaySec;
      if (mounted) setState(() {});
    } catch (_) {
      /* ignore */
    }
  }

  Future<void> _saveAutoConfirmPrefs() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anon';
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('ai_auto_confirm_enabled_$uid', _autoConfirm);
      await prefs.setInt('ai_auto_confirm_delay_$uid', _autoConfirmDelaySec);
    } catch (_) {
      /* ignore */
    }
  }

  void _openAutoConfirmSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final options = [3, 5, 6, 10, 15, 20];
        return Padding(
          padding: const EdgeInsets.all(12),
          child: LiquidGlass(
            enableBlur: true,
            borderRadius: 16,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            gradientColors: [
              Colors.white.withValues(alpha: 0.10),
              Colors.white.withValues(alpha: 0.04),
            ],
            borderColor: Colors.white.withValues(alpha: 0.12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Row(
                children: [
                  const Icon(Icons.timer, color: Colors.white70, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Auto‑confirm delay',
                    style: GoogleFonts.lato(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white54,
                      size: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final sec in options)
                    GestureDetector(
                      onTap: () async {
                        setState(() => _autoConfirmDelaySec = sec);
                        await _saveAutoConfirmPrefs();
                        if (!mounted) return;
                        Navigator.of(context).pop();
                        if (_autoConfirm) {
                          _startAutoConfirmTimer();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          color: (_autoConfirmDelaySec == sec)
                              ? Colors.greenAccent.withValues(alpha: .18)
                              : Colors.white.withValues(alpha: .06),
                          border: Border.all(
                            color: (_autoConfirmDelaySec == sec)
                                ? Colors.greenAccent
                                : Colors.white12,
                          ),
                        ),
                        child: Text(
                          '$sec s',
                          style: GoogleFonts.lato(
                            color: (_autoConfirmDelaySec == sec)
                                ? Colors.greenAccent
                                : Colors.white70,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    },
    );
  }
}
