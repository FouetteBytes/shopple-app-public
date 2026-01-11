import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shopple/utils/app_logger.dart';
import 'package:pattern_box/pattern_box.dart';
import '../../values/values.dart';

/// Phase 4.1: Service Layer using pre-built libraries (NOT custom painting)
/// Follows existing app architecture and patterns

enum BackgroundType { solid, gradient, pattern, animated }

enum PatternType {
  geometric,
  honeycomb,
  circuit,
  wave,
  mosaic,
  circles,
  diamonds,
}

class ProfileBackgroundOption {
  final String id;
  final String name;
  final BackgroundType type;
  final PatternType? patternType;
  final List<Color> colors;
  final String? description;
  final bool isPremium;
  final Map<String, dynamic>? patternConfig;

  const ProfileBackgroundOption({
    required this.id,
    required this.name,
    required this.type,
    this.patternType,
    this.colors = const [],
    this.description,
    this.isPremium = false,
    this.patternConfig,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.toString(),
      'patternType': patternType?.toString(),
      'colors': colors.map((c) => c.toARGB32()).toList(),
      'description': description,
      'isPremium': isPremium,
      'patternConfig': patternConfig,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory ProfileBackgroundOption.fromMap(Map<String, dynamic> map) {
    return ProfileBackgroundOption(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      type: BackgroundType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => BackgroundType.solid,
      ),
      patternType: map['patternType'] != null
          ? PatternType.values.firstWhere(
              (e) => e.toString() == map['patternType'],
              orElse: () => PatternType.geometric,
            )
          : null,
      colors: map['colors'] != null
          ? (map['colors'] as List).map((c) => Color(c)).toList()
          : [],
      description: map['description'],
      isPremium: map['isPremium'] ?? false,
      patternConfig: map['patternConfig'],
    );
  }
}

class PatternBackgroundService {
  /// Get predefined background options using pre-built libraries
  static List<ProfileBackgroundOption> getPredefinedBackgrounds() {
    return [
      // Remove duplicates and create a curated list of diverse colors

      // Vibrant Colors
      ProfileBackgroundOption(
        id: 'solid_coral',
        name: 'Coral Sunset',
        type: BackgroundType.solid,
        colors: [HexColor.fromHex("FF6B9D"), HexColor.fromHex("FFB84D")],
        description: 'Vibrant coral sunset',
      ),
      ProfileBackgroundOption(
        id: 'solid_ocean',
        name: 'Ocean Blue',
        type: BackgroundType.solid,
        colors: [HexColor.fromHex("2DD4BF"), HexColor.fromHex("06B6D4")],
        description: 'Fresh ocean colors',
      ),
      ProfileBackgroundOption(
        id: 'solid_forest',
        name: 'Forest Green',
        type: BackgroundType.solid,
        colors: [HexColor.fromHex("10B981"), HexColor.fromHex("34D399")],
        description: 'Natural forest green',
      ),
      ProfileBackgroundOption(
        id: 'solid_purple',
        name: 'Galaxy Purple',
        type: BackgroundType.solid,
        colors: [HexColor.fromHex("667EEA"), HexColor.fromHex("764BA2")],
        description: 'Deep galaxy purple',
      ),

      // Warm Tones
      ProfileBackgroundOption(
        id: 'solid_rose',
        name: 'Rose Gold',
        type: BackgroundType.solid,
        colors: [HexColor.fromHex("F43F5E"), HexColor.fromHex("EC4899")],
        description: 'Elegant rose gold',
      ),
      ProfileBackgroundOption(
        id: 'solid_citrus',
        name: 'Citrus Burst',
        type: BackgroundType.solid,
        colors: [HexColor.fromHex("FDE047"), HexColor.fromHex("FB923C")],
        description: 'Bright citrus energy',
      ),
      ProfileBackgroundOption(
        id: 'solid_peach',
        name: 'Peach Dream',
        type: BackgroundType.solid,
        colors: [HexColor.fromHex("FBBF24"), HexColor.fromHex("F97316")],
        description: 'Soft peach gradient',
      ),

      // Cool Tones
      ProfileBackgroundOption(
        id: 'solid_indigo',
        name: 'Royal Indigo',
        type: BackgroundType.solid,
        colors: [HexColor.fromHex("6366F1"), HexColor.fromHex("8B5CF6")],
        description: 'Royal indigo gradient',
      ),
      ProfileBackgroundOption(
        id: 'solid_midnight',
        name: 'Midnight Blue',
        type: BackgroundType.solid,
        colors: [HexColor.fromHex("1E293B"), HexColor.fromHex("334155")],
        description: 'Deep midnight blue',
      ),
      ProfileBackgroundOption(
        id: 'solid_emerald',
        name: 'Emerald',
        type: BackgroundType.solid,
        colors: [HexColor.fromHex("059669"), HexColor.fromHex("047857")],
        description: 'Rich emerald green',
      ),

      // Pastel Colors
      ProfileBackgroundOption(
        id: 'solid_lavender',
        name: 'Lavender',
        type: BackgroundType.solid,
        colors: [HexColor.fromHex("C4B5FD"), HexColor.fromHex("A78BFA")],
        description: 'Soft lavender',
      ),
      ProfileBackgroundOption(
        id: 'solid_mint',
        name: 'Mint Fresh',
        type: BackgroundType.solid,
        colors: [HexColor.fromHex("6EE7B7"), HexColor.fromHex("34D399")],
        description: 'Fresh mint green',
      ),
      ProfileBackgroundOption(
        id: 'solid_blush',
        name: 'Blush Pink',
        type: BackgroundType.solid,
        colors: [HexColor.fromHex("FBBF24"), HexColor.fromHex("F472B6")],
        description: 'Soft blush pink',
      ),

      // Bold Colors
      ProfileBackgroundOption(
        id: 'solid_crimson',
        name: 'Crimson Red',
        type: BackgroundType.solid,
        colors: [HexColor.fromHex("DC2626"), HexColor.fromHex("B91C1C")],
        description: 'Bold crimson red',
      ),
      ProfileBackgroundOption(
        id: 'solid_electric',
        name: 'Electric Blue',
        type: BackgroundType.solid,
        colors: [HexColor.fromHex("3B82F6"), HexColor.fromHex("1D4ED8")],
        description: 'Electric blue energy',
      ),
      ProfileBackgroundOption(
        id: 'solid_amber',
        name: 'Golden Amber',
        type: BackgroundType.solid,
        colors: [HexColor.fromHex("F59E0B"), HexColor.fromHex("D97706")],
        description: 'Rich golden amber',
      ),

      // Pattern backgrounds using pattern_box - expanded selection
      ProfileBackgroundOption(
        id: 'pattern_geometric',
        name: 'Geometric Grid',
        type: BackgroundType.pattern,
        patternType: PatternType.geometric,
        colors: AppColors.ballColors[0],
        description: 'Modern square patterns',
      ),
      ProfileBackgroundOption(
        id: 'pattern_diamonds',
        name: 'Diamond Pattern',
        type: BackgroundType.pattern,
        patternType: PatternType.diamonds,
        colors: AppColors.ballColors[1],
        description: 'Elegant diamond shapes',
        isPremium: true,
      ),
      ProfileBackgroundOption(
        id: 'pattern_circles',
        name: 'Concentric Circles',
        type: BackgroundType.pattern,
        patternType: PatternType.circles,
        colors: AppColors.ballColors[2],
        description: 'Hypnotic circle patterns',
        isPremium: true,
      ),
      ProfileBackgroundOption(
        id: 'pattern_honeycomb',
        name: 'Honeycomb',
        type: BackgroundType.pattern,
        patternType: PatternType.honeycomb,
        colors: [
          AppColors.primaryAccentColor,
          AppColors.lightMauveBackgroundColor,
        ],
        description: 'Beautiful honeycomb pattern',
        isPremium: true,
      ),
      ProfileBackgroundOption(
        id: 'pattern_wave',
        name: 'Ocean Waves',
        type: BackgroundType.pattern,
        patternType: PatternType.wave,
        colors: AppColors.ballColors[4],
        description: 'Gentle wave patterns',
      ),

      // Additional pattern variations with different colors
      ProfileBackgroundOption(
        id: 'pattern_geometric_coral',
        name: 'Coral Grid',
        type: BackgroundType.pattern,
        patternType: PatternType.geometric,
        colors: [HexColor.fromHex("FF6B9D"), HexColor.fromHex("FFB84D")],
        description: 'Geometric grid with coral colors',
      ),
      ProfileBackgroundOption(
        id: 'pattern_diamonds_teal',
        name: 'Teal Diamonds',
        type: BackgroundType.pattern,
        patternType: PatternType.diamonds,
        colors: [HexColor.fromHex("2DD4BF"), HexColor.fromHex("06B6D4")],
        description: 'Diamond pattern in teal',
      ),
      ProfileBackgroundOption(
        id: 'pattern_circles_purple',
        name: 'Purple Circles',
        type: BackgroundType.pattern,
        patternType: PatternType.circles,
        colors: [HexColor.fromHex("667EEA"), HexColor.fromHex("764BA2")],
        description: 'Circular patterns in purple',
      ),
      ProfileBackgroundOption(
        id: 'pattern_wave_green',
        name: 'Green Waves',
        type: BackgroundType.pattern,
        patternType: PatternType.wave,
        colors: [HexColor.fromHex("10B981"), HexColor.fromHex("84CC16")],
        description: 'Wave pattern in green tones',
      ),
      ProfileBackgroundOption(
        id: 'pattern_circuit_blue',
        name: 'Tech Circuit',
        type: BackgroundType.pattern,
        patternType: PatternType.circuit,
        colors: [HexColor.fromHex("6366F1"), HexColor.fromHex("8B5CF6")],
        description: 'Tech circuit pattern',
      ),
    ];
  }

