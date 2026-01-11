import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:shopple/bottom_sheets/bottom_sheets.dart';
import 'package:shopple/models/ai_agent/quick_prompt.dart';
import 'package:shopple/services/ai/gemini_service.dart';
import 'package:shopple/services/ai/quick_prompt_service.dart';
import 'package:shopple/widgets/ai/quick_prompt_editor_sheet.dart';
import 'package:shopple/widgets/common/liquid_glass.dart';

/// Modern QuickCards widget with enhanced glassmorphism and performance optimizations
class QuickCardsWidget extends StatefulWidget {
  /// Callback when a quick prompt is selected for execution
  final Function(QuickPrompt)? onQuickPromptSelected;

  /// Optional input controller to suggest tags from
  final TextEditingController? inputController;

  /// Whether to show the empty-state example card when there are no quick cards
  final bool showEmptyState;

  const QuickCardsWidget({
    super.key,
    this.onQuickPromptSelected,
    this.inputController,
    this.showEmptyState = false,
  });

  @override
  State<QuickCardsWidget> createState() => _QuickCardsWidgetState();
}

class _QuickCardsWidgetState extends State<QuickCardsWidget> {
  // Quick Prompts state
  List<QuickPrompt> _quickPrompts = const [];
  bool _quickPromptsLoading = true;
  bool _reorderMode = false;

  // Track current user to avoid unnecessary cache clears
  String? _lastUserId;

  // Tag filtering state (computed lazily)
  final Set<String> _activeTagFilters = <String>{};
  List<String>? _availableTags; // Nullable for lazy computation
  bool _suggestingFilters = false;

  // Google AI rainbow gradient colors
  static const List<Color> _aiRainbowGradient = [
    Color(0xFF4285F4), // Google Blue
    Color(0xFF34A853), // Google Green
    Color(0xFFFBBC04), // Google Yellow
    Color(0xFFEA4335), // Google Red
    Color(0xFF9C27B0), // Purple
    Color(0xFF00BCD4), // Cyan
  ];

  @override
  void initState() {
    super.initState();
    _lastUserId = FirebaseAuth.instance.currentUser?.uid;

    // INSTANT RENDER: Check memory cache synchronously (zero-latency)
    if (QuickPromptService.hasMemoryCache()) {
      _quickPrompts = QuickPromptService.peekMemory();
      _quickPromptsLoading = false; // Suppress spinner completely
    }

    // Still trigger optimistic load for background refresh
    _loadQuickPromptsOptimistic();

    // Listen to auth changes but avoid unnecessary cache clears
    FirebaseAuth.instance.authStateChanges().listen((user) {
      final newUserId = user?.uid;
      if (mounted && newUserId != _lastUserId) {
        _lastUserId = newUserId;
        // Reset cache on user switch
        QuickPromptService.clearCacheForUser();
        _quickPrompts = [];
        _quickPromptsLoading = true;
        _invalidateTagsCache();
        setState(() {});
        _loadQuickPromptsOptimistic();
      }
    });
  }

  /// Optimistic loading - shows cached data immediately if available
  Future<void> _loadQuickPromptsOptimistic() async {
    try {
      final list = await QuickPromptService.loadForUserOptimistic();

      if (mounted) {
        setState(() {
          _quickPrompts = list;
          _quickPromptsLoading = false;
          // Don't compute tags immediately - do it lazily
        });
      }
    } catch (e) {
      // On error, still mark loading as complete
      if (mounted) {
        setState(() {
          _quickPromptsLoading = false;
        });
      }
    }
  }

  /// Lazy computation of available tags
  List<String> get availableTags {
    if (_availableTags == null) {
      final set = <String>{};
      for (final qp in _quickPrompts) {
        set.addAll(qp.tags);
      }
      _availableTags = set.toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

      // Clean up invalid filters
      _activeTagFilters.removeWhere((t) => !_availableTags!.contains(t));
    }
    return _availableTags!;
  }

  /// Clear cached tags when data changes
  void _invalidateTagsCache() {
    _availableTags = null;
  }

  List<QuickPrompt> _filteredQuickPrompts() {
    if (_activeTagFilters.isEmpty) return _quickPrompts;
    return _quickPrompts
        .where((qp) => qp.tags.any((t) => _activeTagFilters.contains(t)))
        .toList();
  }

