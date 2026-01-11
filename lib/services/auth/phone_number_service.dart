import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../../utils/app_logger.dart';

/// 🔥 Basic Phone Number Service
///
/// Simple phone number validation and processing service
class PhoneNumberService {
  /// 🌍 Normalize phone number to E.164 format for consistent storage
  static Future<String?> normalizeToE164(
    String rawNumber, [
    String? countryCode,
  ]) async {
    if (rawNumber.isEmpty) return null;

    try {
      // Clean the phone number
      String cleaned = _cleanPhoneNumber(rawNumber);

      // Basic E.164 formatting (starts with +)
      if (!cleaned.startsWith('+')) {
        // Add default country code if not present
        String defaultCountry = countryCode ?? '1'; // Default to US
        cleaned = '+$defaultCountry$cleaned';
      }

      // Validate length (7-15 digits after +)
      String digits = cleaned.substring(1);
      if (digits.length < 7 || digits.length > 15) {
        AppLogger.w('Invalid phone number length');
        return null;
      }

      return cleaned;
    } catch (e, st) {
      AppLogger.e('Error normalizing phone number', error: e, stackTrace: st);
      return _fallbackNormalization(rawNumber);
    }
  }

  /// 🔄 Generate variations of a phone number for fuzzy matching
  static List<String> generateVariations(String phoneNumber) {
    List<String> variations = [];

    try {
      String cleaned = _cleanPhoneNumber(phoneNumber);

      // Add original
      variations.add(phoneNumber);

      // Add cleaned version
      variations.add(cleaned);

      // Add with + prefix if not present
      if (!cleaned.startsWith('+')) {
        variations.add('+$cleaned');
        variations.add('+1$cleaned'); // US format
      }

      // Add without + prefix
      if (cleaned.startsWith('+')) {
        variations.add(cleaned.substring(1));
      }

      // Add last 10 digits (common US format)
      if (cleaned.length >= 10) {
        variations.add(cleaned.substring(cleaned.length - 10));
      }

      // Add last 7 digits (local number)
      if (cleaned.length >= 7) {
        variations.add(cleaned.substring(cleaned.length - 7));
      }
    } catch (e, st) {
      AppLogger.e(
        'Error generating phone variations',
        error: e,
        stackTrace: st,
      );
    }

    // Remove duplicates and return
    return variations.toSet().toList();
  }

  /// 🔒 Hash phone number for privacy protection
  static String hashPhoneNumber(String phoneNumber) {
    var bytes = utf8.encode(phoneNumber);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// 🔍 Check if a string is likely a phone number
  static bool isPhoneNumber(String input) {
    if (input.isEmpty) return false;

    try {
      String cleaned = _cleanPhoneNumber(input);

      // Check if it's mostly digits
      int digitCount = cleaned.replaceAll(RegExp(r'[^0-9]'), '').length;

      // Must have at least 7 digits and be mostly digits
      return digitCount >= 7 && digitCount >= (cleaned.length * 0.7);
    } catch (e) {
      return false;
    }
  }

  // Helper Methods

  /// Clean phone number by removing non-digit characters (except +)
  static String _cleanPhoneNumber(String phoneNumber) {
    return phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
  }

  /// Fallback normalization for edge cases
  static String? _fallbackNormalization(String phoneNumber) {
    try {
      String cleaned = _cleanPhoneNumber(phoneNumber);

      if (cleaned.length >= 7) {
        // Add + prefix if not present
        if (!cleaned.startsWith('+')) {
          cleaned = '+1$cleaned'; // Default to US
        }
        return cleaned;
      }

      return null;
    } catch (e) {
      return null;
    }
  }
}