  /// Create pattern widget using pattern_box
  static Widget createPatternWidget({
    required ProfileBackgroundOption option,
    double? width,
    double? height,
  }) {
    if (option.colors.isEmpty) return Container();

    final primaryColor = option.colors.first;
    PatternBox painter;

    switch (option.patternType) {
      case PatternType.geometric:
        painter = GridPainter();
        break;
      case PatternType.diamonds:
        painter = DiamondPainter();
        break;
      case PatternType.circles:
        painter = ConcentricCirclePainter();
        break;
      case PatternType.honeycomb:
        painter = HoneyCombPainter();
        break;
      case PatternType.wave:
        painter = WavePainter();
        break;
      case PatternType.circuit:
        painter = WebMatrixPainter();
        break;
      case PatternType.mosaic:
        painter = GridPainter(); // Using GridPainter instead of MossaicPainter
        break;
      case null:
        painter = GridPainter();
        break;
    }

    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? double.infinity,
      child: PatternBoxWidget(
        pattern: painter,
        patternGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor.withValues(alpha: 0.6),
            primaryColor.withValues(alpha: 0.3),
            Colors.transparent,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
        backgroundGradient: LinearGradient(
          colors: [primaryColor.withValues(alpha: 0.1), Colors.transparent],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }

  /// Create solid/gradient background widget
  static Widget createSolidBackground({
    required ProfileBackgroundOption option,
    double? width,
    double? height,
  }) {
    return Container(
      width: width ?? double.infinity,
      height: height ?? double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: option.colors.isNotEmpty
              ? option.colors
              : AppColors.ballColors[0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  /// Create animated pattern (for now, returns static with indicator)
  static Widget createAnimatedPattern(ProfileBackgroundOption option) {
    if (option.colors.isEmpty) return Container();

    return Stack(
      children: [
        createPatternWidget(option: option),
        Positioned(
          top: 8,
          right: 8,
          child: Icon(
            Icons.play_circle_filled,
            color: Colors.white.withValues(alpha: 0.8),
            size: 16,
          ),
        ),
      ],
    );
  }

  /// Create geometric pattern (alias for createPatternWidget)
  static Widget createGeometricPattern(ProfileBackgroundOption option) {
    return createPatternWidget(option: option);
  }

  /// Main method to create background widget based on type
  static Widget createBackgroundWidget({
    required ProfileBackgroundOption option,
    double? width,
    double? height,
  }) {
    switch (option.type) {
      case BackgroundType.pattern:
        return createPatternWidget(
          option: option,
          width: width,
          height: height,
        );
      case BackgroundType.animated:
        return createAnimatedPattern(option);
      case BackgroundType.solid:
      case BackgroundType.gradient:
        return createSolidBackground(
          option: option,
          width: width,
          height: height,
        );
    }
  }

  /// Save user background preference to Firebase
  static Future<void> saveUserBackground(
    ProfileBackgroundOption background,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No authenticated user');

      final backgroundMap = background.toMap();
      AppLogger.d(
        'PatternBackgroundService: Saving background: ${background.name}',
      );
      AppLogger.d('PatternBackgroundService: Background data: $backgroundMap');

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
            'profileBackground': backgroundMap,
            'backgroundUpdatedAt': FieldValue.serverTimestamp(),
          });

      AppLogger.d(
        'PatternBackgroundService: Profile background saved successfully: ${background.name}',
      );
    } catch (e) {
      AppLogger.w(
        'PatternBackgroundService: Error saving profile background: $e',
      );
      throw Exception('Failed to save background: $e');
    }
  }

  /// Get user's current background from Firebase
  static Future<ProfileBackgroundOption?> getUserBackground() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists && doc.data()?['profileBackground'] != null) {
        return ProfileBackgroundOption.fromMap(
          doc.data()!['profileBackground'] as Map<String, dynamic>,
        );
      }

      return null;
    } catch (e) {
      AppLogger.w(
        'PatternBackgroundService: Error getting user background: $e',
      );
      return null;
    }
  }

  /// Create custom solid background
  static ProfileBackgroundOption createCustomSolidBackground(Color color) {
    return ProfileBackgroundOption(
      id: 'custom_solid_${color.toARGB32()}',
      name: 'Custom Color',
      type: BackgroundType.solid,
      colors: [color, color.withValues(alpha: 0.7)],
      description: 'Your custom selected color',
    );
  }

  /// Create custom gradient background
  static ProfileBackgroundOption createCustomGradientBackground({
    required List<Color> colors,
    String? name,
  }) {
    return ProfileBackgroundOption(
      id: 'custom_gradient_${DateTime.now().millisecondsSinceEpoch}',
      name: name ?? 'Custom Gradient',
      type: BackgroundType.gradient,
      colors: colors,
      description: 'Your custom gradient design',
    );
  }
}
