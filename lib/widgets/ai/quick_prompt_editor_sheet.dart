import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopple/values/values.dart';
import 'package:shopple/widgets/adaptive/keyboard_adaptive_body.dart';
import 'package:shopple/services/ai/user_tag_service.dart';
import 'package:shopple/services/ai/gemini_service.dart';
import 'package:shopple/models/ai_agent/quick_prompt.dart';
import 'package:shopple/widgets/common/liquid_glass_button.dart';
import 'package:shopple/widgets/common/liquid_text_field.dart';

class QuickPromptEditorSheet extends StatefulWidget {
  final QuickPrompt? initial;
  const QuickPromptEditorSheet({super.key, this.initial});

  @override
  State<QuickPromptEditorSheet> createState() => _QuickPromptEditorSheetState();
}

class _QuickPromptEditorSheetState extends State<QuickPromptEditorSheet> {
  late TextEditingController _title;
  late TextEditingController _prompt;
  final _tagController = TextEditingController();
  late List<String> _tags;
  List<String> _userTags = const [];
  bool _generating = false;
  bool _generatingTitle = false;
  List<String> _titleSuggestions = const [];
  List<String> _suggested = const [];
  final Set<String> _selectedSuggestions = <String>{};
  String? _colorHex; // optional hex
  static const int _kMaxTitleChars = 24;

