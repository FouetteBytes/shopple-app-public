import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopple/values/values.dart';
import 'package:shopple/services/category_service.dart';
import 'package:shopple/widgets/buttons/primary_tab_buttons.dart';
import 'package:shopple/widgets/common/liquid_glass.dart';
import 'package:shopple/widgets/common/liquid_text_field.dart';

/// LiquidGlass-styled bottom sheet showing all categories.
/// Returns the selected category id via Navigator.pop(context, id).
class AllCategoriesSheet extends StatefulWidget {
  const AllCategoriesSheet({super.key});

  @override
  State<AllCategoriesSheet> createState() => _AllCategoriesSheetState();
}

class _AllCategoriesSheetState extends State<AllCategoriesSheet> {
  late List<Map<String, String>> _all;
  late List<Map<String, String>> _filtered;
  final TextEditingController _controller = TextEditingController();
  String _segment = 'all'; // all | food | non_food
  final ValueNotifier<int> _segmentNotifier = ValueNotifier(
    0,
  ); // 0=all, 1=food, 2=non-food

  @override
  void initState() {
    super.initState();
    _all = CategoryService.getCategoriesForUI(includeAll: false);
    _filtered = List.from(_all);
    _controller.addListener(() {
      final q = _controller.text.trim().toLowerCase();
      setState(() {
        _filtered = _applyFilters(_all, q, _segment);
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _segmentNotifier.dispose();
    super.dispose();
  }

  List<Map<String, String>> _applyFilters(
    List<Map<String, String>> all,
    String query,
    String segment,
  ) {
    List<Map<String, String>> list = List.from(all);
    if (segment == 'food') {
      list = list
          .where((c) => CategoryService.isFoodCategory(c['id']!))
          .toList();
    } else if (segment == 'non_food') {
      list = list
          .where((c) => CategoryService.isNonFoodCategory(c['id']!))
          .toList();
    }
    if (query.isNotEmpty) {
      list = list
          .where((c) => (c['name'] ?? '').toLowerCase().contains(query))
          .toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    // Enforce bounded height for bottom sheet viewport constraints
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenH = MediaQuery.of(context).size.height;
        final maxH =
            constraints.hasBoundedHeight && constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : screenH * 0.88;
        return SizedBox(
          height: maxH,
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle
                      Center(
                        child: Container(
                          width: 48,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.28),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Text(
                        'All Categories',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // LiquidGlass shell for tabs + search
                      LiquidGlass(
                        enableBlur: true,
                        borderRadius: 16,
                        padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                        gradientColors: [
                          Colors.white.withValues(alpha: 0.12),
                          Colors.white.withValues(alpha: 0.08),
                        ],
                        borderColor: Colors.white.withValues(alpha: 0.12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                PrimaryTabButton(
                                  buttonText: 'All',
                                  itemIndex: 0,
                                  notifier: _segmentNotifier,
                                  callback: () {
                                    setState(() {
                                      _segment = 'all';
                                      _filtered = _applyFilters(
                                        _all,
                                        _controller.text.trim().toLowerCase(),
                                        _segment,
                                      );
                                    });
                                  },
                                ),
                                PrimaryTabButton(
                                  buttonText: 'Food',
                                  itemIndex: 1,
                                  notifier: _segmentNotifier,
                                  callback: () {
                                    setState(() {
                                      _segment = 'food';
                                      _filtered = _applyFilters(
                                        _all,
                                        _controller.text.trim().toLowerCase(),
                                        _segment,
                                      );
                                    });
                                  },
                                ),
                                PrimaryTabButton(
                                  buttonText: 'Non-Food',
                                  itemIndex: 2,
                                  notifier: _segmentNotifier,
                                  callback: () {
                                    setState(() {
                                      _segment = 'non_food';
                                      _filtered = _applyFilters(
                                        _all,
                                        _controller.text.trim().toLowerCase(),
                                        _segment,
                                      );
                                    });
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            LiquidTextField(
                              controller: _controller,
                              hintText: 'Search categories…',
                              borderRadius: 12,
                              prefixIcon: const Icon(Icons.search),
                              enableBlur: false,
                              accentColor: AppColors.primaryText,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              // Grid of categories inside a LiquidGlass panel
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                sliver: SliverToBoxAdapter(
                  child: LiquidGlass(
                    enableBlur: true,
                    // subtler, closer to shopping list creation sheet feel
                    blurSigmaX: 8,
                    blurSigmaY: 12,
                    borderRadius: 18,
                    padding: const EdgeInsets.all(12),
                    gradientColors: [
                      Colors.white.withValues(alpha: 0.07),
                      Colors.white.withValues(alpha: 0.03),
                    ],
                    borderColor: Colors.white.withValues(alpha: 0.08),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.10),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 0.86,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                      itemCount: _filtered.length,
                      itemBuilder: (context, i) {
                        final id = _filtered[i]['id']!;
                        final name = _filtered[i]['name']!;
                        final emoji = _filtered[i]['icon'] ?? '📦';
                        return LiquidGlass(
                          enableBlur: true,
                          blurSigmaX: 10,
                          blurSigmaY: 16,
                          borderRadius: 14,
                          padding: EdgeInsets.zero,
                          gradientColors: [
                            Colors.white.withValues(alpha: 0.07),
                            Colors.white.withValues(alpha: 0.03),
                          ],
                          borderColor: Colors.white.withValues(alpha: 0.08),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 12,
                              offset: const Offset(0, 3),
                            ),
                          ],
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => Navigator.pop(context, id),
                              child: SizedBox.expand(
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        emoji,
                                        style: const TextStyle(fontSize: 22),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        name,
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              // Extra bottom padding for safe area spacing
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
            ],
          ),
        );
      },
    );
  }
}
