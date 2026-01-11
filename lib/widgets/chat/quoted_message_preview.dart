import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'package:shopple/values/values.dart';

/// Reusable, themed quoted message preview for both message bubbles and input composer.
class QuotedMessagePreview extends StatelessWidget {
  final Message message;
  final VoidCallback? onClose;
  final bool compact;
  final double? maxWidth;

  const QuotedMessagePreview({
    super.key,
    required this.message,
    this.onClose,
    this.compact = false,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final author = message.user?.name;
    final text = (message.text ?? '').trim();
    final attachments = message.attachments;
    final hasImage =
        attachments.isNotEmpty &&
        attachments.first.type == 'image' &&
        ((attachments.first.imageUrl ??
                    attachments.first.thumbUrl ??
                    attachments.first.assetUrl)
                ?.isNotEmpty ??
            false);
    final imageUrl = attachments.isNotEmpty
        ? (attachments.first.imageUrl ??
              attachments.first.thumbUrl ??
              attachments.first.assetUrl)
        : null;

    final borderColor = AppColors.primaryAccentColor.withValues(alpha: 0.5);
    final bgColor = AppColors.primaryAccentColor.withValues(alpha: 0.10);

    Widget content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 3,
          height: compact ? 44 : 56,
          margin: const EdgeInsets.only(right: 10),
          decoration: BoxDecoration(
            color: AppColors.primaryAccentColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        if (hasImage && imageUrl != null)
          Padding(
            padding: const EdgeInsets.only(right: 8.0, top: 2),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                width: compact ? 36 : 44,
                height: compact ? 36 : 44,
                fit: BoxFit.cover,
              ),
            ),
          ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (author != null && author.isNotEmpty)
                Text(
                  author,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryText,
                  ),
                ),
              if (text.isNotEmpty)
                Text(
                  _truncate(text, 100),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    color: AppColors.secondaryText,
                  ),
                )
              else if (attachments.isNotEmpty)
                Text(
                  '[Attachment]',
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    color: AppColors.secondaryText,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
        ),
        if (onClose != null)
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: InkWell(
              onTap: onClose,
              child: Icon(
                Icons.close,
                size: 18,
                color: AppColors.secondaryText,
              ),
            ),
          ),
      ],
    );

    content = ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: maxWidth ?? MediaQuery.of(context).size.width * 0.7,
      ),
      child: content,
    );

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 0.7),
      ),
      child: content,
    );
  }

  String _truncate(String value, int max) {
    if (value.length <= max) return value;
    return '${value.substring(0, max - 1)}…';
  }
}
