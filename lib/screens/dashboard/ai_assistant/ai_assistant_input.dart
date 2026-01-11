import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopple/controllers/ai_agent_controller.dart';
import 'package:shopple/screens/dashboard/ai_assistant/ai_assistant_utils.dart';

import 'package:shopple/widgets/common/liquid_glass_button.dart';
import 'package:shopple/widgets/common/liquid_text_field.dart';

class AIAssistantInput extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final AIAgentController agent;
  final VoidCallback onRun;

  const AIAssistantInput({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.agent,
    required this.onRun,
  });

  @override
  State<AIAssistantInput> createState() => _AIAssistantInputState();
}

class _AIAssistantInputState extends State<AIAssistantInput> {
  bool _isFocused = false;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_handleFocusChange);
    widget.controller.addListener(_handleTextChange);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_handleFocusChange);
    widget.controller.removeListener(_handleTextChange);
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = widget.focusNode.hasFocus;
      // Expand on focus.
      if (_isFocused) {
        _isExpanded = true;
      } else {
        // Collapse if text fits one line.
        _isExpanded = _needsMultipleLines();
      }
    });
  }

  void _handleTextChange() {
    // Check expansion requirement.
    if (_isFocused) {
      final needsExpand = _needsMultipleLines();
      if (needsExpand != _isExpanded) {
        setState(() => _isExpanded = needsExpand);
      }
    }
  }

  bool _needsMultipleLines() {
    final text = widget.controller.text;
    // Heuristic: newlines or >50 chars.
    return text.contains('\n') || text.length > 50;
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic line count.
    final minLines = 1;
    final maxLines = (_isFocused || _isExpanded) ? 4 : 1;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.only(
        left: 0,
        right: 0,
        top: 8,
        bottom: 8,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: LiquidTextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              minLines: minLines,
              maxLines: maxLines,
              readOnly: widget.agent.isRunning,
              hintText: 'Ask Shopple Intelligence…',
              borderRadius: 24,
              enableBlur: true,
              suffixIcon: widget.agent.isRunning
                  ? const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: Icon(
                        Icons.lock_clock,
                        color: Colors.white54,
                        size: 18,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          _buildRunButton(),
        ],
      ),
    );
  }

  Widget _buildRunButton() {
    final disabled = widget.agent.isRunning || widget.controller.text.trim().isEmpty;
    return LiquidGlassGradientButton(
      onTap: disabled ? null : widget.onRun,
      gradientColors: aiRainbowGradient,
      borderRadius: 40,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      isDisabled: disabled,
      customChild: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.agent.isRunning) ...[
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            ),
          ] else ...[
            const Icon(Icons.auto_awesome, size: 18, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              'Run AI',
              style: GoogleFonts.lato(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
