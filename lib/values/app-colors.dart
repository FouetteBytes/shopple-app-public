part of 'values.dart';

class AppColors {
  static List<List<Color>> ballColors = [
    [HexColor.fromHex("87D3DF"), HexColor.fromHex("DEABEF")],
    [HexColor.fromHex("FC946E"), HexColor.fromHex("FFD996")],
    [HexColor.fromHex("87C76F"), HexColor.fromHex("87C76F")],
    [HexColor.fromHex("E7B2EF"), HexColor.fromHex("EEFCCF")],
    [HexColor.fromHex("8CE0DF"), HexColor.fromHex("8CE0DF")],
    [HexColor.fromHex("353645"), HexColor.fromHex("1E2027")],
    [HexColor.fromHex("FDA7FF"), HexColor.fromHex("FDA7FF")],
    [HexColor.fromHex("899FFE"), HexColor.fromHex("899FFE")],
    [HexColor.fromHex("FC946E"), HexColor.fromHex("FFD996")],
    [HexColor.fromHex("87C76F"), HexColor.fromHex("87C76F")],
  ];

  // RESTORED SHOPPING LISTS/ALERTS LOOK
  // Use navbar-matching charcoal background and slightly lighter card surface
  static final Color primaryBackgroundColor = HexColor.fromHex(
    "181A1F",
  ); // Matches navbar
  static final Color lightMauveBackgroundColor = HexColor.fromHex("C395FC");
  static final Color primaryAccentColor = HexColor.fromHex("246CFD");

  // ESSENTIAL COMPATIBILITY COLORS - tuned for the original dark lists/alerts theme
  // Using charcoal background with proper contrast
  static final Color primaryText = Colors.white; // Keep white text for contrast
  static final Color primaryText70 = Colors.white70;
  static final Color primaryText30 = Colors.white30;
  static final Color secondaryText = HexColor.fromHex(
    "C395FC",
  ); // Keep purple accent
  static final Color background = HexColor.fromHex(
    "181A1F",
  ); // Same as navbar (Shopping Lists/Alerts)
  static final Color surface = HexColor.fromHex(
    "262A34",
  ); // Card/surface slightly lighter than background
  static final Color error = Colors.redAccent;
  static final Color inactive = HexColor.fromHex(
    "666A7A",
  ); // Keep original gray tone
  static final Color primaryGreen =
      primaryAccentColor; // Map to original blue accent
  static final Color accentGreen =
      lightMauveBackgroundColor; // Map to original purple accent
  static final Color darkGreenBackground = HexColor.fromHex(
    "1F222A",
  ); // Accent dark used in gradients
}

extension HexColor on Color {
  /// String is in the format "aabbcc" or "ffaabbcc" with an optional leading "#".
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  /// Prefixes a hash sign if [leadingHashSign] is set to `true` (default is `true`).
  String toHex({bool leadingHashSign = true}) =>
      '${leadingHashSign ? '#' : ''}'
      '${((a * 255).round()).toRadixString(16).padLeft(2, '0')}'
      '${((r * 255).round()).toRadixString(16).padLeft(2, '0')}'
      '${((g * 255).round()).toRadixString(16).padLeft(2, '0')}'
      '${((b * 255).round()).toRadixString(16).padLeft(2, '0')}';
}

// ranges from 0.0 to 1.0

Color darken(Color color, [double amount = .1]) {
  assert(amount >= 0 && amount <= 1);

  final hsl = HSLColor.fromColor(color);
  final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));

  return hslDark.toColor();
}

Color lighten(Color color, [double amount = .1]) {
  assert(amount >= 0 && amount <= 1);

  final hsl = HSLColor.fromColor(color);
  final hslLight = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));

  return hslLight.toColor();
}
