import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:shopple/controllers/ai_agent_controller.dart';
import 'package:shopple/config/feature_flags_ai.dart';

class AIListAssistantSheet extends StatefulWidget {
  final String? prefill;
  const AIListAssistantSheet({super.key, this.prefill});
  @override
  State<AIListAssistantSheet> createState() => _AIListAssistantSheetState();
}

class _AIListAssistantSheetState extends State<AIListAssistantSheet> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  @override
  void initState() {
    super.initState();
    if (widget.prefill != null) {
      _input.text = widget.prefill!;
    }
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AIAgentController>(
      builder: (agent) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scroll.hasClients) {
              _scroll.animateTo(
                _scroll.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });
          return Column(
            children: [
              if (agent.isRunning)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.transparent,
                    color: Colors.lightGreenAccent,
                    minHeight: 2,
                  ),
                ),
              Expanded(
                child: ListView(
                  controller: _scroll,
                  children: [
                    if (AIFeatureFlags.streamingUIEnabled &&
                        agent.streamingParsePreview.isNotEmpty &&
                        agent.isRunning)
                      _Bubble(
                        child: Text(
                          agent.streamingParsePreview,
                          style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    for (final log in agent.logs)
                      _Bubble(
                        variant: log.type.startsWith('add')
                            ? BubbleVariant.success
                            : BubbleVariant.normal,
                        child: Text(
                          '[${log.type}] ${log.description}',
                          style: GoogleFonts.inter(
                            color: log.success
                                ? Colors.white
                                : Colors.redAccent,
                            fontSize: 13,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              _Composer(
                controller: _input,
                onSend: agent.isRunning
                    ? null
                    : () async {
                        final text = _input.text.trim();
                        if (text.isEmpty) return;
                        await agent.runUserCommand(text);
                        if (mounted) _input.clear();
                      },
                onCancel: agent.isRunning ? agent.requestCancel : null,
              ),
            ],
          );
      },
    );
  }
}

enum BubbleVariant { normal, success }

class _Bubble extends StatelessWidget {
  final Widget child;
  final BubbleVariant variant;
  const _Bubble({required this.child, this.variant = BubbleVariant.normal});
  @override
  Widget build(BuildContext context) {
    final bg = variant == BubbleVariant.success
        ? Colors.green.withValues(alpha: 0.18)
        : Colors.white.withValues(alpha: 0.06);
    final border = variant == BubbleVariant.success
        ? Colors.greenAccent.withValues(alpha: 0.4)
        : Colors.white12;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: child,
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback? onSend;
  final VoidCallback? onCancel;
  const _Composer({required this.controller, this.onSend, this.onCancel});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            style: GoogleFonts.inter(color: Colors.white),
            minLines: 1,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Ask: Add milk and eggs',
              hintStyle: GoogleFonts.inter(color: Colors.white38),
              filled: true,
              fillColor: const Color(0xFF222429),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        if (onCancel != null)
          IconButton(
            onPressed: onCancel,
            icon: const Icon(
              Icons.stop_circle_outlined,
              color: Colors.orangeAccent,
            ),
          ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.greenAccent.shade400,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          onPressed: onSend,
          child: const Icon(Icons.send_rounded, size: 18),
        ),
      ],
    );
  }
}
