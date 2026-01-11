import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopple/models/product_request_model.dart';

class RequestInfoSection extends StatelessWidget {
  final ProductRequest request;

  const RequestInfoSection({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    final entries = <_InfoEntry>[
      _InfoEntry('Brand', request.brand),
      _InfoEntry('Size', request.size),
      _InfoEntry('Store', request.store),
      _InfoEntry('Branch', request.storeLocation?.branch),
      _InfoEntry('Priority', request.priority.displayName),
      _InfoEntry('Description', request.description),
      if (request.taggedProductId != null)
        _InfoEntry('Tagged Product ID', request.taggedProductId),
    ];

    final issue = request.issue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Request Details',
          style: GoogleFonts.lato(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 12),
        ...entries
            .where((entry) => entry.value != null && entry.value!.isNotEmpty)
            .map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _InfoRow(label: entry.label, value: entry.value!),
              ),
            ),
        if (issue != null) _IssueDetails(issue: issue),
      ],
    );
  }
}

class _InfoEntry {
  final String label;
  final String? value;

  _InfoEntry(this.label, this.value);
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: GoogleFonts.lato(fontSize: 12, color: Colors.white54),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.lato(fontSize: 13, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class _IssueDetails extends StatelessWidget {
  final ProductIssue issue;

  const _IssueDetails({required this.issue});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reported Issues',
          style: GoogleFonts.lato(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: issue.issueTypes
              .map(
                (type) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    type.displayName,
                    style: GoogleFonts.lato(
                      fontSize: 12,
                      color: Colors.orangeAccent,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 12),
        _IssueRow(
          label: 'Incorrect Name',
          value: issue.incorrectName,
          highlight: true,
        ),
        _IssueRow(label: 'Correct Name', value: issue.correctName),
        _IssueRow(
          label: 'Incorrect Price',
          value: issue.incorrectPrice,
          highlight: true,
        ),
        _IssueRow(label: 'Correct Price', value: issue.correctPrice),
        _IssueRow(
          label: 'Incorrect Size',
          value: issue.incorrectSize,
          highlight: true,
        ),
        _IssueRow(label: 'Correct Size', value: issue.correctSize),
        _IssueRow(
          label: 'Incorrect Brand',
          value: issue.incorrectBrand,
          highlight: true,
        ),
        _IssueRow(label: 'Correct Brand', value: issue.correctBrand),
        _IssueRow(label: 'Extra Details', value: issue.additionalDetails),
      ],
    );
  }
}

class _IssueRow extends StatelessWidget {
  final String label;
  final String? value;
  final bool highlight;

  const _IssueRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final textColor = highlight ? Colors.orangeAccent : Colors.white;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: GoogleFonts.lato(fontSize: 12, color: Colors.white54),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value!,
              style: GoogleFonts.lato(fontSize: 13, color: textColor),
            ),
          ),
        ],
      ),
    );
  }
}
