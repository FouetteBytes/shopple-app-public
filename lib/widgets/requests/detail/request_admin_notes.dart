import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopple/values/values.dart';
import 'package:shopple/models/product_request_model.dart';

class RequestAdminNotes extends StatelessWidget {
  final List<AdminNote> notes;

  const RequestAdminNotes({super.key, required this.notes});

  @override
  Widget build(BuildContext context) {
    final publicNotes = notes
        .where((note) => !note.isPrivate && note.note.trim().isNotEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Admin Notes',
              style: GoogleFonts.lato(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
            if (publicNotes.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${publicNotes.length} response${publicNotes.length > 1 ? 's' : ''}',
                  style: GoogleFonts.lato(
                    fontSize: 11,
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        if (publicNotes.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Admins will leave notes here when they review your request.',
              style: GoogleFonts.lato(fontSize: 12, color: Colors.white54),
            ),
          )
        else
          Column(
            children: publicNotes
                .map((note) => _AdminNoteTile(note: note))
                .toList(),
          ),
      ],
    );
  }
}

class _AdminNoteTile extends StatelessWidget {
  final AdminNote note;

  const _AdminNoteTile({required this.note});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.support_agent_outlined,
                  size: 14,
                  color: Colors.white54,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    note.authorName?.isNotEmpty == true
                        ? note.authorName!
                        : 'Shopple Team',
                    style: GoogleFonts.lato(
                      fontSize: 12,
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (note.createdAt != null)
                  Text(
                    _formatNoteTimeAgo(note.createdAt!),
                    style: GoogleFonts.lato(
                      fontSize: 11,
                      color: Colors.white38,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              note.note,
              style: GoogleFonts.lato(fontSize: 13, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatNoteTimeAgo(DateTime timestamp) {
  final now = DateTime.now();
  final difference = now.difference(timestamp);

  if (difference.inDays > 365) {
    final years = (difference.inDays / 365).floor();
    return '$years y ago';
  } else if (difference.inDays > 30) {
    final months = (difference.inDays / 30).floor();
    return '$months mo ago';
  } else if (difference.inDays > 0) {
    return '${difference.inDays}d ago';
  } else if (difference.inHours > 0) {
    return '${difference.inHours}h ago';
  } else if (difference.inMinutes > 0) {
    return '${difference.inMinutes}m ago';
  }
  return 'Just now';
}
