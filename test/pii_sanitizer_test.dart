import 'package:flutter_test/flutter_test.dart';
import 'package:shopple/services/ai/pii_sanitizer.dart';

void main() {
  group('PIISanitizer', () {
    test('redacts email', () {
      final input = 'Contact me at user@example.com please';
      final out = PIISanitizer.redact(input);
      expect(out.contains('user@example.com'), false);
      expect(out.contains('[REDACTED_EMAIL]'), true);
    });
    test('redacts phone', () {
      final input = 'My number is (555) 123-4567 for orders';
      final out = PIISanitizer.redact(input);
      expect(out.contains('(555) 123-4567'), false);
      expect(out.contains('[REDACTED_PHONE]'), true);
    });
    test('redacts long digits', () {
      final input = 'Card 123456 maybe';
      final out = PIISanitizer.redact(input);
      expect(out.contains('123456'), false);
      expect(out.contains('[REDACTED_NUMBER]'), true);
    });
  });
}
