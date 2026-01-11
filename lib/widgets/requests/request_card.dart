import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopple/values/values.dart';
import 'package:shopple/models/product_request_model.dart';
import 'package:shopple/widgets/common/liquid_glass.dart';
import 'package:shopple/widgets/requests/request_type_extensions.dart';

class RequestCard extends StatelessWidget {
  final ProductRequest request;
  final VoidCallback onTap;

  const RequestCard({super.key, required this.request, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final String? heroImage = request.photoUrls.isNotEmpty
        ? request.photoUrls.first
        : null;
    final bool hasPublicNotes = request.adminNotes.any(
      (note) => !note.isPrivate && note.note.trim().isNotEmpty,
    );
    final brand = request.brand;
    final size = request.size;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: GestureDetector(
        onTap: onTap,
        child: LiquidGlass(
          borderRadius: 20,
          padding: EdgeInsets.zero,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ImagePanel(
                    imageUrl: heroImage,
                    fallbackColor: request.requestType.color,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            spacing: 12,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              _TypeChip(request: request),
                              _StatusBadge(status: request.status),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            request.productName,
                            style: GoogleFonts.lato(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if ((brand ?? '').isNotEmpty ||
                              (size ?? '').isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (brand != null && brand.isNotEmpty)
                                  _InfoPill(
                                    icon: Icons.business_outlined,
                                    label: brand,
                                  ),
                                if (size != null && size.isNotEmpty)
                                  _InfoPill(
                                    icon: Icons.straighten_outlined,
                                    label: size,
                                  ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 12),
                          // Use Expanded to push content to bottom if there is extra space, 
                          // but since we are in IntrinsicHeight/Column, we might just want a gap or alignment.
                          // If we want the card to be at least a certain height, we can use ConstrainedBox on the whole card.
                          // For now, let's just ensure there is some spacing.
                          const SizedBox(height: 8),
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.end,
                            spacing: 12,
                            runSpacing: 8,
                            children: [
                              _PriorityChip(priority: request.priority),
                              _RequestMeta(
                                createdAt: request.createdAt,
                                hasPublicNotes: hasPublicNotes,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ImagePanel extends StatelessWidget {
  final String? imageUrl;
  final Color fallbackColor;

  const _ImagePanel({required this.imageUrl, required this.fallbackColor});

  @override
  Widget build(BuildContext context) {
    const double width = 118;
    if (imageUrl == null) {
      return Container(
        width: width,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              fallbackColor.withValues(alpha: 0.6),
              fallbackColor.withValues(alpha: 0.2),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Icon(
          Icons.local_mall_outlined,
          color: Colors.white70,
          size: 32,
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl!,
      width: width,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        width: width,
        color: Colors.white12,
        alignment: Alignment.center,
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        width: width,
        color: Colors.white12,
        alignment: Alignment.center,
        child: const Icon(
          Icons.image_not_supported_outlined,
          color: Colors.white54,
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final ProductRequest request;

  const _TypeChip({required this.request});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: request.requestType.color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            request.requestType.icon,
            size: 14,
            color: request.requestType.color,
          ),
          const SizedBox(width: 6),
          Text(
            request.requestType.displayName,
            style: GoogleFonts.lato(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final RequestStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    final icon = _statusIcon(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            status.displayName,
            style: GoogleFonts.lato(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriorityChip extends StatelessWidget {
  final Priority priority;

  const _PriorityChip({required this.priority});

  @override
  Widget build(BuildContext context) {
    final color = _priorityColor(priority);
    final icon = _priorityIcon(priority);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            priority.displayName,
            style: GoogleFonts.lato(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestMeta extends StatelessWidget {
  final DateTime? createdAt;
  final bool hasPublicNotes;

  const _RequestMeta({required this.createdAt, required this.hasPublicNotes});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatTimeAgo(createdAt),
          style: GoogleFonts.lato(fontSize: 12, color: Colors.white54),
          textAlign: TextAlign.right,
        ),
        if (hasPublicNotes) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 14,
                color: AppColors.primaryGreen,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  'Admin replied',
                  style: GoogleFonts.lato(
                    fontSize: 11,
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white54),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.lato(fontSize: 11, color: Colors.white70),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

Color _statusColor(RequestStatus status) {
  switch (status) {
    case RequestStatus.pending:
      return Colors.orangeAccent;
    case RequestStatus.inReview:
      return Colors.blueAccent;
    case RequestStatus.approved:
      return Colors.greenAccent;
    case RequestStatus.completed:
      return AppColors.primaryGreen;
    case RequestStatus.rejected:
      return Colors.redAccent;
  }
}

IconData _statusIcon(RequestStatus status) {
  switch (status) {
    case RequestStatus.pending:
      return Icons.hourglass_empty;
    case RequestStatus.inReview:
      return Icons.rate_review;
    case RequestStatus.approved:
      return Icons.verified_outlined;
    case RequestStatus.completed:
      return Icons.check_circle_outline;
    case RequestStatus.rejected:
      return Icons.cancel_outlined;
  }
}

Color _priorityColor(Priority priority) {
  switch (priority) {
    case Priority.low:
      return Colors.lightBlueAccent;
    case Priority.normal:
      return Colors.white70;
    case Priority.high:
      return Colors.deepOrangeAccent;
  }
}

IconData _priorityIcon(Priority priority) {
  switch (priority) {
    case Priority.low:
      return Icons.south;
    case Priority.normal:
      return Icons.remove;
    case Priority.high:
      return Icons.north;
  }
}

String _formatTimeAgo(DateTime? timestamp) {
  if (timestamp == null) {
    return 'Just now';
  }
  final now = DateTime.now();
  final difference = now.difference(timestamp);

  if (difference.inDays > 365) {
    final years = (difference.inDays / 365).floor();
    return '$years ${years == 1 ? 'year' : 'years'} ago';
  } else if (difference.inDays > 30) {
    final months = (difference.inDays / 30).floor();
    return '$months ${months == 1 ? 'month' : 'months'} ago';
  } else if (difference.inDays > 0) {
    return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
  } else if (difference.inHours > 0) {
    return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
  } else if (difference.inMinutes > 0) {
    return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
  }
  return 'Just now';
}
