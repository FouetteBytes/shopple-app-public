import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shopple/controllers/ai_agent_controller.dart';
import 'package:shopple/models/ai_agent/agent_intents.dart';
import 'package:shopple/screens/dashboard/ai_assistant/ai_assistant_utils.dart';
import 'package:shopple/widgets/common/liquid_glass.dart';

class AIAssistantActivity extends StatefulWidget {
  final AIAgentController agent;
  final bool autoConfirm;
  final int autoConfirmRemainingSec;
  final VoidCallback onToggleAutoConfirm;
  final VoidCallback onOpenAutoConfirmSettings;
  final VoidCallback onRunAllRemaining;
  final VoidCallback onRefreshToNew;

  const AIAssistantActivity({
    super.key,
    required this.agent,
    required this.autoConfirm,
    required this.autoConfirmRemainingSec,
    required this.onToggleAutoConfirm,
    required this.onOpenAutoConfirmSettings,
    required this.onRunAllRemaining,
    required this.onRefreshToNew,
  });

  @override
  State<AIAssistantActivity> createState() => _AIAssistantActivityState();
}

class _AIAssistantActivityState extends State<AIAssistantActivity> {
  bool _sessionCollapsed = false;

  @override
  Widget build(BuildContext context) {
    final phases = _derivePhases(widget.agent.logs, widget.agent.isRunning);

    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 120),
      children: [
        _buildActivityHeader(),
        const SizedBox(height: 12),
        if (widget.agent.streamingParsePreview.isNotEmpty &&
            widget.agent.isRunning)
          _buildStreamingPreview(),
        const SizedBox(height: 8),
        if (widget.agent.sessionActive) _buildSessionControls(),
        if (widget.agent.sessionActive) const SizedBox(height: 12),
        // Show item progress only when session inactive
        if (!widget.agent.sessionActive) _buildItemProgressStrip(),
        const SizedBox(height: 16),
        // Dynamic card or completion banner
        if (widget.agent.isRunning && phases.isNotEmpty) ...[
        ] else if (!widget.agent.isRunning &&
            widget.agent.lastResult == null) ...[
          if (phases.isNotEmpty) _buildSingleCurrentPhaseCard(phases),
        ] else if (!widget.agent.isRunning &&
            widget.agent.lastResult != null &&
            !widget.agent.sessionActive) ...[
          _buildCompletionBanner(),
        ],
        if (phases.isEmpty)
          Center(
            child: Text(
              widget.agent.isRunning ? 'Analyzing…' : 'No activity yet',
              style: GoogleFonts.lato(color: Colors.white54),
            ),
          ),
      ],
    );
  }

  Widget _buildActivityHeader() {
    final running = widget.agent.isRunning;
    final elapsed = widget.agent.elapsedMs;
    String elapsedLabel() {
      if (elapsed < 1000) return '${elapsed}ms';
      final s = (elapsed / 1000).toStringAsFixed(1);
      return '${s}s';
    }

    return LiquidGlass(
      enableBlur: true,
      borderRadius: 22,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      gradientColors: [
        Colors.white.withValues(alpha: .08),
        Colors.white.withValues(alpha: .03),
      ],
      borderColor: Colors.white.withValues(alpha: .12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .25),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
      ],
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  running
                      ? aiRainbowGradient.first.withValues(alpha: .85)
                      : Colors.greenAccent.withValues(alpha: .80),
                  running
                      ? aiRainbowGradient.first.withValues(alpha: .55)
                      : Colors.greenAccent.withValues(alpha: .55),
                ],
              ),
            ),
            child: Icon(
              running ? Icons.bolt : Icons.check_circle,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  running ? 'Intelligence Running' : 'Session Idle',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  running
                      ? 'Elapsed ${elapsedLabel()}'
                      : (widget.agent.lastResult != null
                          ? 'Last run • ${widget.agent.lastResult!.addedItems.length} added'
                          : 'Awaiting a request'),
                  style: GoogleFonts.inter(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ),
          if (running)
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStreamingPreview() {
    final txt = widget.agent.streamingParsePreview;
    return LiquidGlass(
      enableBlur: true,
      borderRadius: 18,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      gradientColors: [
        Colors.white.withValues(alpha: .07),
        Colors.white.withValues(alpha: .03),
      ],
      borderColor: Colors.white.withValues(alpha: .10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.text_snippet_outlined,
                size: 16,
                color: Colors.white70,
              ),
              const SizedBox(width: 6),
              Text(
                'Understanding',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            txt,
            style: GoogleFonts.robotoMono(fontSize: 11, color: Colors.white70),
            maxLines: 6,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            minHeight: 3,
            valueColor: AlwaysStoppedAnimation(aiRainbowGradient.first),
            backgroundColor: Colors.white.withValues(alpha: .15),
          ),
        ],
      ),
    );
  }

  Widget _buildItemProgressStrip() {
    if (widget.agent.itemStatuses.isEmpty) return const SizedBox.shrink();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: widget.agent.itemStatuses.entries.map((e) {
          final status = e.value;
          final imageUrl = widget.agent.itemImages[e.key];
          Color col;
          IconData icn;
          switch (status) {
            case 'added':
              col = Colors.greenAccent;
              icn = Icons.check;
              break;
            case 'searching':
              col = aiRainbowGradient[0];
              icn = Icons.travel_explore;
              break;
            case 'pending':
              col = Colors.white54;
              icn = Icons.hourglass_bottom;
              break;
            case 'failed':
              col = Colors.redAccent;
              icn = Icons.error_outline;
              break;
            case 'canceled':
              col = Colors.orangeAccent;
              icn = Icons.cancel;
              break;
            default:
              col = Colors.white54;
              icn = Icons.help_outline;
              break;
          }
          return Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              gradient: LinearGradient(
                colors: [
                  col.withValues(alpha: .20),
                  col.withValues(alpha: .05),
                ],
              ),
              border: Border.all(color: col.withValues(alpha: .5)),
            ),
            child: Row(
              children: [
                // Show product image if available, otherwise show icon
                if (imageUrl != null && imageUrl.isNotEmpty)
                  Container(
                    width: 18,
                    height: 18,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: col.withValues(alpha: 0.7), width: 1.5),
                    ),
                    child: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: Colors.grey.shade800),
                        errorWidget: (_, __, ___) => Icon(icn, size: 12, color: col),
                      ),
                    ),
                  )
                else ...
                [
                  Icon(icn, size: 14, color: col),
                  const SizedBox(width: 4),
                ],
                Text(
                  abbr(e.key),
                  style: GoogleFonts.lato(fontSize: 11, color: col),
                ),
                if (status == 'failed' && !widget.agent.isRunning) ...[
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => widget.agent.retryFailedItem(e.key),
                    child: const Icon(
                      Icons.refresh,
                      size: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSessionControls() {
    final pending = widget.agent.sessionPendingItemPhrases;
    final failed = widget.agent.itemStatuses.entries
        .where((e) => e.value == 'failed')
        .map((e) => e.key)
        .toList();
    final added = widget.agent.itemStatuses.entries
        .where((e) => e.value == 'added')
        .map((e) => e.key)
        .toList();
    final totalItems = widget.agent.itemStatuses.length;
    final resolvedCount = added.length + failed.length;
    final progress = totalItems == 0 ? 0.0 : resolvedCount / totalItems;
    final sessionDone = widget.agent.currentSession?.completed ?? false;

    if (sessionDone && _sessionCollapsed) {
      return GestureDetector(
        onTap: () => setState(() => _sessionCollapsed = false),
        child: LiquidGlass(
          enableBlur: true,
          borderRadius: 16,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          gradientColors: [
            Colors.white.withValues(alpha: 0.10),
            Colors.white.withValues(alpha: 0.04),
          ],
          borderColor: Colors.white.withValues(alpha: 0.12),
          child: Row(
            children: [
              const Icon(Icons.route, size: 18, color: Colors.white70),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Session complete • ${added.length} added • ${failed.length} failed',
                  style: GoogleFonts.lato(fontSize: 12, color: Colors.white70),
                ),
              ),
              const Icon(Icons.expand_more, size: 18, color: Colors.white54),
            ],
          ),
        ),
      );
    }
    return LiquidGlass(
      enableBlur: true,
      borderRadius: 16,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      gradientColors: [
        Colors.white.withValues(alpha: 0.10),
        Colors.white.withValues(alpha: 0.04),
      ],
      borderColor: Colors.white.withValues(alpha: 0.12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!sessionDone && pending.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  colors: [
                    aiRainbowGradient.first.withValues(alpha: .35),
                    aiRainbowGradient.first.withValues(alpha: .10),
                  ],
                ),
                border: Border.all(
                  color: aiRainbowGradient.first.withValues(alpha: .55),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, size: 18, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.autoConfirm
                          ? 'Auto-confirm in ${widget.autoConfirmRemainingSec} s'
                          : 'Review items or enable Auto‑confirm',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: widget.onOpenAutoConfirmSettings,
                    child: const Icon(
                      Icons.tune,
                      size: 18,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _autoConfirmToggle(),
                ],
              ),
            ),
          ],
          LayoutBuilder(
            builder: (ctx, cons) {
              return Row(
                children: [
                  Icon(Icons.route, size: 18, color: Colors.lightBlueAccent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Wrap(
                      runSpacing: 4,
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Agent Session',
                          style: GoogleFonts.lato(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => setState(() => _sessionCollapsed = true),
                    child: const Icon(
                      Icons.close_fullscreen,
                      size: 18,
                      color: Colors.white54,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Container(
              height: 8,
              color: Colors.white.withValues(alpha: .12),
              child: LayoutBuilder(
                builder: (ctx, cons) {
                  return Stack(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOutCubic,
                        width: cons.maxWidth * progress,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.greenAccent.withValues(alpha: .85),
                              Colors.greenAccent.withValues(alpha: .55),
                            ],
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: Center(
                          child: Text(
                            '${(progress * 100).toStringAsFixed(0)}%',
                            style: GoogleFonts.robotoMono(
                              fontSize: 10,
                              color: Colors.black87,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (pending.isEmpty && failed.isEmpty && added.isNotEmpty) ...[
            Text(
              'All items processed.',
              style: GoogleFonts.lato(fontSize: 12, color: Colors.greenAccent),
            ),
          ] else ...[
            if (pending.isNotEmpty) ...[
              Text(
                'Pending',
                style: GoogleFonts.lato(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final phrase in pending) _sessionItemChip(phrase),
                ],
              ),
              const SizedBox(height: 12),
              _primaryConfirmAllButton(pendingCount: pending.length),
            ],
            if (failed.isNotEmpty) ...[
              Text(
                'Failed (tap to retry)',
                style: GoogleFonts.lato(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final phrase in failed)
                    _sessionItemChip(phrase, failed: true),
                ],
              ),
              const SizedBox(height: 12),
            ],
            // Added items section with product images
            if (added.isNotEmpty) ...[
              Text(
                'Added',
                style: GoogleFonts.lato(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.greenAccent,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final phrase in added) _sessionResolvedChip(phrase),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ],
          if (sessionDone) ...[
            const SizedBox(height: 12),
            Text(
              'Session complete • ${added.length} added • ${failed.length} failed',
              style: GoogleFonts.lato(fontSize: 11, color: Colors.white54),
            ),
          ],
        ],
      ),
    );
  }

  Widget _autoConfirmToggle() {
    final active = widget.autoConfirm;
    return GestureDetector(
      onTap: widget.onToggleAutoConfirm,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          color: active
              ? Colors.greenAccent.withValues(alpha: .18)
              : Colors.white.withValues(alpha: .08),
          border: Border.all(
            color: active ? Colors.greenAccent : Colors.white24,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              active ? Icons.timer : Icons.timer_outlined,
              size: 16,
              color: active ? Colors.greenAccent : Colors.white70,
            ),
            const SizedBox(width: 6),
            Text(
              active
                  ? 'Auto in ${widget.autoConfirmRemainingSec}s'
                  : 'Auto‑confirm',
              style: GoogleFonts.lato(
                fontSize: 11,
                color: active ? Colors.greenAccent : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _primaryConfirmAllButton({required int pendingCount}) {
    final running = widget.agent.isRunning;
    final autoActive = widget.autoConfirm && widget.autoConfirmRemainingSec > 0;
    final label = running
        ? 'Resolving…'
        : autoActive
            ? 'Confirming in ${widget.autoConfirmRemainingSec}s'
            : 'Confirm All ($pendingCount)';
    return GestureDetector(
      onTap: running ? null : widget.onRunAllRemaining,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: running
              ? null
              : LinearGradient(
                  colors: [
                    aiRainbowGradient.first.withValues(alpha: .85),
                    aiRainbowGradient[2].withValues(alpha: .85),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          color: running ? Colors.white.withValues(alpha: .06) : null,
          border: Border.all(
            color: running ? Colors.white12 : Colors.transparent,
          ),
          boxShadow: [
            if (!running)
              BoxShadow(
                color: aiRainbowGradient.first.withValues(alpha: .30),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
          ],
        ),
        child: Row(
          children: [
            if (running) ...[
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              ),
              const SizedBox(width: 10),
            ] else ...[
              const Icon(
                Icons.playlist_add_check_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sessionItemChip(String phrase, {bool failed = false}) {
    final status = widget.agent.itemStatuses[phrase];
    final searching = status == 'searching' && widget.agent.isRunning;
    final baseColor = failed ? Colors.redAccent : Colors.white70;
    
    // Get image if available (for search visualization)
    final imageUrl = widget.agent.itemImages[phrase];
    
    return GestureDetector(
      onTap: (widget.agent.isRunning || searching)
          ? null
          : () async {
              await widget.agent.executeSessionItemByPhrase(phrase);
            },
      child: AnimatedOpacity(
        opacity: searching ? .85 : 1, // Increased opacity for visibility
        duration: const Duration(milliseconds: 240),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              colors: [
                baseColor.withValues(alpha: .18),
                baseColor.withValues(alpha: .05),
              ],
            ),
            border: Border.all(color: baseColor.withValues(alpha: .45)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (searching) ...[
                // Show image if found during search, else spinner
                if (imageUrl != null && imageUrl.isNotEmpty)
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: baseColor, width: 1),
                      image: DecorationImage(
                        image: CachedNetworkImageProvider(imageUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                else
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(baseColor),
                    ),
                  ),
              ] else
                Icon(
                  failed ? Icons.refresh : Icons.search,
                  size: 14,
                  color: baseColor,
                ),
              const SizedBox(width: 6),
              Text(
                abbr(phrase),
                style: GoogleFonts.lato(fontSize: 12, color: baseColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sessionResolvedChip(String phrase) {
    final imageUrl = widget.agent.itemImages[phrase];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            Colors.greenAccent.withValues(alpha: .22),
            Colors.greenAccent.withValues(alpha: .05),
          ],
        ),
        border: Border.all(color: Colors.greenAccent.withValues(alpha: .55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (imageUrl != null && imageUrl.isNotEmpty) ...[
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.greenAccent, width: 1),
                image: DecorationImage(
                  image: CachedNetworkImageProvider(imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 6),
          ] else ...[
            const Icon(Icons.check, size: 14, color: Colors.greenAccent),
            const SizedBox(width: 4),
          ],
          Text(
            abbr(phrase),
            style: GoogleFonts.lato(fontSize: 12, color: Colors.greenAccent),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionBanner() {
    final added = widget.agent.lastResult?.addedItems.length ?? 0;
    final failed = widget.agent.lastResult?.failures.length ?? 0;
    final ms = widget.agent.elapsedMs;
    final sec = (ms / 1000).toStringAsFixed(1);
    
    // Get added item images for history-style display
    final addedImages = widget.agent.lastResult?.addedItems.keys
        .map((phrase) => widget.agent.itemImages[phrase])
        .where((url) => url != null && url.isNotEmpty)
        .cast<String>()
        .toList() ?? [];

    return LiquidGlass(
      enableBlur: true,
      borderRadius: 22,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      gradientColors: [
        Colors.greenAccent.withValues(alpha: .18),
        Colors.greenAccent.withValues(alpha: .06),
      ],
      borderColor: Colors.greenAccent.withValues(alpha: .55),
      boxShadow: [
        BoxShadow(
          color: Colors.greenAccent.withValues(alpha: .35),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Colors.greenAccent.withValues(alpha: .9),
                      Colors.greenAccent.withValues(alpha: .55),
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.black,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Session complete',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Added $added • Failed $failed • $sec s',
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: widget.onRefreshToNew,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: .95),
                        Colors.white.withValues(alpha: .80),
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.add_circle_outline,
                        size: 16,
                        color: Colors.black87,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Add New',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (addedImages.isNotEmpty) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 36,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: addedImages.length,
                itemBuilder: (context, index) {
                  return Container(
                    width: 36,
                    height: 36,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.5), width: 1),
                      image: DecorationImage(
                        image: CachedNetworkImageProvider(addedImages[index]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSingleCurrentPhaseCard(List<Phase> phases) {
    Phase current = phases.first;
    for (final p in phases) {
      if (p.status == PhaseStatus.running) {
        current = p;
        break;
      }
    }
    if (current.status != PhaseStatus.running) {
      for (int i = phases.length - 1; i >= 0; i--) {
        if (phases[i].status == PhaseStatus.complete) {
          current = phases[i];
          break;
        }
      }
    }
    final index = phases.indexOf(current);
    final total = phases.length;
    final stepLabel = 'Step ${index + 1} of $total';
    final subtitle = () {
      switch (current.status) {
        case PhaseStatus.running:
          return 'Working…';
        case PhaseStatus.complete:
          if (index == total - 1) {
            if (!widget.agent.sessionActive) {
              return 'Session complete';
            } else {
              return 'Ready for confirmation';
            }
          }
          return 'Done';
        case PhaseStatus.pending:
          return 'Pending';
        case PhaseStatus.error:
          return 'Error — check logs';
      }
    }();
    final color = _statusColor(current.status);
    final progress =
        (index + (current.status == PhaseStatus.complete ? 1 : 0)) / total;
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 12),
      child: LiquidGlass(
        enableBlur: true,
        borderRadius: 24,
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
        gradientColors: [
          color.withValues(alpha: .22),
          color.withValues(alpha: .08),
        ],
        borderColor: color.withValues(alpha: .55),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: .28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        color.withValues(alpha: .9),
                        color.withValues(alpha: .55),
                      ],
                    ),
                  ),
                  child: Icon(current.def.icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stepLabel,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          letterSpacing: .5,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        current.title,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ),
                ),
                if (current.status == PhaseStatus.running)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress.clamp(0, 1),
                minHeight: 6,
                backgroundColor: Colors.white.withValues(alpha: .10),
                valueColor: const AlwaysStoppedAnimation(Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(PhaseStatus s) {
    switch (s) {
      case PhaseStatus.pending:
        return Colors.white54;
      case PhaseStatus.running:
        return aiRainbowGradient[0];
      case PhaseStatus.complete:
        return Colors.greenAccent;
      case PhaseStatus.error:
        return Colors.redAccent;
    }
  }

  List<Phase> _derivePhases(List<AgentActionLog> logs, bool running) {
    final phases = <PhaseDefinition>[
      PhaseDefinition(
        id: 'parse',
        title: 'Understand Request',
        icon: Icons.text_snippet_outlined,
        matchTypes: const {
          'server_delegate',
          'parse_provider',
          'parse',
          'warning',
          'run_id',
          'quota',
          'parse_steps',
          'parse_step',
        },
      ),
      PhaseDefinition(
        id: 'list',
        title: 'List Preparation',
        icon: Icons.list_alt_outlined,
        matchTypes: const {
          'create_list',
          'reuse_list',
          'plan',
          'plan_steps',
          'plan_step',
          'execute_step',
          'session_mode',
          'session_step_start',
          'session_list_created',
          'session_start',
        },
      ),
      PhaseDefinition(
        id: 'items',
        title: 'Item Resolution',
        icon: Icons.shopping_cart_checkout,
        matchTypes: const {
          'search_item',
          'add_item',
          'add_item_alt',
          'add_item_custom',
          'add_item_success',
          'add_item_failed',
          'add_item_error',
          'search_phase',
          'search_phase_error',
          'search_circuit_break',
          'disambiguate',
          'session_item_start',
          'search_reuse',
        },
      ),
      PhaseDefinition(
        id: 'final',
        title: 'Finalize',
        icon: Icons.flag_circle,
        matchTypes: const {
          'cancel',
          'finalize',
          'completion_success',
          'completion_partial',
          'completion_failed',
          'completion_empty',
          'session_complete',
          'session_wait',
        },
      ),
    ];

    final remaining = [...logs];
    final phaseInstances = <Phase>[];

    for (final def in phases) {
      final matched = remaining
          .where((l) => def.matchTypes.contains(l.type))
          .toList();

      if (def.id == 'parse') {
        final contentMatched = remaining
            .where(
              (l) =>
                  !matched.contains(l) &&
                  (l.description.contains('Breaking down user request') ||
                      l.description.contains('✓ List name:') ||
                      l.description.contains('✓ Budget limit:') ||
                      l.description.contains('✓ Items to find:') ||
                      l.description.contains('✓ Start date:') ||
                      l.description.contains('✓ End date:') ||
                      l.description.contains('✓ Preferred stores:')),
            )
            .toList();
        matched.addAll(contentMatched);
      } else if (def.id == 'list') {
        final contentMatched = remaining
            .where(
              (l) =>
                  !matched.contains(l) &&
                  (l.description.contains('Execution plan created') ||
                      l.description.contains('Create shopping list') ||
                      l.description.contains('Step: Creating shopping list') ||
                      l.description.startsWith('1.') ||
                      l.description.startsWith('2.') ||
                      l.description.startsWith('3.') ||
                      l.description.startsWith('4.')),
            )
            .toList();
        matched.addAll(contentMatched);
      } else if (def.id == 'items') {
        final contentMatched = remaining
            .where(
              (l) =>
                  !matched.contains(l) &&
                  (l.description.contains('Step: Finding') ||
                      l.description.contains('Resolving broad category') ||
                      l.description.contains('Round ') ||
                      l.description.contains('Candidate ') ||
                      l.description.contains('Acceptance threshold')),
            )
            .toList();
        matched.addAll(contentMatched);
      }

      remaining.removeWhere((l) => matched.contains(l));
      phaseInstances.add(Phase(def: def, logs: matched));
    }

    if (remaining.isNotEmpty) {
      final finalPhase = phaseInstances.last;
      finalPhase.logs.addAll(remaining);
    }

    int lastLoggedIndex = -1;
    for (int i = 0; i < phaseInstances.length; i++) {
      if (phaseInstances[i].logs.isNotEmpty) lastLoggedIndex = i;
    }
    bool precedingError = false;
    for (int i = 0; i < phaseInstances.length; i++) {
      final p = phaseInstances[i];
      final hasLogs = p.logs.isNotEmpty;
      final hasError = p.logs.any((l) => !l.success);
      if (precedingError) {
        p.status = PhaseStatus.pending;
        continue;
      }
      if (hasError) {
        p.status = PhaseStatus.error;
        precedingError = true;
        continue;
      }
      if (!running) {
        p.status = hasLogs ? PhaseStatus.complete : PhaseStatus.pending;
      } else {
        if (lastLoggedIndex == -1) {
          p.status = (i == 0) ? PhaseStatus.running : PhaseStatus.pending;
        } else {
          if (i < lastLoggedIndex) {
            p.status = PhaseStatus.complete;
          } else if (i == lastLoggedIndex) {
            p.status = PhaseStatus.running;
          } else {
            p.status = PhaseStatus.pending;
          }
        }
      }
    }
    if (widget.agent.sessionActive) {
      final unresolved = widget.agent.sessionPendingItemPhrases.isNotEmpty;
      if (unresolved) {
        Phase? itemsP;
        Phase? finalP;
        for (final p in phaseInstances) {
          if (p.def.id == 'items') itemsP = p;
          if (p.def.id == 'final') finalP = p;
        }
        if (itemsP != null) itemsP.status = PhaseStatus.running;
        if (finalP != null) finalP.status = PhaseStatus.pending;
      }
    }
    return phaseInstances;
  }
}
