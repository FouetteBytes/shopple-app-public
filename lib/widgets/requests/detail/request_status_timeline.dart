import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopple/values/values.dart';
import 'package:shopple/models/product_request_model.dart';

class RequestStatusTimeline extends StatelessWidget {
  final ProductRequest request;

  const RequestStatusTimeline({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    final status = request.status;
    final steps = <_TimelineStep>[
      const _TimelineStep('Submitted', Icons.upload_outlined, true),
      _TimelineStep(
        'Reviewing',
        Icons.rate_review_outlined,
        status != RequestStatus.pending,
      ),
      _TimelineStep(
        'Completed',
        Icons.verified_outlined,
        status == RequestStatus.approved || status == RequestStatus.completed,
      ),
    ];

    final rejection = status == RequestStatus.rejected;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status',
          style: GoogleFonts.lato(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: steps.map((step) {
            final isActive = step.isActive && !rejection;
            return Expanded(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: isActive
                        ? AppColors.primaryGreen
                        : Colors.white10,
                    child: Icon(
                      step.icon,
                      size: 18,
                      color: isActive ? Colors.white : Colors.white38,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    step.label,
                    style: GoogleFonts.lato(
                      fontSize: 11,
                      color: isActive ? Colors.white : Colors.white38,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        if (rejection)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.redAccent.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.cancel_outlined,
                    color: Colors.redAccent,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'This request was rejected. Check admin notes for details.',
                      style: GoogleFonts.lato(
                        fontSize: 12,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _TimelineStep {
  final String label;
  final IconData icon;
  final bool isActive;

  const _TimelineStep(this.label, this.icon, this.isActive);
}
