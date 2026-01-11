import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopple/values/values.dart';
import 'package:shopple/models/product_request_model.dart';
import 'package:shopple/widgets/common/liquid_glass.dart';
import 'package:shopple/widgets/requests/detail/request_admin_notes.dart';
import 'package:shopple/widgets/requests/detail/request_info_section.dart';
import 'package:shopple/widgets/requests/detail/request_photo_gallery.dart';
import 'package:shopple/widgets/requests/detail/request_status_timeline.dart';
import 'package:shopple/widgets/requests/request_type_extensions.dart';

class RequestDetailSheet extends StatelessWidget {
  final ProductRequest request;
  final VoidCallback? onEdit;

  const RequestDetailSheet({super.key, required this.request, this.onEdit});

  @override
  Widget build(BuildContext context) {
    final bool canEdit = onEdit != null;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: LiquidGlass(
        enableBlur: true,
        borderRadius: 24,
        padding: const EdgeInsets.all(20),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: request.requestType.color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      request.requestType.icon,
                      color: request.requestType.color,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.productName,
                          style: GoogleFonts.lato(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          request.requestType.displayName,
                          style: GoogleFonts.lato(
                            fontSize: 13,
                            color: Colors.white60,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white54),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              RequestStatusTimeline(request: request),
              const SizedBox(height: 16),
              RequestPhotoGallery(photoUrls: request.photoUrls),
              if (request.photoUrls.isNotEmpty) const SizedBox(height: 16),
              RequestInfoSection(request: request),
              const SizedBox(height: 16),
              RequestAdminNotes(notes: request.adminNotes),
              if (canEdit) ...[
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onEdit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.edit_outlined),
                    label: Text(
                      'Edit Request',
                      style: GoogleFonts.lato(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
