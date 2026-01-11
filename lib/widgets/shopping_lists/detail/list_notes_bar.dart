import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopple/controllers/shopping_lists/list_detail_controller.dart';
import 'package:shopple/models/shopping_lists/list_note_model.dart';
import 'package:shopple/values/values.dart';
import 'package:shopple/widgets/common/liquid_glass.dart';
import 'package:shopple/widgets/notes/list_notes_widget.dart';
import 'package:shopple/bottom_sheets/bottom_sheets.dart';

class ListNotesBar extends StatelessWidget {
  final ListDetailController controller;

  const ListNotesBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ListNote>>(
      stream: controller.notesCountStream,
      builder: (context, snapshot) {
        final noteCount = snapshot.data?.length ?? 0;
        final accent = HexColor.fromHex(controller.list.colorTheme);
        return LiquidGlass(
          borderRadius: 25,
          enableBlur: true,
          blurSigmaX: 16,
          blurSigmaY: 24,
          gradientColors: [
            Colors.white.withValues(alpha: 0.08),
            Colors.white.withValues(alpha: 0.03),
          ],
          borderColor: Colors.white.withValues(alpha: 0.12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, -6),
            ),
          ],
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showListNotesSheet(context),
              splashColor: accent.withValues(alpha: 0.12),
              highlightColor: Colors.white.withValues(alpha: 0.04),
              child: Container(
                padding: const EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 16,
                  bottom: 16,
                ),
                width: double.infinity,
                height: 80,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Icon(Icons.attach_file, color: accent, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            noteCount > 0
                                ? 'Notes ($noteCount)'
                                : 'Add a note…',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            noteCount > 0
                                ? 'Tap to view and add more'
                                : 'Share ideas, tasks, links',
                            style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (noteCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.20),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: accent, width: 1),
                        ),
                        child: Text(
                          noteCount.toString(),
                          style: GoogleFonts.inter(
                            color: accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showListNotesSheet(BuildContext context) {
    showAppBottomSheet(
      ListNotesWidget(
        listId: controller.listId,
        availableItems: controller.itemsController.mergedItems,
        listColor: controller.list.colorTheme,
        initialNotes: controller.prefetchedNotes,
      ),
      isScrollControlled: true,
      maxHeightFactor: 0.88,
    );
  }
}
