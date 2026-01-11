import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/product_model.dart';
import '../services/category_service.dart';
import '../widgets/skeleton_loader.dart';
import 'package:fl_chart/fl_chart.dart';

import '../widgets/product_request/product_request_sheet.dart';
import '../values/values.dart';
import '../widgets/common/liquid_glass.dart';
import 'package:shopple/controllers/product_details_controller.dart';

class ModernProductDetailsScreen extends StatefulWidget {
  final Product product;
  final List<ProductWithPrices> allProductPrices;

  const ModernProductDetailsScreen({
    super.key,
    required this.product,
    required this.allProductPrices,
  });

  @override
  State<ModernProductDetailsScreen> createState() =>
      _ModernProductDetailsScreenState();
}

class _ModernProductDetailsScreenState extends State<ModernProductDetailsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  late ProductDetailsController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(ProductDetailsController(
      product: widget.product,
      allProductPrices: widget.allProductPrices,
    ));

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
  }



  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(child: _buildContent(context)),
        ],
      ),
      floatingActionButton: _buildRequestButton(context),
    );
  }

  Widget _buildRequestButton(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return FloatingActionButton.extended(
      onPressed: () => _showRequestOptions(context),
      backgroundColor: Theme.of(context).primaryColor,
      elevation: 4,
      icon: Icon(
        Icons.report_problem_outlined,
        color: Colors.white,
        size: isTablet ? 24 : 20,
      ),
      label: Text(
        'Report Issue',
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: isTablet ? 16 : 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showRequestOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: LiquidGlass(
          borderRadius: 20,
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.primaryText.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Title
                Text(
                  'Suggest Product Edit',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText,
                  ),
                ),

                const SizedBox(height: 20),

                // Options
                _buildRequestOption(
                  context,
                  icon: Icons.info_outline,
                  title: 'Update Information',
                  subtitle: 'Suggest information corrections',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.pop(context);
                    _openRequestForm(context, 'Update Information');
                  },
                ),

                _buildRequestOption(
                  context,
                  icon: Icons.price_change_outlined,
                  title: 'Update Price',
                  subtitle: 'Report price changes',
                  color: Colors.green,
                  onTap: () {
                    Navigator.pop(context);
                    _openRequestForm(context, 'Price Update');
                  },
                ),

                _buildRequestOption(
                  context,
                  icon: Icons.flag_outlined,
                  title: 'Report Error',
                  subtitle: 'Something is wrong',
                  color: Colors.orange,
                  onTap: () {
                    Navigator.pop(context);
                    _openRequestForm(context, 'Report Error');
                  },
                ),

                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequestOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: LiquidGlass(
        borderRadius: 12,
        enableBlur: false,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.primaryText.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: AppColors.primaryText.withValues(alpha: 0.3),
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openRequestForm(BuildContext context, String requestType) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProductRequestSheet(
        initialRequestType: requestType,
        preTaggedProduct: widget.product,
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final expandedHeight = isTablet
        ? screenSize.height * 0.4
        : screenSize.height * 0.35;

    return SliverAppBar(
      expandedHeight: expandedHeight,
      pinned: true,
      elevation: 0,
      backgroundColor: Theme.of(context).primaryColor,
      leading: Container(
        margin: EdgeInsets.all(screenSize.width * 0.02),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Colors.white,
            size: isTablet ? 28 : 24,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        Container(
          margin: EdgeInsets.all(screenSize.width * 0.02),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(
              Icons.favorite_border,
              color: Colors.white,
              size: isTablet ? 28 : 24,
            ),
            onPressed: () {
              // Add to favorites logic
            },
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Product Image
            Hero(
              tag: 'product_${widget.product.id}',
              child: CachedNetworkImage(
                imageUrl: widget.product.imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => SkeletonLoader(
                  width: double.infinity,
                  height: expandedHeight,
                  borderRadius: BorderRadius.circular(0),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[300],
                  child: Icon(
                    Icons.image_not_supported,
                    size: isTablet ? 80 : 50,
                  ),
                ),
              ),
            ),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final padding = EdgeInsets.all(isTablet ? 32 : 20);

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Padding(
              padding: padding,
              child: Obx(() => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Info - Shows immediately
                  if (controller.isBasicDataLoaded.value) ...[
                    _buildAnimatedSection(_buildProductInfo()),
                    SizedBox(height: isTablet ? 32 : 24),
                  ] else ...[
                    _buildProductInfoSkeleton(),
                    SizedBox(height: isTablet ? 32 : 24),
                  ],

                  // Price Section - Shows immediately with product data
                  if (controller.isPriceDataLoaded.value) ...[
                    _buildAnimatedSection(_buildPriceSection()),
                    SizedBox(height: isTablet ? 32 : 24),
                    _buildAnimatedSection(_buildStoreComparison()),
                    SizedBox(height: isTablet ? 32 : 24),
                  ] else ...[
                    _buildPriceSectionSkeleton(),
                    SizedBox(height: isTablet ? 32 : 24),
                    _buildStoreComparisonSkeleton(),
                    SizedBox(height: isTablet ? 32 : 24),
                  ],

                  // Price History - Shows when data loads
                  if (controller.isPriceHistoryLoaded.value) ...[
                    _buildAnimatedSection(_buildPriceHistory()),
                    SizedBox(height: isTablet ? 32 : 24),
                  ] else ...[
                    _buildPriceHistorySkeleton(),
                    SizedBox(height: isTablet ? 32 : 24),
                  ],

                  // Statistics - Shows when data loads
                  if (controller.isStatisticsLoaded.value) ...[
                    _buildAnimatedSection(_buildPriceStatistics()),
                  ] else ...[
                    _buildStatisticsSkeleton(),
                  ],

                  SizedBox(height: isTablet ? 48 : 32),
                ],
              )),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductInfo() {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.product.name,
          style: GoogleFonts.inter(
            fontSize: isTablet ? 36 : 28,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.titleLarge?.color,
            height: 1.2,
          ),
        ),
        SizedBox(height: isTablet ? 12 : 8),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 16 : 12,
                vertical: isTablet ? 8 : 6,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                widget.product.brandName,
                style: GoogleFonts.inter(
                  fontSize: isTablet ? 16 : 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 16 : 12,
                vertical: isTablet ? 8 : 6,
              ),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                CategoryService.getDisplayName(widget.product.category),
                style: GoogleFonts.inter(
                  fontSize: isTablet ? 16 : 14,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            ),
          ],
        ),
        if (widget.product.sizeRaw.isNotEmpty) ...[
          SizedBox(height: isTablet ? 16 : 12),
          Row(
            children: [
              Icon(
                Icons.straighten,
                size: isTablet ? 20 : 16,
                color: Colors.grey[600],
              ),
              SizedBox(width: isTablet ? 12 : 8),
              Text(
                widget.product.sizeRaw,
                style: GoogleFonts.inter(
                  fontSize: isTablet ? 18 : 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildPriceSection() {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    final productWithPrices = widget.allProductPrices
        .where((p) => p.product.id == widget.product.id)
        .toList();

    if (productWithPrices.isEmpty) {
      return const SizedBox();
    }

    final product = productWithPrices.first;
    final bestPrice = product.getBestPrice();
    final worstPrice = product.getWorstPrice();

    if (bestPrice == null) {
      return const SizedBox();
    }

    return Container(
      padding: EdgeInsets.all(isTablet ? 24 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withValues(alpha: 0.1),
            Theme.of(context).primaryColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Best Price Available',
            style: GoogleFonts.inter(
              fontSize: isTablet ? 20 : 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.titleMedium?.color,
            ),
          ),
          SizedBox(height: isTablet ? 16 : 12),
          Wrap(
            spacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Rs. ${bestPrice.price.toStringAsFixed(2)}',
                style: GoogleFonts.inter(
                  fontSize: isTablet ? 40 : 32,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              if (worstPrice != null &&
                  worstPrice.price != bestPrice.price) ...[
                Text(
                  'Rs. ${worstPrice.price.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                    fontSize: isTablet ? 22 : 18,
                    decoration: TextDecoration.lineThrough,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: isTablet ? 12 : 8),
          Row(
            children: [
              Icon(
                Icons.store,
                size: isTablet ? 20 : 16,
                color: Colors.grey[600],
              ),
              SizedBox(width: isTablet ? 12 : 8),
              Expanded(
                child: Text(
                  'Available at ${bestPrice.supermarketId}',
                  style: GoogleFonts.inter(
                    fontSize: isTablet ? 16 : 14,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStoreComparison() {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    final productWithPrices = widget.allProductPrices
        .where((p) => p.product.id == widget.product.id)
        .toList();

    if (productWithPrices.isEmpty) {
      return const SizedBox();
    }

    final product = productWithPrices.first;
    final allPrices = product.getAllPrices();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Store Comparison',
          style: GoogleFonts.inter(
            fontSize: isTablet ? 24 : 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        SizedBox(height: isTablet ? 20 : 16),
        ...allPrices.map((price) => _buildStoreCard(price)),
      ],
    );
  }

  Widget _buildStoreCard(CurrentPrice price) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    final productWithPrices = widget.allProductPrices
        .where((p) => p.product.id == widget.product.id)
        .toList();

    if (productWithPrices.isEmpty) {
      return const SizedBox();
    }

    final product = productWithPrices.first;
    final allPrices = product.getAllPrices();
    final isLowest =
        allPrices.isNotEmpty &&
        allPrices.first.supermarketId == price.supermarketId;

    return Container(
      margin: EdgeInsets.only(bottom: isTablet ? 16 : 12),
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: isLowest
            ? Border.all(color: Theme.of(context).primaryColor, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: isTablet ? 60 : 50,
            height: isTablet ? 60 : 50,
            decoration: BoxDecoration(
              color: _getStoreColor(price.supermarketId).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(isTablet ? 30 : 25),
            ),
            child: Icon(
              _getStoreIcon(price.supermarketId),
              color: _getStoreColor(price.supermarketId),
              size: isTablet ? 30 : 24,
            ),
          ),
          SizedBox(width: isTablet ? 20 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getStoreName(price.supermarketId),
                  style: GoogleFonts.inter(
                    fontSize: isTablet ? 18 : 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.titleMedium?.color,
                  ),
                ),
                SizedBox(height: isTablet ? 6 : 4),
                Text(
                  'Updated: ${_formatDate(price.lastUpdated)}',
                  style: GoogleFonts.inter(
                    fontSize: isTablet ? 14 : 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Rs. ${price.price.toStringAsFixed(2)}',
                style: GoogleFonts.inter(
                  fontSize: isTablet ? 22 : 18,
                  fontWeight: FontWeight.bold,
                  color: isLowest
                      ? Theme.of(context).primaryColor
                      : Theme.of(context).textTheme.titleMedium?.color,
                ),
              ),
              if (isLowest) ...[
                SizedBox(height: isTablet ? 6 : 4),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 10 : 8,
                    vertical: isTablet ? 4 : 2,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'BEST',
                    style: GoogleFonts.inter(
                      fontSize: isTablet ? 12 : 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceHistory() {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    if (controller.priceHistory.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Price History',
            style: GoogleFonts.inter(
              fontSize: isTablet ? 24 : 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
          SizedBox(height: isTablet ? 20 : 16),
          Container(
            padding: EdgeInsets.all(isTablet ? 24 : 20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'No price history available',
              style: GoogleFonts.inter(
                fontSize: isTablet ? 18 : 16,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Price History (6 Months)',
          style: GoogleFonts.inter(
            fontSize: isTablet ? 24 : 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        SizedBox(height: isTablet ? 20 : 16),
        Container(
          height: isTablet ? 350 : 250,
          padding: EdgeInsets.all(isTablet ? 20 : 16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: _buildPriceChart(),
        ),
      ],
    );
  }

  Widget _buildPriceChart() {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    final allData = <FlSpot>[];
    final storeColors = <String, Color>{
      'cargills': Colors.red,
      'keells': Colors.green,
      'arpico': Colors.blue,
    };

    double maxY = 0;
    double minY = double.infinity;

    // Collect all data points
    for (final storeEntry in controller.priceHistory.entries) {
      for (int i = 0; i < storeEntry.value.length; i++) {
        final history = storeEntry.value[i];
        final avgPrice = history.monthSummary.avgPrice;
        if (avgPrice > 0) {
          allData.add(FlSpot(i.toDouble(), avgPrice));
          maxY = maxY < avgPrice ? avgPrice : maxY;
          minY = minY > avgPrice ? avgPrice : minY;
        }
      }
    }

    // Handle edge cases for minY and maxY
    if (minY == double.infinity) {
      minY = 0;
    }
    if (maxY == 0 && minY == 0) {
      maxY = 100; // Default range if no data
    }

    if (allData.isEmpty) {
      return Center(
        child: Text(
          'No chart data available',
          style: GoogleFonts.inter(
            fontSize: isTablet ? 18 : 16,
            color: Colors.grey[600],
          ),
        ),
      );
    }

    final padding = (maxY - minY) * 0.1;

    // Ensure we have a minimum interval to prevent division by zero
    final priceRange = maxY - minY;
    final horizontalInterval = priceRange > 0 ? priceRange / 4 : maxY / 4;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: horizontalInterval > 0 ? horizontalInterval : 1.0,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withValues(alpha: 0.2),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: isTablet ? 40 : 30,
              getTitlesWidget: (value, meta) {
                final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
                if (value.toInt() < monthNames.length) {
                  return Text(
                    monthNames[value.toInt()],
                    style: GoogleFonts.inter(
                      fontSize: isTablet ? 14 : 12,
                      color: Colors.grey[600],
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: isTablet ? 60 : 50,
              getTitlesWidget: (value, meta) {
                return Text(
                  'Rs.${value.toInt()}',
                  style: GoogleFonts.inter(
                    fontSize: isTablet ? 12 : 10,
                    color: Colors.grey[600],
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: 5,
        minY: minY - padding,
        maxY: maxY + padding,
        lineBarsData: controller.priceHistory.entries.map((storeEntry) {
          final spots = <FlSpot>[];
          for (int i = 0; i < storeEntry.value.length; i++) {
            final history = storeEntry.value[i];
            if (history.monthSummary.avgPrice > 0) {
              spots.add(FlSpot(i.toDouble(), history.monthSummary.avgPrice));
            }
          }

          return LineChartBarData(
            spots: spots,
            isCurved: true,
            color: storeColors[storeEntry.key] ?? Colors.grey,
            barWidth: isTablet ? 4 : 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: isTablet ? 5 : 4,
                  color: barData.color!,
                  strokeColor: Colors.white,
                  strokeWidth: 2,
                );
              },
            ),
            belowBarData: BarAreaData(show: false),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPriceStatistics() {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    if (controller.priceStatistics.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Price Analytics',
          style: GoogleFonts.inter(
            fontSize: isTablet ? 24 : 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        SizedBox(height: isTablet ? 20 : 16),
        Container(
          padding: EdgeInsets.all(isTablet ? 24 : 20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildStatRow(
                'Average Price',
                'Rs. ${controller.priceStatistics['averagePrice']?.toStringAsFixed(2) ?? '0.00'}',
              ),
              _buildStatRow(
                'Lowest Price',
                'Rs. ${controller.priceStatistics['lowestPrice']?.toStringAsFixed(2) ?? '0.00'}',
              ),
              _buildStatRow(
                'Highest Price',
                'Rs. ${controller.priceStatistics['highestPrice']?.toStringAsFixed(2) ?? '0.00'}',
              ),
              _buildStatRow(
                'Price Volatility',
                '${controller.priceStatistics['priceVolatility']?.toStringAsFixed(1) ?? '0.0'}%',
              ),
              _buildStatRow(
                'Trend Direction',
                controller.priceStatistics['trendDirection'] ?? 'stable',
              ),
              if (controller.priceStatistics['bestMonth']?.isNotEmpty == true)
                _buildStatRow('Best Month', controller.priceStatistics['bestMonth']),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: isTablet ? 12 : 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: isTablet ? 16 : 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: GoogleFonts.inter(
                fontSize: isTablet ? 16 : 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.titleMedium?.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedSection(Widget child) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 500),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: child,
    );
  }

  // Skeleton loading methods for progressive loading
  Widget _buildProductInfoSkeleton() {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SkeletonLoader(
          width: double.infinity,
          height: isTablet ? 40 : 32,
          borderRadius: BorderRadius.circular(8),
        ),
        SizedBox(height: isTablet ? 12 : 8),
        Row(
          children: [
            SkeletonLoader(
              width: isTablet ? 120 : 100,
              height: isTablet ? 32 : 28,
              borderRadius: BorderRadius.circular(20),
            ),
            const SizedBox(width: 12),
            SkeletonLoader(
              width: isTablet ? 100 : 80,
              height: isTablet ? 32 : 28,
              borderRadius: BorderRadius.circular(20),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPriceSectionSkeleton() {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return Container(
      padding: EdgeInsets.all(isTablet ? 24 : 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonLoader(
            width: isTablet ? 200 : 150,
            height: isTablet ? 20 : 16,
            borderRadius: BorderRadius.circular(8),
          ),
          SizedBox(height: isTablet ? 16 : 12),
          SkeletonLoader(
            width: isTablet ? 180 : 140,
            height: isTablet ? 40 : 32,
            borderRadius: BorderRadius.circular(8),
          ),
          SizedBox(height: isTablet ? 12 : 8),
          SkeletonLoader(
            width: isTablet ? 160 : 120,
            height: isTablet ? 16 : 14,
            borderRadius: BorderRadius.circular(8),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreComparisonSkeleton() {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SkeletonLoader(
          width: isTablet ? 200 : 150,
          height: isTablet ? 24 : 20,
          borderRadius: BorderRadius.circular(8),
        ),
        SizedBox(height: isTablet ? 20 : 16),
        ...List.generate(
          3,
          (index) => Container(
            margin: EdgeInsets.only(bottom: isTablet ? 16 : 12),
            padding: EdgeInsets.all(isTablet ? 20 : 16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                SkeletonLoader(
                  width: isTablet ? 60 : 50,
                  height: isTablet ? 60 : 50,
                  borderRadius: BorderRadius.circular(isTablet ? 30 : 25),
                ),
                SizedBox(width: isTablet ? 20 : 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonLoader(
                        width: isTablet ? 120 : 100,
                        height: isTablet ? 18 : 16,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      SizedBox(height: isTablet ? 6 : 4),
                      SkeletonLoader(
                        width: isTablet ? 100 : 80,
                        height: isTablet ? 14 : 12,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ],
                  ),
                ),
                SkeletonLoader(
                  width: isTablet ? 80 : 60,
                  height: isTablet ? 22 : 18,
                  borderRadius: BorderRadius.circular(8),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceHistorySkeleton() {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SkeletonLoader(
          width: isTablet ? 250 : 200,
          height: isTablet ? 24 : 20,
          borderRadius: BorderRadius.circular(8),
        ),
        SizedBox(height: isTablet ? 20 : 16),
        Container(
          height: isTablet ? 350 : 250,
          padding: EdgeInsets.all(isTablet ? 20 : 16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: SkeletonLoader(
            width: double.infinity,
            height: double.infinity,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsSkeleton() {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SkeletonLoader(
          width: isTablet ? 200 : 150,
          height: isTablet ? 24 : 20,
          borderRadius: BorderRadius.circular(8),
        ),
        SizedBox(height: isTablet ? 20 : 16),
        Container(
          padding: EdgeInsets.all(isTablet ? 24 : 20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: List.generate(
              5,
              (index) => Padding(
                padding: EdgeInsets.symmetric(vertical: isTablet ? 12 : 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SkeletonLoader(
                      width: isTablet ? 120 : 100,
                      height: isTablet ? 16 : 14,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    SkeletonLoader(
                      width: isTablet ? 80 : 60,
                      height: isTablet ? 16 : 14,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getStoreColor(String store) {
    switch (store.toLowerCase()) {
      case 'cargills':
        return Colors.red;
      case 'keells':
        return Colors.green;
      case 'arpico':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getStoreIcon(String store) {
    switch (store.toLowerCase()) {
      case 'cargills':
        return Icons.store;
      case 'keells':
        return Icons.shopping_cart;
      case 'arpico':
        return Icons.local_grocery_store;
      default:
        return Icons.store;
    }
  }

  String _getStoreName(String store) {
    switch (store.toLowerCase()) {
      case 'cargills':
        return 'Cargills Food City';
      case 'keells':
        return 'Keells Super';
      case 'arpico':
        return 'Arpico Supercenter';
      default:
        return store;
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Unknown';
    }
  }
}