  static const _weekdayTags = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _situationTags = [
    'Work',
    'Home',
    'Trip',
    'Party',
    'Weekly',
    'Monthly',
  ];

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.initial?.title ?? '');
    _prompt = TextEditingController(text: widget.initial?.prompt ?? '');
    _tags = [...(widget.initial?.tags ?? const [])];
    _colorHex = widget.initial?.color;
    _loadUserTags();
  }

  Future<void> _loadUserTags() async {
    final saved = await UserTagService.load();
    if (mounted) setState(() => _userTags = saved);
  }

  @override
  void dispose() {
    _title.dispose();
    _prompt.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _addTag(String t) {
    final tag = t.trim();
    if (tag.isEmpty) return;
    if (!_tags.contains(tag)) setState(() => _tags.add(tag));
    _tagController.clear();
    // Persist to user tag library for reuse
    UserTagService.add(tag);
  }

  Future<void> _generateTagFromPrompt() async {
    final idea = _tagController.text.trim().isEmpty
        ? _prompt.text.trim()
        : _tagController.text.trim();
    if (idea.isEmpty) return;
    setState(() => _generating = true);
    try {
      final prompt =
          'You are classifying a shopping instruction into concise, relevant tags used for quick access.\n'
          '- Extract 4-8 SHORT tags (max 2 words), strictly relevant.\n'
          '- Prefer known shopping contexts (e.g., Grocery, Weekly, Trip, Party, Family, Budget, Healthy, Vegetarian, Spices).\n'
          '- No punctuation, no numbers unless essential.\n'
          'Instruction: "$idea"\n'
          'Return ONLY a comma-separated list of tags.';
      final text = await GeminiService.instance.generateText(
        prompt,
        lite: true,
      );
      final parts = text
          .split(RegExp(r'[\n,]'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();
      setState(() {
        _suggested = parts.take(7).toList();
        _selectedSuggestions
          ..clear()
          ..addAll(_suggested.take(3)); // preselect a few
      });
      _tagController.clear();
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _applySelectedSuggestions() async {
    if (_selectedSuggestions.isEmpty) return;
    final addList = _selectedSuggestions.toList();
    setState(() {
      for (final t in addList) {
        if (!_tags.contains(t)) _tags.add(t);
      }
    });
    for (final t in addList) {
      await UserTagService.add(t);
    }
    setState(() {
      _suggested = const [];
      _selectedSuggestions.clear();
    });
  }

  Future<void> _generateTitleFromPrompt() async {
    final content = _prompt.text.trim();
    if (content.isEmpty) return;
    setState(() => _generatingTitle = true);
    try {
      final p =
          'You are generating SHORT, high-quality quick-card titles for a shopping assistant.\n'
          'Rules:\n'
          '- Return 3-6 options, ONE per line (no bullets, no numbering).\n'
          '- 2–4 words, Title Case, ≤ $_kMaxTitleChars characters.\n'
          '- No quotes, no punctuation, no emojis.\n'
          '- Avoid filler words like: list, shopping, AI, assistant, app.\n'
          '- Be specific and action-oriented (e.g., "Party Prep Snacks", "Weekend Trip Essentials").\n'
          'Instruction: "$content"\n'
          'Return ONLY the titles, newline-separated.';
      final out = await GeminiService.instance.generateText(p, lite: true);
      final lines = out
          .split(RegExp(r'\r?\n|,'))
          .map((e) => _normalizeTitle(e))
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();
      if (mounted) {
        if (lines.isNotEmpty) {
          _title.text = lines.first;
          _titleSuggestions = lines.skip(1).take(5).toList();
        } else {
          _titleSuggestions = const [];
        }
        setState(() {});
      }
    } finally {
      if (mounted) setState(() => _generatingTitle = false);
    }
  }

  String _normalizeTitle(String s) {
    var t = s.trim();
    if (t.isEmpty) return '';
    // strip quotes and common bullets/numbering
    t = t.replaceAll(RegExp(r'^[-*•\d\.\)\s]+'), '');
    // strip curved quotes and straight quotes from ends
    t = t.replaceAll(RegExp("^[\u201C\u201D\"']|[\u201C\u201D\"']\$"), '');
    // remove trailing punctuation
    t = t.replaceAll(RegExp(r'[\.!?]+$'), '');
    // collapse whitespace
    t = t.replaceAll(RegExp(r'\s+'), ' ');
    // Title Case basic
    t = t
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map(
          (w) =>
              w[0].toUpperCase() +
              (w.length > 1 ? w.substring(1).toLowerCase() : ''),
        )
        .join(' ');
    // avoid filler terms
    final banned = {'List', 'Shopping', 'Ai', 'Assistant', 'App'};
    t = t.split(' ').where((w) => !banned.contains(w)).join(' ');
    // enforce char limit
    if (t.length > _kMaxTitleChars) {
      t = t.substring(0, _kMaxTitleChars).trimRight();
      // drop trailing orphan char if it ends mid-letter boundary (best effort)
      if (t.endsWith(' ')) t = t.trimRight();
    }
    return t.trim();
  }

  Future<void> _autoFillFromPrompt() async {
    await _generateTitleFromPrompt();
    await _generateTagFromPrompt();
    // Optional color guess based on suggestions
    if (_suggested.isNotEmpty) {
      String? hex;
      final s = _suggested.map((e) => e.toLowerCase()).toList();
      if (s.any(
        (t) =>
            t.contains('grocery') ||
            t.contains('vegetable') ||
            t.contains('fresh'),
      )) {
        hex = '#34A853';
      } else if (s.any(
        (t) => t.contains('party') || t.contains('celebration'),
      )) {
        hex = '#EA4335';
      } else if (s.any(
        (t) =>
            t.contains('trip') || t.contains('travel') || t.contains('weekend'),
      )) {
        hex = '#00BCD4';
      } else if (s.any((t) => t.contains('budget') || t.contains('saver'))) {
        hex = '#FBBC04';
      } else if (s.any((t) => t.contains('weekly') || t.contains('routine'))) {
        hex = '#4285F4';
      }
      if (mounted) setState(() => _colorHex = hex ?? _colorHex);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const KbGap(12, minSize: 4),
        const KbGap(10, minSize: 4),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.initial == null
                        ? 'New Quick Card'
                        : 'Edit Quick Card',
                    style: GoogleFonts.lato(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Prompt first for clarity
              LiquidTextField(
                controller: _prompt,
                minLines: 3,
                maxLines: 6,
                hintText: 'Describe what you want the Shopping AI to do...',
                prefixText: 'Prompt: ',
              ),
              const SizedBox(height: 12),
              LiquidTextField(
                controller: _title,
                hintText: 'Short and clear (≤ 24 chars)',
                prefixText: 'Title: ',
              ),
              const SizedBox(height: 12),
              // Title helpers (AI button)
              Align(
                alignment: Alignment.centerRight,
                child: LiquidGlassButton(
                  onTap: _generatingTitle ? null : _generateTitleFromPrompt,
                  borderRadius: 16,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_generatingTitle)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      else
                        const Icon(Icons.auto_fix_high, size: 16, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        'Suggest titles',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Title length helper
              Builder(
                builder: (_) {
                  final len = _title.text.trim().length;
                  final over = len > _kMaxTitleChars;
                  return Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      over
                          ? 'Title too long: $len/$_kMaxTitleChars'
                          : 'Title length: $len/$_kMaxTitleChars',
                      style: GoogleFonts.lato(
                        color: over ? Colors.redAccent : Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  );
                },
              ),
              if (_titleSuggestions.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Better titles',
                  style: GoogleFonts.lato(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _titleSuggestions
                      .map(
                        (s) => GestureDetector(
                          onTap: () {
                            setState(() {
                              _title.text = s;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Text(
                              s,
                              style: GoogleFonts.lato(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                'Tags',
                style: GoogleFonts.lato(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._weekdayTags.map(
                    (t) => _TagChip(
                      label: t,
                      selected: _tags.contains(t),
                      onTap: () => setState(() {
                        _tags.contains(t) ? _tags.remove(t) : _tags.add(t);
                      }),
                    ),
                  ),
                  ..._situationTags.map(
                    (t) => _TagChip(
                      label: t,
                      selected: _tags.contains(t),
                      onTap: () => setState(() {
                        _tags.contains(t) ? _tags.remove(t) : _tags.add(t);
                      }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: LiquidTextField(
                      controller: _tagController,
                      hintText: 'Add custom tag and press +',
                      onSubmitted: _addTag,
                    ),
                  ),
                  const SizedBox(width: 8),
                  LiquidGlassButton.icon(
                    onTap: () => _addTag(_tagController.text),
                    icon: Icons.add_circle_outline,
                    size: 48,
                    iconSize: 24,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_userTags.isNotEmpty) ...[
                Text(
                  'Your tags',
                  style: GoogleFonts.lato(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _userTags
                      .map(
                        (t) => _TagChip(
                          label: t,
                          selected: _tags.contains(t),
                          onTap: () => setState(() {
                            _tags.contains(t) ? _tags.remove(t) : _tags.add(t);
                          }),
                        ),
                      )
                      .toList(),
                ),
              ],
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _tags
                    .map(
                      (t) => InputChip(
                        label: Text(t),
                        labelStyle: const TextStyle(color: Colors.white),
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        onDeleted: () => setState(() => _tags.remove(t)),
                        deleteIconColor: Colors.white70,
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              // AI Tag generation helper section (moved after tags per request)
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: HexColor.fromHex('181A1F'),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: HexColor.fromHex('343840')),
                ),
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          color: Colors.white70,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Generate tag ideas',
                          style: GoogleFonts.lato(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        LiquidGlassButton(
                          onTap: _generating ? null : _generateTagFromPrompt,
                          borderRadius: 16,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_generating)
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(Colors.white),
                                  ),
                                )
                              else
                                const Icon(Icons.auto_awesome, size: 16, color: Colors.white),
                              const SizedBox(width: 8),
                              Text(
                                'Suggest',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Use your prompt or a word in the field below to get short, friendly tags. Pick a few you like.',
                      style: GoogleFonts.lato(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: LiquidTextField(
                            controller: _tagController,
                            hintText: 'Type a hint (optional)…',
                            enabled: !_generating,
                            onSubmitted: (_) =>
                                _generating ? null : _generateTagFromPrompt(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        LiquidGlassButton.icon(
                          onTap: _generating ? null : _generateTagFromPrompt,
                          icon: Icons.bolt_outlined,
                          size: 48,
                          iconSize: 24,
                        ),
                      ],
                    ),
                    if (_suggested.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Suggestions',
                        style: GoogleFonts.lato(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _suggested
                            .map(
                              (s) => _TagChip(
                                label: s,
                                selected: _selectedSuggestions.contains(s),
                                onTap: () {
                                  setState(() {
                                    if (_selectedSuggestions.contains(s)) {
                                      _selectedSuggestions.remove(s);
                                    } else {
                                      _selectedSuggestions.add(s);
                                    }
                                  });
                                },
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: _applySelectedSuggestions,
                          icon: const Icon(
                            Icons.check_circle_outline,
                            size: 18,
                          ),
                          label: const Text('Add selected'),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: (_generating || _generatingTitle)
                            ? null
                            : _autoFillFromPrompt,
                        icon: const Icon(Icons.auto_fix_high, size: 16),
                        label: const Text('Auto-fill from prompt'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Optional card color
              Row(
                children: [
                  Text(
                    'Card color (optional)',
                    style: GoogleFonts.lato(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final hex in [
                        '#4285F4',
                        '#34A853',
                        '#FBBC04',
                        '#EA4335',
                        '#9C27B0',
                        '#00BCD4',
                        '#607D8B',
                      ])
                        GestureDetector(
                          onTap: () => setState(() => _colorHex = hex),
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: HexColor.fromHex(
                                hex.replaceFirst('#', ''),
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _colorHex == hex
                                    ? Colors.white
                                    : Colors.white24,
                                width: _colorHex == hex ? 2 : 1,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: LiquidGlassButton.primary(
                      onTap: () {
                        final normalizedTitle = _normalizeTitle(_title.text);
                        final result = QuickPrompt(
                          id: widget.initial?.id ?? 'new',
                          title: normalizedTitle.isEmpty
                              ? 'Quick Card'
                              : normalizedTitle,
                          prompt: _prompt.text.trim(),
                          tags: _tags,
                          color: _colorHex,
                        );
                        Navigator.pop(context, result);
                      },
                      icon: Icons.save_outlined,
                      text: widget.initial == null ? 'Create' : 'Save',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TagChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? Colors.blueAccent.withValues(alpha: .28)
              : Colors.white.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: selected ? .35 : .12),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.lato(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
