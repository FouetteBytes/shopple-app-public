import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shopple/values/values.dart';
import 'package:shopple/services/analytics/enhanced_search_analytics_service.dart';
import 'package:shopple/utils/app_logger.dart';
import 'package:shopple/services/category_service.dart';

class PersonalizedDefaultContent extends StatelessWidget {
  final PersonalizedSearchData personalizedData;
  final Function(String) onQueryTapped;
  final Function(String) onCategoryTapped; // expects categoryId
  final void Function(PersonalizedProduct)? onRecommendationTap;

  const PersonalizedDefaultContent({
    super.key,
    required this.personalizedData,
    required this.onQueryTapped,
    required this.onCategoryTapped,
    this.onRecommendationTap,
  });

  @override
  Widget build(BuildContext context) {
    if (personalizedData.topQueries.isEmpty &&
        personalizedData.recommendations.isEmpty) {
      return _firstTime(context);
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting and inline recent searches removed from Search page
          if (personalizedData.recommendations.isNotEmpty) ...[
            _recommendations(context),
            const SizedBox(height: 24),
          ],
          if (personalizedData.userPreferences.topCategories.isNotEmpty) ...[
            _favoriteCategories(context),
          ],
        ],
      ),
    );
  }

  Widget _recommendations(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.recommend,
              color: AppColors.primaryAccentColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Recommended for You',
                style: GoogleFonts.inter(
                  color: AppColors.primaryText,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                // Surface a simple callback via a synthetic query or dedicated route at call site
                // Using query tap to keep the widget contract minimal
                onQueryTapped('');
              },
              child: Text(
                'See all',
                style: GoogleFonts.inter(
                  color: AppColors.primaryAccentColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.78,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: personalizedData.recommendations.take(4).length,
          itemBuilder: (context, index) {
            final p = personalizedData.recommendations[index];
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  if (onRecommendationTap != null) {
                    onRecommendationTap!(p);
                  } else {
                    onQueryTapped(p.name);
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primaryText.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product image
                      AspectRatio(
                        aspectRatio: 16 / 9,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                          child: p.imageUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: p.imageUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) =>
                                      Container(color: AppColors.background),
                                  errorWidget: (context, url, error) =>
                                      Container(
                                        color: AppColors.background,
                                        child: Icon(
                                          Icons.image_not_supported,
                                          color: AppColors.primaryText
                                              .withValues(alpha: 0.3),
                                        ),
                                      ),
                                )
                              : Container(
                                  color: AppColors.background,
                                  child: Center(
                                    child: Icon(
                                      Icons.shopping_basket_rounded,
                                      color: AppColors.primaryText.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.name,
                              style: GoogleFonts.inter(
                                color: AppColors.primaryText,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            if (p.brandName.isNotEmpty)
                              Text(
                                p.brandName,
                                style: GoogleFonts.inter(
                                  color: AppColors.primaryText70,
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _favoriteCategories(BuildContext context) {
    // Debug: Use AppLogger in debug-only
    AppLogger.d('🔍 [UI_DEBUG] Displaying favorite categories:');
    AppLogger.d('🔍 [UI_DEBUG] Data source: ${personalizedData.source}');
    AppLogger.d(
      '🔍 [UI_DEBUG] Number of categories: ${personalizedData.userPreferences.topCategories.length}',
    );
    for (
      int i = 0;
      i < personalizedData.userPreferences.topCategories.length && i < 5;
      i++
    ) {
      final c = personalizedData.userPreferences.topCategories[i];
      AppLogger.d(
        '🔍 [UI_DEBUG] Category ${i + 1}: ${c['name']} (${c['frequency']})',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.favorite, color: AppColors.primaryAccentColor, size: 20),
            const SizedBox(width: 8),
            Text(
              'Your Favorite Categories',
              style: GoogleFonts.inter(
                color: AppColors.primaryText,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            // Add data source indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: personalizedData.source == 'cloud'
                    ? Colors.green.withValues(alpha: 0.2)
                    : Colors.orange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                personalizedData.source.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: personalizedData.source == 'cloud'
                      ? Colors.green
                      : Colors.orange,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: personalizedData.userPreferences.topCategories.take(6).map((
            c,
          ) {
            final name = c['name'] as String; // display name
            // frequency can be int or double depending on backend; format safely
            final num freqNum = (c['frequency'] is num)
                ? c['frequency'] as num
                : 0;
            // Normalize large frequencies to a more readable format
            String freqText;
            if (freqNum >= 100) {
              freqText =
                  '${(freqNum / 10).round()}%'; // Convert to percentage-like display
            } else if (freqNum >= 10) {
              freqText = '${freqNum.round()}';
            } else if (freqNum % 1 == 0) {
              freqText = freqNum.toInt().toString();
            } else {
              freqText = freqNum.toStringAsFixed(1);
            }
            final id = CategoryService.getCategoryId(name);
            final emoji = CategoryService.getCategoryIcon(id);
            return InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => onCategoryTapped(id),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primaryText.withValues(alpha: 0.08),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      name,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryAccentColor.withValues(
                          alpha: 0.1,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        freqText,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: AppColors.primaryAccentColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _firstTime(BuildContext context) {
    // Scrollable to avoid overflow on small viewports
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: AppColors.primaryAccentColor),
            const SizedBox(height: 16),
            Text(
              'Start searching to get personalized\nrecommendations',
              style: GoogleFonts.inter(
                color: AppColors.primaryText,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Your frequently searched products and brands will appear here',
              style: GoogleFonts.inter(
                color: AppColors.primaryText70,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Text(
              'Quick Search',
              style: GoogleFonts.inter(
                color: AppColors.primaryText,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _quickSearchButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _quickSearchButtons(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 3,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _quickButton('🍚 Rice & Grains', () => onCategoryTapped('rice_grains')),
        _quickButton('🥤 Beverages', () => onCategoryTapped('beverages')),
        _quickButton('🍿 Snacks', () => onCategoryTapped('snacks')),
        _quickButton('🧀 Dairy', () => onCategoryTapped('dairy')),
      ],
    );
  }

  Widget _quickButton(String label, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.inactive.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: AppColors.primaryText,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
