import 'package:flutter/material.dart';
import '../../services/media/pattern_background_service.dart';
import '../../values/values.dart';
import '../common/liquid_glass.dart';
import '../pattern_background/pattern_selection_grid.dart';

/// Phase 4.2.B: Bottom Sheet Design
/// Uses existing BottomSheetHolder and follows existing bottom sheet patterns
/// Reuses existing header styling and close button design
/// Maintains existing scrolling behavior and layout

class PatternSelectionBottomSheet extends StatefulWidget {
  final ProfileBackgroundOption? currentBackground;
  final Function(ProfileBackgroundOption) onBackgroundSelected;
  final VoidCallback? onClose;

  const PatternSelectionBottomSheet({
    super.key,
    this.currentBackground,
    required this.onBackgroundSelected,
    this.onClose,
  });

  @override
  State<PatternSelectionBottomSheet> createState() =>
      _PatternSelectionBottomSheetState();
}

class _PatternSelectionBottomSheetState
    extends State<PatternSelectionBottomSheet>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<ProfileBackgroundOption> _allPatterns = [];
  List<ProfileBackgroundOption> _solidPatterns = [];
  List<ProfileBackgroundOption> _patternBackgrounds = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
    ); // Changed from 3 to 2
    _loadPatterns();
  }

  void _loadPatterns() {
    _allPatterns = PatternBackgroundService.getPredefinedBackgrounds();
    _solidPatterns = _allPatterns
        .where(
          (p) =>
              p.type == BackgroundType.solid ||
              p.type == BackgroundType.gradient,
        )
        .toList();
    _patternBackgrounds = _allPatterns
        .where((p) => p.type == BackgroundType.pattern)
        .toList();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color:
            AppColors.primaryBackgroundColor, // Use existing background color
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ), // Existing corner radius
      ),
      child: Column(
        children: [
          // Handle bar - using existing component
          Container(
            margin: EdgeInsets.symmetric(vertical: 12),
          ),

          // Header - following existing header styling
          _buildHeader(),

          // Tab Bar - following existing tab styling
          _buildTabBar(),

          SizedBox(height: 20),

          // Tab Content - maintaining existing scrolling behavior
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildColorsTab(), _buildPatternsTab()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Icon(
            Icons.palette_outlined,
            color: AppColors.primaryAccentColor,
            size: 24,
          ),
          SizedBox(width: 12),
          Text(
            'Choose Background Pattern',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white, // Existing text style
            ),
          ),
          Spacer(),
          // Existing close button design
          IconButton(
            onPressed: widget.onClose,
            icon: Icon(
              Icons.close,
              color: Colors.white.withValues(alpha: 0.7),
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      child: LiquidGlass(
        borderRadius: 12,
        enableBlur: true,
        blurSigmaX: 12,
        blurSigmaY: 18,
        gradientColors: [
          Colors.white.withValues(alpha: 0.08),
          Colors.white.withValues(alpha: 0.03),
        ],
        borderColor: Colors.white.withValues(alpha: 0.10),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: AppColors.primaryAccentColor,
            borderRadius: BorderRadius.circular(10),
          ),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
          labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          tabs: [
            Tab(text: 'Colors'),
            Tab(text: 'Patterns'),
          ],
        ),
      ),
    );
  }

  Widget _buildColorsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: PatternSelectionGrid(
        currentSelection: widget.currentBackground,
        onPatternSelected: widget.onBackgroundSelected,
        patterns: _solidPatterns,
      ),
    );
  }

  Widget _buildPatternsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Premium notice for patterns
          _buildNoticeCard(
            icon: Icons.star,
            iconColor: Colors.amber,
            message: 'Geometric patterns available. Some require premium.',
          ),
          PatternSelectionGrid(
            currentSelection: widget.currentBackground,
            onPatternSelected: widget.onBackgroundSelected,
            patterns: _patternBackgrounds,
          ),
        ],
      ),
    );
  }

  Widget _buildNoticeCard({
    required IconData icon,
    required Color iconColor,
    required String message,
  }) {
    return LiquidGlass(
      borderRadius: 10,
      enableBlur: true,
      blurSigmaX: 10,
      blurSigmaY: 16,
      gradientColors: [
        Colors.white.withValues(alpha: 0.08),
        Colors.white.withValues(alpha: 0.03),
      ],
      borderColor: Colors.white.withValues(alpha: 0.10),
      child: Container(
        padding: EdgeInsets.all(12),
        margin: EdgeInsets.only(bottom: 20),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
