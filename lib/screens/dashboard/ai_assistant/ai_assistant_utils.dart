import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopple/models/ai_agent/agent_intents.dart';

// Google AI rainbow gradient colors
const List<Color> aiRainbowGradient = [
  Color(0xFF4285F4), // Google Blue
  Color(0xFF34A853), // Google Green
  Color(0xFFFBBC04), // Google Yellow
  Color(0xFFEA4335), // Google Red
  Color(0xFF9C27B0), // Purple
  Color(0xFF00BCD4), // Cyan
];

Widget miniInfoChip(IconData icon, String label, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: color.withValues(alpha: 0.5)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.lato(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    ),
  );
}

String formatDate(String timestamp) {
  if (timestamp.isEmpty) return 'Today';
  try {
    final date = DateTime.parse(timestamp);
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return 'Nov ${date.day}';
  } catch (_) {
    return 'Today';
  }
}

String abbr(String s) {
  if (s.length <= 18) return s;
  return '${s.substring(0, 15)}…';
}

// Internal phase modeling for activity breakdown
enum PhaseStatus { pending, running, complete, error }

class PhaseDefinition {
  final String id;
  final String title;
  final IconData icon;
  final Set<String> matchTypes;
  const PhaseDefinition({
    required this.id,
    required this.title,
    required this.icon,
    required this.matchTypes,
  });
}

class Phase {
  final PhaseDefinition def;
  final List<AgentActionLog> logs;
  PhaseStatus status = PhaseStatus.pending;
  Phase({required this.def, required this.logs});
  String get title => def.title;
  IconData get icon => def.icon;
}
