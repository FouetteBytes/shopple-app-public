import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopple/values/values.dart';
import 'package:shopple/services/media/profile_picture_service.dart';
import 'package:shopple/services/media/pattern_background_service.dart';
import 'package:shopple/utils/app_logger.dart';
import 'package:shopple/widgets/common/liquid_glass.dart';
import 'package:shopple/widgets/common/liquid_glass_button.dart';

class ProfilePictureSelector extends StatefulWidget {
  final String? currentPicture;
  final Function(String) onPictureSelected;
  final Function(ProfileBackgroundOption?)? onBackgroundSelected;

  const ProfilePictureSelector({
    super.key,
    this.currentPicture,
    required this.onPictureSelected,
    this.onBackgroundSelected,
  });

  @override
  State<ProfilePictureSelector> createState() => _ProfilePictureSelectorState();
}

class _ProfilePictureSelectorState extends State<ProfilePictureSelector>
    with SingleTickerProviderStateMixin {
  String? selectedPicture;
  ProfileBackgroundOption? selectedBackground;
  List<String> memojiList = [];
  List<ProfileBackgroundOption> backgroundColors = [];
  bool isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    selectedPicture = widget.currentPicture;
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final memojis = await ProfilePictureService.getAvailableMemojis();
      final colors = PatternBackgroundService.getPredefinedBackgrounds()
          .where(
            (bg) =>
                bg.type == BackgroundType.solid ||
                bg.type == BackgroundType.gradient,
          )
          .toList();
      if (!mounted) return;
      setState(() {
        memojiList = memojis;
        backgroundColors = colors;
        // Set default background selection to first color if none selected
        if (selectedBackground == null && colors.isNotEmpty) {
          selectedBackground = colors[0];
        }
        isLoading = false;
      });
    } catch (e) {
      AppLogger.w('ProfilePictureSelector: Error loading data: $e');
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 10),

        // Tab Bar
        Container(
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
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorPadding: EdgeInsets.all(4),
                labelColor: Colors.white,
                unselectedLabelColor: Color(0xFF9CA3AF),
                labelStyle: GoogleFonts.lato(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: GoogleFonts.lato(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(text: 'Avatar'),
                  Tab(text: 'Background'),
                ],
              ),
            ),
          ),

          SizedBox(height: 20),

          // Tab Content - Use fixed height instead of Expanded
          SizedBox(
            height: screenHeight * 0.45,
            child: isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primaryAccentColor,
                      ),
                    ),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [_buildAvatarTab(), _buildBackgroundTab()],
                  ),
          ),

          // Select button
          Padding(
            padding: EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: LiquidGlassButton.primary(
                onTap: selectedPicture != null
                    ? () {
                        // If no background is selected, use the first background as default
                        ProfileBackgroundOption? finalBackground =
                            selectedBackground;
                        if (finalBackground == null &&
                            backgroundColors.isNotEmpty) {
                          finalBackground =
                              backgroundColors[0]; // Default to first background
                        }

                        AppLogger.d('ProfilePictureSelector returning:');
                        AppLogger.d('   Picture: $selectedPicture');
                        AppLogger.d(
                          '   Background: ${finalBackground?.name} (${finalBackground?.id})',
                        );

                        // Return both picture and background
                        Navigator.pop(context, {
                          'picture': selectedPicture,
                          'background': finalBackground,
                        });
                      }
                    : null,
                text: "Select Picture",
                isDisabled: selectedPicture == null,
                gradientColors: [
                  AppColors.primaryAccentColor,
                  AppColors.primaryAccentColor.withValues(alpha: 0.8),
                ],
              ),
            ),
          ),
        ],
    );
  }

  Widget _buildAvatarTab() {
    return GridView.builder(
      padding: EdgeInsets.symmetric(horizontal: 20),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1,
      ),
      itemCount: memojiList.length,
      itemBuilder: (context, index) {
        String memojiPath = memojiList[index];
        bool isSelected = selectedPicture == memojiPath;

        return GestureDetector(
          onTap: () {
            setState(() {
              selectedPicture = memojiPath;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? AppColors.primaryAccentColor
                    : Colors.transparent,
                width: 3,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(17),
              child: Image.asset(memojiPath, fit: BoxFit.cover),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBackgroundTab() {
    return GridView.builder(
      padding: EdgeInsets.symmetric(horizontal: 20),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: backgroundColors.length,
      itemBuilder: (context, index) {
        ProfileBackgroundOption background = backgroundColors[index];
        bool isSelected = selectedBackground?.id == background.id;

        return GestureDetector(
          onTap: () {
            setState(() {
              selectedBackground = background;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppColors.primaryAccentColor
                    : const Color(0xFFFFFFFF).withValues(alpha: 0.2),
                width: isSelected ? 3 : 1,
              ),
              gradient: LinearGradient(
                colors: background.colors.isNotEmpty
                    ? background.colors
                    : [Colors.grey],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        );
      },
    );
  }
}
