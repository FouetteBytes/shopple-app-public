import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animations/animations.dart';
import 'package:get/get.dart';

import '../../controllers/shopping_lists/list_notes_controller.dart';
import '../../models/shopping_lists/shopping_list_item_model.dart';
import '../../services/product/product_image_cache.dart';
import '../../utils/modern_ux_enhancements.dart';
import '../../values/values.dart';

import 'package:shopple/widgets/common/liquid_text_field.dart';

class NoteInputWidget extends StatefulWidget {
  final ListNotesController controller;
  final String listId;
  final String? itemId;
  final List<ShoppingListItem> availableItems;
  final String? listColor;

  const NoteInputWidget({
    super.key,
    required this.controller,
    required this.listId,
    this.itemId,
    this.availableItems = const [],
    this.listColor,
  });

  @override
  State<NoteInputWidget> createState() => _NoteInputWidgetState();
}

class _NoteInputWidgetState extends State<NoteInputWidget> {
  ShoppingListItem? _selectedItem;
  bool _showItemSelector = false;

  void _toggleItemSelector() {
    ModernUXEnhancements.selectionClick();
    setState(() {
      _showItemSelector = !_showItemSelector;
    });
  }

  void _selectItem(ShoppingListItem? item) {
    setState(() {
      _selectedItem = item;
      _showItemSelector = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final textNotEmpty = widget.controller.noteContentController.text
        .trim()
        .isNotEmpty;

    return Column(
      children: [
        // Item selector dropdown
        if (_showItemSelector) ...[
          OpenContainer(
            closedElevation: 0,
            openElevation: 0,
            transitionDuration: const Duration(milliseconds: 300),
            transitionType: ContainerTransitionType.fadeThrough,
            closedBuilder: (context, openContainer) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1B1E24),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Link to an item (optional):',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _buildGeneralNoteOption(),
                  const Divider(color: Colors.white12, height: 1),
                  _buildItemsList(),
                ],
              ),
            ),
            openBuilder: (context, closeContainer) => Container(), // Not used
          ),
          const SizedBox(height: 8),
        ],

        // Selected item preview
        if (_selectedItem != null) ...[
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.blueAccent.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                _ModernItemThumb(item: _selectedItem!, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Note for: ${_selectedItem!.name}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _selectItem(null),
                  icon: const Icon(
                    Icons.close,
                    size: 16,
                    color: Colors.blueAccent,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Reply target indicator
        Obx(() {
          if (!widget.controller.isReplying) return const SizedBox.shrink();

          final replyTarget = widget.controller.replyTargetNote;
          if (replyTarget == null) return const SizedBox.shrink();

          final listColor = widget.listColor != null
              ? HexColor.fromHex(widget.listColor!)
              : Colors.blue;
          final previewText = replyTarget.content.length > 50
              ? '${replyTarget.content.substring(0, 50)}...'
              : replyTarget.content;

          return Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: listColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: listColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.reply, size: 16, color: listColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Replying to:',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: listColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        previewText,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: widget.controller.cancelReply,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: listColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(Icons.close, size: 14, color: listColor),
                  ),
                ),
              ],
            ),
          );
        }),

        // Input area
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Item selector button
              if (widget.availableItems.isNotEmpty) ...[
                GestureDetector(
                  onTap: _toggleItemSelector,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _showItemSelector
                          ? Colors.blueAccent
                          : Colors.white.withValues(alpha: 0.04),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _showItemSelector
                            ? Colors.blueAccent
                            : Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Icon(
                      _showItemSelector ? Icons.close : Icons.link,
                      color: _showItemSelector ? Colors.white : Colors.white54,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],

              // Text input
              Expanded(
                child: LiquidTextField(
                  controller: widget.controller.noteContentController,
                  focusNode: widget.controller.noteContentFocus,
                  maxLines: null,
                  textInputAction: TextInputAction.newline,
                  hintText: _selectedItem != null
                      ? 'Add a note about ${_selectedItem!.name}...'
                      : (widget.itemId != null
                            ? 'Add a note about this item...'
                            : 'Add a note to this list...'),
                  borderRadius: 16,
                  enableBlur: false,
                  onSubmitted: (_) {
                    ModernUXEnhancements.lightImpact();
                    if (widget.controller.noteContentController.text
                        .trim()
                        .isNotEmpty) {
                      _submitNote();
                    }
                  },
                ),
              ),

              const SizedBox(width: 12),

              // Send button
              GestureDetector(
                onTap: () {
                  if (widget.controller.noteContentController.text
                      .trim()
                      .isNotEmpty) {
                    ModernUXEnhancements.mediumImpact();
                    _submitNote();
                  }
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: textNotEmpty ? Colors.blueAccent : Colors.white12,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: AnimatedRotation(
                    turns: textNotEmpty ? 0 : -0.01,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.send,
                      color: textNotEmpty ? Colors.white : Colors.white38,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGeneralNoteOption() {
    return ListTile(
      dense: true,
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFF2A2E36),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.note_outlined, color: Colors.white54, size: 18),
      ),
      title: Text(
        'General note (no item link)',
        style: GoogleFonts.inter(
          fontSize: 14,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      selected: _selectedItem == null,
      selectedTileColor: Colors.blueAccent.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onTap: () => _selectItem(null),
    );
  }

  Widget _buildItemsList() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 180),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: widget.availableItems.length,
        itemBuilder: (context, index) {
          final item = widget.availableItems[index];
          return AnimatedContainer(
            duration: Duration(milliseconds: 200 + (index * 50)),
            curve: Curves.easeOutCubic,
            child: ListTile(
              dense: true,
              leading: _ModernItemThumb(item: item),
              title: Text(
                item.name,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: item.notes.isNotEmpty
                  ? Text(
                      item.notes,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.white54,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  : null,
              trailing: item.isCompleted
                  ? Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.greenAccent,
                        size: 14,
                      ),
                    )
                  : null,
              selected: _selectedItem?.id == item.id,
              selectedTileColor: Colors.blueAccent.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              onTap: () => _selectItem(item),
            ),
          );
        },
      ),
    );
  }

  void _submitNote() async {
    // Add metadata about linked item if one is selected
    final originalAddNote = widget.controller.addNote;

    // Temporarily override the metadata in the controller
    if (_selectedItem != null) {
      widget.controller.setLinkedItem(_selectedItem!);
    }

    await originalAddNote();

    // Clear selection after successful note
    if (_selectedItem != null) {
      setState(() {
        _selectedItem = null;
      });
    }
  }
}

class _ModernItemThumb extends StatelessWidget {
  final ShoppingListItem item;
  final double size;
  const _ModernItemThumb({required this.item, this.size = 32});

  @override
  Widget build(BuildContext context) {
    final pid = item.productId;
    if (pid == null || pid.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFF2A2E36), const Color(0xFF1E2126)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.shopping_bag_outlined,
          color: Colors.white54,
          size: 16,
        ),
      );
    }

    return FutureBuilder<String?>(
      future: ProductImageCache.instance.getImageUrl(pid),
      builder: (context, snapshot) {
        final url = snapshot.data;
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmer();
        }
        if (url == null || url.isEmpty) {
          return _buildFallback();
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Image.network(
              url,
              key: ValueKey(url),
              width: size,
              height: size,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return _buildShimmer();
              },
              errorBuilder: (_, __, ___) => _buildFallback(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildShimmer() => Container(
    width: size,
    height: size,
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

  Widget _buildFallback() => Container(
    width: size,
    height: size,
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
      size: 16,
      color: Colors.white,
    ),
  );
}
