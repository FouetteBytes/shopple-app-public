import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../common/liquid_glass.dart';

class ItemAssignmentHistorySheet extends StatelessWidget {
  final String listId;
  final String itemId;
  const ItemAssignmentHistorySheet({
    super.key,
    required this.listId,
    required this.itemId,
  });

  static void show(
    BuildContext context, {
    required String listId,
    required String itemId,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          ItemAssignmentHistorySheet(listId: listId, itemId: itemId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LiquidGlass(
      borderRadius: 20,
      enableBlur: true,
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Text(
                    'Assignment History',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .doc('shopping_lists/$listId')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final data =
                      snapshot.data!.data() as Map<String, dynamic>? ?? {};
                  final collab =
                      data['collaboration'] as Map<String, dynamic>? ?? {};
                  final assigns =
                      collab['itemAssignments'] as Map<String, dynamic>? ?? {};
                  final item = assigns[itemId] as Map<String, dynamic>?;
                  final rawHistory = List<Map<String, dynamic>>.from(
                    item?['history'] ?? const [],
                  );
                  rawHistory.sort((a, b) {
                    final ta =
                        (a['timestamp'] as Timestamp?)?.toDate() ??
                        DateTime.fromMillisecondsSinceEpoch(0);
                    final tb =
                        (b['timestamp'] as Timestamp?)?.toDate() ??
                        DateTime.fromMillisecondsSinceEpoch(0);
                    return tb.compareTo(ta);
                  });
                  if (rawHistory.isEmpty) {
                    return Center(
                      child: Text(
                        'No history yet',
                        style: GoogleFonts.inter(color: Colors.white54),
                      ),
                    );
                  }
                  return ListView.separated(
                    itemCount: rawHistory.length,
                    separatorBuilder: (_, __) => Divider(
                      color: Colors.white.withValues(alpha: 0.06),
                      height: 1,
                    ),
                    itemBuilder: (context, index) {
                      final h = rawHistory[index];
                      final action = (h['actionType'] ?? '').toString();
                      final who = (h['userName'] ?? 'Someone').toString();
                      final when = (h['timestamp'] as Timestamp?)?.toDate();
                      final subtitle = _subtitleFor(action, h);
                      final icon = _iconFor(action);
                      final color = _colorFor(action);
                      return ListTile(
                        leading: Icon(icon, color: color),
                        title: Text(
                          '$who ${_verbFor(action)}',
                          style: GoogleFonts.inter(color: Colors.white),
                        ),
                        subtitle: Text(
                          subtitle,
                          style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        trailing: when != null
                            ? Text(
                                _formatRelative(when),
                                style: GoogleFonts.inter(
                                  color: Colors.white38,
                                  fontSize: 12,
                                ),
                              )
                            : null,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _verbFor(String action) {
    switch (action) {
      case 'assigned':
        return 'assigned the item';
      case 'reassigned':
        return 'reassigned the item';
      case 'unassigned':
        return 'unassigned the item';
      case 'notes_updated':
        return 'updated assignment notes';
      case 'completed':
        return 'marked it completed';
      default:
        return 'updated assignment';
    }
  }

  String _subtitleFor(String action, Map<String, dynamic> h) {
    switch (action) {
      case 'assigned':
      case 'reassigned':
        return 'Assigned to ${h['newValue'] ?? ''}';
      case 'unassigned':
        return 'Assignment cleared';
      case 'notes_updated':
        final notes = (h['newValue'] ?? '').toString();
        return notes.isEmpty ? 'Notes cleared' : 'Notes: $notes';
      case 'completed':
        return 'Assignment completed';
      default:
        return '';
    }
  }

  IconData _iconFor(String action) {
    switch (action) {
      case 'assigned':
        return Icons.person_add_alt_1;
      case 'reassigned':
        return Icons.swap_horiz;
      case 'unassigned':
        return Icons.person_off;
      case 'notes_updated':
        return Icons.sticky_note_2_outlined;
      case 'completed':
        return Icons.check_circle_outline;
      default:
        return Icons.history;
    }
  }

  Color _colorFor(String action) {
    switch (action) {
      case 'assigned':
        return Colors.blueAccent;
      case 'reassigned':
        return Colors.orangeAccent;
      case 'unassigned':
        return Colors.redAccent;
      case 'notes_updated':
        return Colors.tealAccent;
      case 'completed':
        return Colors.greenAccent;
      default:
        return Colors.white70;
    }
  }

  String _formatRelative(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
