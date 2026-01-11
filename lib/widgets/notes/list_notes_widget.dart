import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../../controllers/shopping_lists/list_notes_controller.dart';
import '../../models/shopping_lists/list_note_model.dart';
import 'note_bubble.dart';
import 'note_input_widget.dart';

class ListNotesWidget extends StatelessWidget {
  final String listId;
  final String? itemId;
  final String? itemName; // For display context
  final List<dynamic> availableItems; // Pass from parent
  final String? listColor; // List color for theming
  final List<ListNote>? initialNotes;

  const ListNotesWidget({
    super.key,
    required this.listId,
    this.itemId,
    this.itemName,
    this.availableItems = const [],
    this.listColor,
    this.initialNotes,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ListNotesController(), tag: _getTag());
    // Seed initial notes immediately if provided
    if (initialNotes != null && initialNotes!.isNotEmpty) {
      controller.seedInitialNotes(initialNotes!);
    }

    // Load notes when widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (itemId != null) {
        controller.loadItemNotes(listId, itemId!);
      } else {
        controller.loadListNotes(listId);
      }
    });

    // Adopt app's dark, blurred bottom sheet theme
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          // Header
          _buildHeader(),
          Divider(height: 1, color: Colors.white.withValues(alpha: 0.06)),

          // Notes list
          Expanded(child: Obx(() => _buildNotesList(controller))),

          // Reply indicator (if replying)
          Obx(() => _buildReplyIndicator(controller)),

          Divider(height: 1, color: Colors.white.withValues(alpha: 0.06)),

          // Input area
          NoteInputWidget(
            controller: controller,
            listId: listId,
            itemId: itemId,
            availableItems: availableItems.cast(),
            listColor: listColor,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Icon(
            itemId != null ? Icons.comment : Icons.notes,
            color: Colors.white70,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  itemId != null ? 'Item Notes' : 'List Notes',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                if (itemName != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'for "$itemName"',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white54,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white70),
            onPressed: () => Get.back(),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesList(ListNotesController controller) {
    if (controller.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white70),
      );
    }

    if (controller.error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              'Failed to load notes',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              controller.error,
              style: GoogleFonts.inter(fontSize: 13, color: Colors.white54),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (!controller.hasNotes) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              itemId != null ? Icons.comment_outlined : Icons.note_add_outlined,
              size: 48,
              color: Colors.white24,
            ),
            const SizedBox(height: 16),
            Text(
              itemId != null
                  ? 'No notes for this item yet'
                  : 'No notes in this list yet',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add the first note to get started!',
              style: GoogleFonts.inter(fontSize: 13, color: Colors.white54),
            ),
          ],
        ),
      );
    }

    // Show threaded notes in a notes-style list
    final threadedNotes = controller.threadedNotes;
    return AnimationLimiter(
      child: ListView.separated(
        controller: controller.scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        itemBuilder: (context, index) {
          final thread = threadedNotes[index];
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 400),
            child: SlideAnimation(
              verticalOffset: 30.0,
              child: FadeInAnimation(
                child: _buildNoteThread(thread, controller),
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 4),
        itemCount: threadedNotes.length,
      ),
    );
  }

  Widget _buildNoteThread(
    List<ListNote> thread,
    ListNotesController controller,
  ) {
    if (thread.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main note card
        NoteBubble(
          note: thread.first,
          controller: controller,
          isMainNote: true,
        ),

        // Replies as indented notes
        if (thread.length > 1)
          Padding(
            padding: const EdgeInsets.only(left: 20, top: 4),
            child: Column(
              children: thread
                  .skip(1)
                  .map(
                    (reply) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: NoteBubble(
                        note: reply,
                        controller: controller,
                        isMainNote: false,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildReplyIndicator(ListNotesController controller) {
    if (!controller.isReplying) return const SizedBox.shrink();

    final replyTarget = controller.replyTargetNote;
    if (replyTarget == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          const Icon(Icons.reply, size: 16, color: Colors.white70),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Replying to ${replyTarget.userName}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
                Text(
                  replyTarget.content.length > 50
                      ? '${replyTarget.content.substring(0, 50)}...'
                      : replyTarget.content,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white54,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16, color: Colors.white70),
            onPressed: controller.cancelReply,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
          ),
        ],
      ),
    );
  }

  String _getTag() {
    return 'notes_${listId}_${itemId ?? 'list'}';
  }
}