  Future<void> _onAddQuickPrompt() async {
    if (_quickPrompts.length >= 3) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You can only have 3 quick cards. Remove one to add another.',
          ),
        ),
      );
      return;
    }
    final res = await showAppBottomSheet(
      const QuickPromptEditorSheet(),
      isScrollControlled: true,
    );
    if (res == null) return;
    final created = await QuickPromptService.create(
      res.title,
      res.prompt,
      tags: res.tags,
      color: res.color,
    );
    setState(() {
      _quickPrompts = [..._quickPrompts, created];
      _invalidateTagsCache(); // Clear tags cache for recomputation
    });
  }

  Future<void> _onEditQuickPrompt(QuickPrompt qp) async {
    final res = await showAppBottomSheet(
      QuickPromptEditorSheet(initial: qp),
      isScrollControlled: true,
    );
    if (res == null) return;
    final updated = QuickPrompt(
      id: qp.id,
      title: res.title,
      prompt: res.prompt,
      tags: res.tags,
      color: res.color,
    );
    await QuickPromptService.update(updated);
    setState(() {
      final idx = _quickPrompts.indexWhere((e) => e.id == qp.id);
      if (idx >= 0) _quickPrompts[idx] = updated;
      _invalidateTagsCache(); // Clear tags cache for recomputation
    });
  }

  Future<void> _onDeleteQuickPrompt(QuickPrompt qp) async {
    await QuickPromptService.remove(qp.id);
    setState(() {
      _quickPrompts.removeWhere((e) => e.id == qp.id);
      _invalidateTagsCache(); // Clear tags cache for recomputation
    });
  }

  Future<void> _suggestFiltersFromInput() async {
    final text = widget.inputController?.text.trim() ?? '';
    if (text.isEmpty) {
      return;
    }
    setState(() => _suggestingFilters = true);
    try {
      final p =
          'Propose 3-6 short, relevant tags (1-2 words) that would help categorize this shopping command.\n'
          'Instruction: "$text"\n'
          'Return only a comma-separated list.';
      final out = await GeminiService.instance.generateText(p, lite: true);
      final suggestions = out
          .split(RegExp(r'[\n,]'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toSet();

      // Map to available tags (case-insensitive exact matches)
      final availableTags = this.availableTags; // Get tags through lazy getter
      final availLower = {for (var t in availableTags) t.toLowerCase(): t};
      final matched = <String>{};
      for (final s in suggestions) {
        final m = availLower[s.toLowerCase()];
        if (m != null) matched.add(m);
      }
      if (matched.isNotEmpty) {
        setState(
          () => _activeTagFilters
            ..clear()
            ..addAll(matched),
        );
      }
    } finally {
      if (mounted) setState(() => _suggestingFilters = false);
    }
  }

  void _applyQuick(QuickPrompt qp) {
    widget.onQuickPromptSelected?.call(qp);
  }

  Color _hex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header row with title and actions
        SizedBox(
          width: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quick Cards',
                style: GoogleFonts.lato(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  if (_quickPrompts.isNotEmpty)
                    IconButton(
                      tooltip: _reorderMode ? 'Done' : 'Reorder',
                      onPressed: () async {
                        setState(() => _reorderMode = !_reorderMode);
                        if (!_reorderMode) {
                          await QuickPromptService.saveForUser(_quickPrompts);
                        }
                      },
                      icon: Icon(
                        _reorderMode ? Icons.check : Icons.drag_indicator,
                        color: Colors.white70,
                      ),
                    ),
                  if (availableTags.isNotEmpty &&
                      widget.inputController != null)
                    TextButton.icon(
                      onPressed: _suggestingFilters
                          ? null
                          : _suggestFiltersFromInput,
                      icon: _suggestingFilters
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(
                              Icons.auto_awesome,
                              size: 16,
                              color: Colors.white70,
                            ),
                      label: Text(
                        'Suggest',
                        style: GoogleFonts.lato(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  IconButton(
                    tooltip: _quickPrompts.length >= 3
                        ? 'Max 3 quick cards'
                        : 'Add quick card',
                    onPressed: _quickPrompts.length >= 3
                        ? null
                        : _onAddQuickPrompt,
                    icon: Icon(
                      Icons.add_circle_outline,
                      color: _quickPrompts.length >= 3
                          ? Colors.white24
                          : Colors.white70,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Max cards warning
        if (_quickPrompts.length >= 3) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 14, color: Colors.white54),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Maximum of 3 quick cards. Remove one to add another.',
                    style: GoogleFonts.lato(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Tag filters
        if (availableTags.isNotEmpty) ...[
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const SizedBox(width: 2),
                ...availableTags.take(18).map((t) {
                  final sel = _activeTagFilters.contains(t);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        t,
                        style: GoogleFonts.lato(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      selected: sel,
                      selectedColor: Colors.white.withValues(alpha: .14),
                      backgroundColor: Colors.white.withValues(alpha: .06),
                      onSelected: (v) {
                        setState(() {
                          if (v) {
                            _activeTagFilters.add(t);
                          } else {
                            _activeTagFilters.remove(t);
                          }
                        });
                      },
                    ),
                  );
                }),
                if (_activeTagFilters.isNotEmpty)
                  TextButton(
                    onPressed: () => setState(() => _activeTagFilters.clear()),
                    child: Text(
                      'Clear',
                      style: GoogleFonts.lato(color: Colors.white70),
                    ),
                  ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 8),

        // Quick cards content
        if (_quickPromptsLoading)
          // Show modern loading skeleton
          Column(
            children: List.generate(
              2,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildShimmerCard(),
              ),
            ),
          )
        else if (_quickPrompts.isEmpty)
          (widget.showEmptyState ? _buildEmptyState() : const SizedBox.shrink())
        else if (_quickPrompts.isNotEmpty)
          (_reorderMode
              ? ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  onReorder: (oldIndex, newIndex) async {
                    if (newIndex > oldIndex) newIndex -= 1;
                    final item = _quickPrompts.removeAt(oldIndex);
                    _quickPrompts.insert(newIndex, item);
                    setState(() {});
                    await QuickPromptService.saveForUser(_quickPrompts);
                  },
                  itemCount: _quickPrompts.length,
                  buildDefaultDragHandles: false,
                  itemBuilder: (context, index) {
                    final qp = _quickPrompts[index];
                    return _buildReorderableCard(qp, index);
                  },
                )
              : Column(
                  children: _filteredQuickPrompts()
                      .map(
                        (qp) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _modernQuickCard(qp),
                        ),
                      )
                      .toList(),
                )),
      ],
    );
  }

  // Modern shimmer loading effect for quick cards
  Widget _buildShimmerCard() {
    return LiquidGlass(
      enableBlur: true,
      borderRadius: 16,
      padding: const EdgeInsets.all(20),
      gradientColors: [
        Colors.white.withValues(alpha: .04),
        Colors.white.withValues(alpha: .01),
      ],
      borderColor: Colors.white.withValues(alpha: .08),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Shimmer accent bar
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title shimmer
                    Container(
                      height: 16,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Description shimmer
                    Container(
                      height: 12,
                      width: 250,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Tags shimmer
          Row(
            children: [
              Container(
                height: 24,
                width: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .06),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                height: 24,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .06),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // New full-width empty state for quick cards (rebuilt from scratch)
  Widget _buildEmptyState() {
    final accent = _aiRainbowGradient[0];
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: .08),
            Colors.white.withValues(alpha: .03),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: .12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Accent icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    accent.withValues(alpha: .35),
                    _aiRainbowGradient[1].withValues(alpha: .28),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: .35),
                    blurRadius: 18,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome_outlined,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Quick Cards yet',
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create personalized quick cards to run your\nfrequent AI tasks in one tap.',
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                color: Colors.white70,
                fontSize: 13.5,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            // Primary action button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _onAddQuickPrompt,
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: Text(
                  'Create quick card',
                  style: GoogleFonts.lato(fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: .14),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Modern quick card design with enhanced glassmorphism
  Widget _modernQuickCard(QuickPrompt qp) {
    final accent = qp.color != null ? _hex(qp.color!) : _aiRainbowGradient[0];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _applyQuick(qp),
          borderRadius: BorderRadius.circular(16),
          splashColor: accent.withValues(alpha: .1),
          highlightColor: accent.withValues(alpha: .05),
          child: LiquidGlass(
            enableBlur: true,
            borderRadius: 16,
            padding: const EdgeInsets.all(20),
            gradientColors: [
              Colors.white.withValues(alpha: .08),
              Colors.white.withValues(alpha: .03),
            ],
            borderColor: accent.withValues(alpha: .15),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: .1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: .15),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Modern accent indicator with glow animation
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 4,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [accent, accent.withValues(alpha: .6)],
                        ),
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                            color: accent.withValues(alpha: .4),
                            blurRadius: 12,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            qp.title.isEmpty ? 'Quick Card' : qp.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.lato(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            qp.prompt,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.lato(
                              color: Colors.white70,
                              fontSize: 13,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!_reorderMode)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: PopupMenuButton<String>(
                          onSelected: (v) {
                            if (v == 'edit') _onEditQuickPrompt(qp);
                            if (v == 'delete') _onDeleteQuickPrompt(qp);
                          },
                          icon: const Icon(
                            Icons.more_vert,
                            color: Colors.white70,
                            size: 18,
                          ),
                          itemBuilder: (c) => const [
                            PopupMenuItem(value: 'edit', child: Text('Edit')),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                if (qp.tags.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: qp.tags.take(4).map((tag) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                accent.withValues(alpha: .15),
                                accent.withValues(alpha: .08),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: accent.withValues(alpha: .25),
                              width: 0.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: accent,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: accent.withValues(alpha: .4),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                tag,
                                style: GoogleFonts.lato(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Reorderable card for drag-and-drop functionality
  Widget _buildReorderableCard(QuickPrompt qp, int index) {
    final accent = qp.color != null ? _hex(qp.color!) : _aiRainbowGradient[0];

    return ReorderableDragStartListener(
      key: ValueKey(qp.id),
      index: index,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: LiquidGlass(
          enableBlur: true,
          borderRadius: 16,
          padding: const EdgeInsets.all(20),
          gradientColors: [
            Colors.white.withValues(alpha: .08),
            Colors.white.withValues(alpha: .03),
          ],
          borderColor: accent.withValues(alpha: .15),
          child: Row(
            children: [
              Icon(Icons.drag_handle, color: Colors.white54, size: 20),
              const SizedBox(width: 12),
              Container(
                width: 4,
                height: 30,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      qp.title.isEmpty ? 'Quick Card' : qp.title,
                      style: GoogleFonts.lato(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      qp.prompt,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.lato(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
