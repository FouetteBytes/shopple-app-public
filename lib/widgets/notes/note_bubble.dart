import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shopple/bottom_sheets/bottom_sheets.dart';

import '../../controllers/shopping_lists/list_notes_controller.dart';
import '../../models/shopping_lists/list_note_model.dart';
import '../../services/product/product_image_cache.dart';
import '../../utils/modern_ux_enhancements.dart';

import 'package:shopple/widgets/common/liquid_glass_button.dart';
import 'package:shopple/widgets/common/liquid_text_field.dart';

class NoteBubble extends StatelessWidget {
  final ListNote note;
  final ListNotesController controller;
  final bool isMainNote;

  const NoteBubble({
    super.key,
    required this.note,
    required this.controller,
    this.isMainNote = true,
  });

  @override
  Widget build(BuildContext context) {
    final isCurrentUser = controller.canEditNote(note);
    final timeFormat = DateFormat('MMM d, h:mm a');

    // Notes-style card: consistent left alignment, subtle card background.
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GestureDetector(
        onLongPress: () {
          ModernUXEnhancements.mediumImpact();
          _showOptions(context);
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1B1E24),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: author • time • edited
              Row(
                children: [
                  Text(
                    note.userName,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.circle, size: 4, color: Colors.white24),
                  const SizedBox(width: 8),
                  Text(
                    timeFormat.format(note.createdAt),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.white38,
                    ),
                  ),
                  if (note.isEdited) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.edit, size: 12, color: Colors.white38),
                  ],
                  const Spacer(),
                  if (isMainNote)
                    IconButton(
                      tooltip: 'Reply',
                      icon: const Icon(
                        Icons.reply,
                        size: 18,
                        color: Colors.white60,
                      ),
                      onPressed: () => controller.setReplyTarget(note),
                    ),
                  if (isCurrentUser) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.person, size: 14, color: Colors.white24),
                  ],
                ],
              ),

              if (note.isReply) ...[
                Container(
                  margin: const EdgeInsets.only(top: 4, bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF242830),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.reply, size: 12, color: Colors.white60),
                      const SizedBox(width: 6),
                      Text(
                        'Reply',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Linked item chip (if any)
              if (note.metadata['productName'] != null ||
                  note.metadata['linkedProductId'] != null) ...[
                _LinkedItemChip(
                  productName: (note.metadata['productName'] ?? '') as String,
                  productId: note.metadata['linkedProductId'] as String?,
                ),
                const SizedBox(height: 8),
              ],

              // Content
              Text(
                note.content,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    if (!controller.canEditNote(note)) return;

    showAppBottomSheet(
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Edit option
          ListTile(
            leading: const Icon(Icons.edit, color: Colors.white70),
            title: Text(
              'Edit Note',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              _showEditDialog(context);
            },
          ),

          // Delete option
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.redAccent),
            title: Text(
              'Delete Note',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.redAccent,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              _showDeleteDialog(context);
            },
          ),

          const SizedBox(height: 20),
        ],
      ),
      isScrollControlled: false,
      maxHeightFactor: 0.5,
    );
  }

  void _showEditDialog(BuildContext context) {
    final TextEditingController editController = TextEditingController(
      text: note.content,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Edit Note',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        content: LiquidTextField(
          controller: editController,
          maxLines: 3,
          hintText: 'Edit your note...',
          borderRadius: 12,
        ),
        actions: [
          LiquidGlassButton.text(
            onTap: () => Navigator.pop(context),
            text: 'Cancel',
          ),
          LiquidGlassButton.text(
            onTap: () {
              final newContent = editController.text.trim();
              if (newContent.isNotEmpty && newContent != note.content) {
                controller.updateNote(note.id, newContent);
              }
              Navigator.pop(context);
            },
            text: 'Save',
            accentColor: Colors.blueAccent,
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Note',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to delete this note? This action cannot be undone.',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              controller.deleteNote(note.id);
              Navigator.pop(context);
            },
            child: Text(
              'Delete',
              style: GoogleFonts.inter(
                color: Colors.redAccent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkedItemChip extends StatelessWidget {
  final String productName;
  final String? productId;
  const _LinkedItemChip({required this.productName, this.productId});

  @override
  Widget build(BuildContext context) {
    final name = (productName.isNotEmpty) ? productName : 'Linked item';
    final Future<String?> future = (productId != null && productId!.isNotEmpty)
        ? ProductImageCache.instance.getImageUrl(productId!)
        : Future<String?>.value(null);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF23262D), const Color(0xFF1A1D24)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (productId != null && productId!.isNotEmpty) ...[
            FutureBuilder<String?>(
              future: future,
              builder: (context, snapshot) {
                final url = snapshot.data;
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _modernShimmer();
                }
                if (url == null || url.isEmpty) {
                  return _modernFallbackIcon();
                }
                return ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Image.network(
                      url,
                      key: ValueKey(url),
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return _modernShimmer();
                      },
                      errorBuilder: (_, __, ___) => _modernFallbackIcon(),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 10),
          ] else ...[
            const Icon(Icons.link_rounded, size: 18, color: Colors.white54),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Text(
              name,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _modernShimmer() => Container(
    width: 32,
    height: 32,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      gradient: LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.1),
          Colors.white.withValues(alpha: 0.05),
          Colors.white.withValues(alpha: 0.1),
        ],
        stops: const [0.0, 0.5, 1.0],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
  );

  Widget _modernFallbackIcon() => Container(
    width: 32,
    height: 32,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [const Color(0xFFA06AFA), const Color(0xFF6C3FBF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(10),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFFA06AFA).withValues(alpha: 0.3),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    alignment: Alignment.center,
    child: const Icon(
      Icons.shopping_bag_outlined,
      size: 18,
      color: Colors.white,
    ),
  );
}
