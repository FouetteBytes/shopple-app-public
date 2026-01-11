import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopple/values/values.dart';
import 'package:shopple/models/product_request_model.dart';
import 'package:shopple/services/product_request/product_request_api.dart';
import 'package:shopple/controllers/user_controller.dart';
import 'package:shopple/widgets/common/liquid_glass.dart';
import 'package:shopple/widgets/requests/request_detail_sheet.dart';
import 'package:shopple/widgets/dark_background/dark_radial_background.dart';
import 'package:shopple/widgets/common/page_header.dart';
import 'package:shopple/widgets/common/segmented_button_picker.dart';
import 'package:shopple/widgets/product_request/product_request_sheet.dart';
import 'package:shopple/widgets/requests/request_card.dart';

/// Request Center - Shows user's product requests with status tracking
class RequestCenterScreen extends StatefulWidget {
  const RequestCenterScreen({super.key});

  @override
  State<RequestCenterScreen> createState() => _RequestCenterScreenState();
}

class _RequestCenterScreenState extends State<RequestCenterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final userController = Get.find<UserController>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = userController.user?.uid;
    if (userId == null) {
      return Scaffold(
        body: Stack(
          children: [
            DarkRadialBackground(
              color: HexColor.fromHex("#181a1f"),
              position: "topLeft",
            ),
            SafeArea(
              child: Center(
                child: Text(
                  'Please log in to view your requests',
                  style: GoogleFonts.poppins(color: AppColors.primaryText),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          DarkRadialBackground(
            color: HexColor.fromHex("#181a1f"),
            position: "topLeft",
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Page Header
                  PageHeader(
                    title: "Request Center",
                    actions: [
                      PageHeaderAction.iconButton(
                        icon: Icons.info_outline,
                        onPressed: () => _showInfoDialog(context),
                        tooltip: 'What is this?',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Segmented Tab Picker
                  SegmentedButtonPicker(
                    controller: _tabController,
                    tabs: [
                      SegmentedTabFactory.simple(
                        text: 'All',
                        icon: Icons.list_alt,
                      ),
                      SegmentedTabFactory.simple(
                        text: 'Pending',
                        icon: Icons.schedule,
                      ),
                      SegmentedTabFactory.simple(
                        text: 'Approved',
                        icon: Icons.check_circle_outline,
                      ),
                      SegmentedTabFactory.simple(
                        text: 'Rejected',
                        icon: Icons.cancel_outlined,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Tab Views
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildRequestsList(userId, null),
                        _buildRequestsList(userId, RequestStatus.pending),
                        _buildRequestsList(userId, RequestStatus.approved),
                        _buildRequestsList(userId, RequestStatus.rejected),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: LiquidGlass(
          borderRadius: 20,
          enableBlur: true,
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title Row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primaryGreen,
                            AppColors.primaryGreen.withValues(alpha: 0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.info_outline,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Request Center',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Content Column
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Track all your product requests in one place!',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.primaryText.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoItem(
                      icon: Icons.add_circle_outline,
                      title: 'Submit Requests',
                      description:
                          'Report product errors, suggest updates, or request new products',
                    ),
                    const SizedBox(height: 12),
                    _buildInfoItem(
                      icon: Icons.track_changes,
                      title: 'Track Progress',
                      description:
                          'Monitor the status of your submissions in real-time',
                    ),
                    const SizedBox(height: 12),
                    _buildInfoItem(
                      icon: Icons.chat_bubble_outline,
                      title: 'Get Responses',
                      description:
                          'Receive admin feedback and updates on your requests',
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Action Button
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen.withValues(
                        alpha: 0.2,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Got it!',
                      style: GoogleFonts.poppins(
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.primaryGreen.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primaryGreen, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppColors.primaryText.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRequestsList(String userId, RequestStatus? filterStatus) {
    return StreamBuilder<List<ProductRequest>>(
      stream: ProductRequestService.streamUserRequests(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.white24,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading requests',
                  style: GoogleFonts.lato(fontSize: 16, color: Colors.white38),
                ),
              ],
            ),
          );
        }

        var requests = snapshot.data ?? [];

        // Filter by status if needed
        if (filterStatus != null) {
          requests = requests.where((r) => r.status == filterStatus).toList();
        }

        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  filterStatus == null
                      ? Icons.inbox_outlined
                      : Icons.filter_list_off,
                  size: 64,
                  color: Colors.white24,
                ),
                const SizedBox(height: 16),
                Text(
                  filterStatus == null
                      ? 'No requests yet'
                      : 'No ${filterStatus.displayName.toLowerCase()} requests',
                  style: GoogleFonts.lato(fontSize: 16, color: Colors.white38),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create your first product request',
                  style: GoogleFonts.lato(fontSize: 14, color: Colors.white24),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            return RequestCard(
              request: request,
              onTap: () => _openRequestDetail(request),
            );
          },
        );
      },
    );
  }

  void _openRequestDetail(ProductRequest request) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RequestDetailSheet(
        request: request,
        onEdit: request.status == RequestStatus.pending
            ? () {
                Navigator.of(context).pop();
                _openEditRequest(request);
              }
            : null,
      ),
    );
  }

  Future<void> _openEditRequest(ProductRequest request) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProductRequestSheet(existingRequest: request),
    );
  }
}
