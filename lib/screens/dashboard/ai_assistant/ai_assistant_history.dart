import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shopple/controllers/ai_agent_controller.dart';
import 'package:shopple/screens/dashboard/ai_assistant/ai_assistant_utils.dart';
import 'package:shopple/widgets/common/liquid_glass.dart';
import 'package:shopple/widgets/common/liquid_glass_button.dart';

class AIAssistantHistory extends StatefulWidget {
  final AIAgentController agent;
  final Function(String) onRerun;

  const AIAssistantHistory({
    super.key,
    required this.agent,
    required this.onRerun,
  });

  @override
  State<AIAssistantHistory> createState() => _AIAssistantHistoryState();
}

class _AIAssistantHistoryState extends State<AIAssistantHistory> {
  String _historySort = 'newest';

  @override
  Widget build(BuildContext context) {
    if (widget.agent.history.isEmpty) {
      return Center(
        child: Text(
          widget.agent.remoteHistoryLoaded ? 'No history yet' : 'Syncing history…',
          style: GoogleFonts.lato(color: Colors.white54),
        ),
      );
    }

    final items = List<Map<String, dynamic>>.from(widget.agent.history);
    if (_historySort == 'newest') {
      items.sort(
        (a, b) =>
            (b['ts'] ?? '').toString().compareTo((a['ts'] ?? '').toString()),
      );
    } else if (_historySort == 'oldest') {
      items.sort(
        (a, b) =>
            (a['ts'] ?? '').toString().compareTo((b['ts'] ?? '').toString()),
      );
    } else if (_historySort == 'added') {
      items.sort((a, b) => (b['added'] ?? 0).compareTo(a['added'] ?? 0));
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 12),
      itemCount: items.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) {
          return _buildHeader(context);
        }
        final h = items[i - 1];
        return _buildHistoryItem(h);
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'History',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              setState(() => _historySort = v);
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'newest',
                child: Text('Newest first'),
              ),
              const PopupMenuItem(
                value: 'oldest',
                child: Text('Oldest first'),
              ),
              const PopupMenuItem(
                value: 'added',
                child: Text('Most items added'),
              ),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: Colors.white.withValues(alpha: .06),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.sort, size: 16, color: Colors.white70),
                  const SizedBox(width: 6),
                  Text(
                    'Sort',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) {
                  return AlertDialog(
                    backgroundColor: const Color(0xFF1E1F24),
                    title: const Text(
                      'Clear history',
                      style: TextStyle(color: Colors.white),
                    ),
                    content: const Text(
                      'Remove all AI history entries? This cannot be undone.',
                      style: TextStyle(color: Colors.white70),
                    ),
                    actions: [
                      LiquidGlassButton.text(
                        onTap: () => Navigator.pop(ctx, false),
                        text: 'Cancel',
                      ),
                      LiquidGlassButton.text(
                        onTap: () => Navigator.pop(ctx, true),
                        text: 'Clear',
                        isDestructive: true,
                      ),
                    ],
                  );
                },
              );
              if (confirm == true) {
                await widget.agent.clearHistory();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: Colors.white.withValues(alpha: .06),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.delete_sweep_outlined,
                    size: 16,
                    color: Colors.redAccent,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Clear',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.redAccent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> h) {
    final input = h['input'] as String? ?? '';
    final ts = h['ts'] as String? ?? '';
    // Get stored images (independent of list existence)
    final addedImages = (h['addedImages'] as Map<String, dynamic>?)?.cast<String, String>() ?? {};
    final imageUrls = addedImages.values.where((url) => url.isNotEmpty).toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () {
          widget.onRerun(input);
          // Switch to the "New" tab (index 0)
          final screenState = context.findAncestorStateOfType<TickerProviderStateMixin>();
          if (screenState != null) {
             // Tab switching handled by onRerun callback
          }
        },
        child: LiquidGlass(
          enableBlur: true,
          borderRadius: 20,
          padding: const EdgeInsets.all(16),
          gradientColors: [
            Colors.white.withValues(alpha: .08),
            Colors.white.withValues(alpha: .03),
          ],
          borderColor: Colors.white.withValues(alpha: .12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: aiRainbowGradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Shopple AI',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              formatDate(ts),
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: Colors.white54,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          input,
                          style: GoogleFonts.lato(
                            fontSize: 15,
                            color: Colors.white.withValues(alpha: .9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  LiquidGlassButton.icon(
                    onTap: () => widget.agent.deleteHistoryEntry(ts),
                    icon: Icons.close,
                    size: 32,
                    iconSize: 16,
                    isDestructive: true,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (imageUrls.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _buildStackedImages(imageUrls),
                    ),
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        miniInfoChip(
                          Icons.add_task,
                          '+${h['added']}',
                          Colors.greenAccent,
                        ),
                        if ((h['failed'] ?? 0) > 0)
                          miniInfoChip(
                            Icons.error_outline,
                            '-${h['failed']}',
                            Colors.redAccent,
                          ),
                        miniInfoChip(
                          Icons.schedule,
                          '${(h['durationMs'] ?? 0)} ms',
                          Colors.amberAccent,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
                  border: Border.all(color: Colors.white24, width: 1),
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
                  border: Border.all(color: Colors.white24, width: 1),
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
}
