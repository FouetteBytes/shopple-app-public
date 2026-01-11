import 'package:flutter_test/flutter_test.dart';
import 'package:shopple/models/user_privacy_settings.dart';

/// Unit tests for UserPrivacySettings model and ContactMasker utility.
/// These tests verify privacy logic without touching Firebase.
/// All data is created in-memory and isolated.

void main() {
  group('UserPrivacySettings Tests', () {
    group('Default Settings', () {
      test('default settings allow searching', () {
        const settings = UserPrivacySettings.defaultSettings;

        expect(settings.searchableByName, isTrue);
        expect(settings.searchableByEmail, isTrue);
        expect(settings.searchableByPhone, isTrue);
        expect(settings.isFullyPrivate, isFalse);
      });

      test('default settings have partial contact visibility', () {
        const settings = UserPrivacySettings.defaultSettings;

        expect(settings.emailVisibility, ContactVisibility.partial);
        expect(settings.phoneVisibility, ContactVisibility.partial);
        expect(settings.nameVisibility, ContactVisibility.full);
      });

      test('isSearchable returns true for default settings', () {
        const settings = UserPrivacySettings.defaultSettings;

        expect(settings.isSearchable, isTrue);
      });
    });

    group('Fully Private Settings', () {
      test('fully private settings disable all searching', () {
        const settings = UserPrivacySettings.fullyPrivate;

        expect(settings.searchableByName, isFalse);
        expect(settings.searchableByEmail, isFalse);
        expect(settings.searchableByPhone, isFalse);
        expect(settings.isFullyPrivate, isTrue);
      });

      test('fully private settings hide contact info', () {
        const settings = UserPrivacySettings.fullyPrivate;

        expect(settings.emailVisibility, ContactVisibility.hidden);
        expect(settings.phoneVisibility, ContactVisibility.hidden);
        // Name is still full for identification purposes
        expect(settings.nameVisibility, ContactVisibility.full);
      });

      test('isSearchable returns false for fully private', () {
        const settings = UserPrivacySettings.fullyPrivate;

        expect(settings.isSearchable, isFalse);
      });
    });

    group('Custom Settings', () {
      test('creates settings with custom values', () {
        const settings = UserPrivacySettings(
          searchableByName: true,
          searchableByEmail: false,
          searchableByPhone: false,
          isFullyPrivate: false,
          emailVisibility: ContactVisibility.hidden,
          phoneVisibility: ContactVisibility.hidden,
          nameVisibility: ContactVisibility.full,
        );

        expect(settings.searchableByName, isTrue);
        expect(settings.searchableByEmail, isFalse);
        expect(settings.emailVisibility, ContactVisibility.hidden);
      });

      test('isSearchable with only name searchable', () {
        const settings = UserPrivacySettings(
          searchableByName: true,
          searchableByEmail: false,
          searchableByPhone: false,
          isFullyPrivate: false,
        );

        expect(settings.isSearchable, isTrue);
      });

      test('isSearchable is false when fully private even if flags are true', () {
        const settings = UserPrivacySettings(
          searchableByName: true,
          searchableByEmail: true,
          searchableByPhone: true,
          isFullyPrivate: true,
        );

        expect(settings.isSearchable, isFalse);
      });

      test('isSearchable is false when no search flags are set', () {
        const settings = UserPrivacySettings(
          searchableByName: false,
          searchableByEmail: false,
          searchableByPhone: false,
          isFullyPrivate: false,
        );

        expect(settings.isSearchable, isFalse);
      });
    });

    group('copyWith', () {
      test('creates copy with single field changed', () {
        const original = UserPrivacySettings.defaultSettings;
        final updated = original.copyWith(searchableByEmail: false);

        expect(updated.searchableByEmail, isFalse);
        expect(updated.searchableByName, original.searchableByName);
        expect(updated.searchableByPhone, original.searchableByPhone);
      });

      test('creates copy with multiple fields changed', () {
        const original = UserPrivacySettings.defaultSettings;
        final updated = original.copyWith(
          searchableByName: false,
          emailVisibility: ContactVisibility.hidden,
        );

        expect(updated.searchableByName, isFalse);
        expect(updated.emailVisibility, ContactVisibility.hidden);
        expect(updated.phoneVisibility, original.phoneVisibility);
      });

      test('copyWith with no parameters returns equivalent settings', () {
        const original = UserPrivacySettings.defaultSettings;
        final copy = original.copyWith();

        expect(copy.searchableByName, original.searchableByName);
        expect(copy.searchableByEmail, original.searchableByEmail);
        expect(copy.emailVisibility, original.emailVisibility);
      });
    });

    group('fromFirestore', () {
      test('parses complete data correctly', () {
        final data = {
          'searchableByName': false,
          'searchableByEmail': false,
          'searchableByPhone': true,
          'isFullyPrivate': false,
          'emailVisibility': 'hidden',
          'phoneVisibility': 'full',
          'nameVisibility': 'partial',
        };

        final settings = UserPrivacySettings.fromFirestore(data);

        expect(settings.searchableByName, isFalse);
        expect(settings.searchableByEmail, isFalse);
        expect(settings.searchableByPhone, isTrue);
        expect(settings.isFullyPrivate, isFalse);
        expect(settings.emailVisibility, ContactVisibility.hidden);
        expect(settings.phoneVisibility, ContactVisibility.full);
        expect(settings.nameVisibility, ContactVisibility.partial);
      });

      test('returns default settings for null data', () {
        final settings = UserPrivacySettings.fromFirestore(null);

        expect(settings.searchableByName, isTrue);
        expect(settings.searchableByEmail, isTrue);
        expect(settings.emailVisibility, ContactVisibility.partial);
      });

      test('handles missing fields with defaults', () {
        final data = <String, dynamic>{
          'searchableByName': false,
        };

        final settings = UserPrivacySettings.fromFirestore(data);

        expect(settings.searchableByName, isFalse);
        expect(settings.searchableByEmail, isTrue); // default
        expect(settings.emailVisibility, ContactVisibility.partial); // default
      });
    });

    group('toString', () {
      test('returns readable string representation', () {
        const settings = UserPrivacySettings.defaultSettings;
        final str = settings.toString();

        expect(str, contains('searchableByName'));
        expect(str, contains('emailVisibility'));
      });
    });
  });

  group('ContactVisibility Tests', () {
    group('fromString', () {
      test('parses full correctly', () {
        expect(ContactVisibility.fromString('full'), ContactVisibility.full);
      });

      test('parses partial correctly', () {
        expect(
          ContactVisibility.fromString('partial'),
          ContactVisibility.partial,
        );
      });

      test('parses hidden correctly', () {
        expect(ContactVisibility.fromString('hidden'), ContactVisibility.hidden);
      });

      test('handles case insensitivity', () {
        expect(ContactVisibility.fromString('FULL'), ContactVisibility.full);
        expect(ContactVisibility.fromString('Full'), ContactVisibility.full);
        expect(ContactVisibility.fromString('HIDDEN'), ContactVisibility.hidden);
      });

      test('defaults to partial for unknown values', () {
        expect(
          ContactVisibility.fromString('unknown'),
          ContactVisibility.partial,
        );
        expect(
          ContactVisibility.fromString(''),
          ContactVisibility.partial,
        );
      });
    });

    group('displayName', () {
      test('full displays as Visible', () {
        expect(ContactVisibility.full.displayName, equals('Visible'));
      });

      test('partial displays as Partially Hidden', () {
        expect(
          ContactVisibility.partial.displayName,
          equals('Partially Hidden'),
        );
      });

      test('hidden displays as Hidden', () {
        expect(ContactVisibility.hidden.displayName, equals('Hidden'));
      });
    });

    group('description', () {
      test('full has appropriate description', () {
        expect(
          ContactVisibility.full.description,
          contains('full contact info'),
        );
      });

      test('partial has appropriate description', () {
        expect(
          ContactVisibility.partial.description,
          contains('masked'),
        );
      });

      test('hidden has appropriate description', () {
        expect(
          ContactVisibility.hidden.description,
          contains('cannot see'),
        );
      });
    });

    group('value', () {
      test('returns correct string value', () {
        expect(ContactVisibility.full.value, equals('full'));
        expect(ContactVisibility.partial.value, equals('partial'));
        expect(ContactVisibility.hidden.value, equals('hidden'));
      });
    });
  });

  group('ContactMasker Tests', () {
    group('maskEmail', () {
      test('masks standard email correctly', () {
        final masked = ContactMasker.maskEmail('john.doe@email.com');

        expect(masked, contains('jo***'));
        expect(masked, contains('@'));
        expect(masked, contains('.com'));
        expect(masked, isNot(contains('john.doe')));
      });

      test('handles short local part', () {
        final masked = ContactMasker.maskEmail('jd@email.com');

        expect(masked, isNotEmpty);
        expect(masked, contains('@'));
      });

      test('handles single character local part', () {
        final masked = ContactMasker.maskEmail('j@email.com');

        expect(masked, isNotEmpty);
        expect(masked, contains('@'));
      });

      test('handles empty email', () {
        final masked = ContactMasker.maskEmail('');

        expect(masked, isEmpty);
      });

      test('handles email without @ sign', () {
        final masked = ContactMasker.maskEmail('invalidemail');

        expect(masked, equals('***@***.***'));
      });

      test('preserves TLD', () {
        final masked = ContactMasker.maskEmail('user@domain.org');

        expect(masked, contains('.org'));
      });

      test('handles subdomain TLD', () {
        final masked = ContactMasker.maskEmail('user@domain.co.uk');

        expect(masked, contains('.co.uk'));
      });
    });

    group('maskPhone', () {
      test('masks phone showing last 4 digits', () {
        final masked = ContactMasker.maskPhone('+1 555 123 4567');

        expect(masked, contains('4567'));
        expect(masked, contains('***'));
      });

      test('handles international format with +', () {
        final masked = ContactMasker.maskPhone('+44 20 7946 0958');

        expect(masked, startsWith('+'));
        expect(masked, contains('0958'));
      });

      test('handles phone without country code', () {
        final masked = ContactMasker.maskPhone('555-123-4567');

        expect(masked, contains('4567'));
        expect(masked, contains('***'));
      });

      test('handles empty phone', () {
        final masked = ContactMasker.maskPhone('');

        expect(masked, isEmpty);
      });

      test('handles short phone number', () {
        final masked = ContactMasker.maskPhone('123');

        expect(masked, isNotEmpty);
      });
    });

    group('maskName', () {
      test('masks last name showing first name and initial', () {
        final masked = ContactMasker.maskName('John Doe');

        expect(masked, equals('John D.'));
      });

      test('handles single name', () {
        final masked = ContactMasker.maskName('John');

        expect(masked, equals('John'));
      });

      test('handles multiple names', () {
        final masked = ContactMasker.maskName('John Michael Doe');

        expect(masked, startsWith('John'));
        expect(masked, contains('M.'));
      });

      test('handles empty name', () {
        final masked = ContactMasker.maskName('');

        expect(masked, isEmpty);
      });

      test('handles name with extra spaces', () {
        // Implementation splits on single space, so extra spaces create empty parts
        // The function trims outer whitespace but inner multiple spaces remain
        final masked = ContactMasker.maskName('  John Doe  ');

        // After trim: "John Doe", parts[1] is "Doe" -> "D."
        expect(masked, equals('John D.'));
      });
    });

    group('applyVisibility', () {
      test('full visibility returns unchanged value', () {
        final result = ContactMasker.applyVisibility(
          'john@email.com',
          ContactVisibility.full,
          ContactType.email,
        );

        expect(result, equals('john@email.com'));
      });

      test('hidden visibility returns null', () {
        final result = ContactMasker.applyVisibility(
          'john@email.com',
          ContactVisibility.hidden,
          ContactType.email,
        );

        expect(result, isNull);
      });

      test('partial visibility masks email', () {
        final result = ContactMasker.applyVisibility(
          'john@email.com',
          ContactVisibility.partial,
          ContactType.email,
        );

        expect(result, isNot(equals('john@email.com')));
        expect(result, contains('***'));
      });

      test('partial visibility masks phone', () {
        final result = ContactMasker.applyVisibility(
          '+1 555 123 4567',
          ContactVisibility.partial,
          ContactType.phone,
        );

        expect(result, contains('4567'));
        expect(result, contains('***'));
      });

      test('partial visibility masks name', () {
        final result = ContactMasker.applyVisibility(
          'John Doe',
          ContactVisibility.partial,
          ContactType.name,
        );

        expect(result, equals('John D.'));
      });

      test('returns null for null input', () {
        final result = ContactMasker.applyVisibility(
          null,
          ContactVisibility.full,
          ContactType.email,
        );

        expect(result, isNull);
      });

      test('returns null for empty input', () {
        final result = ContactMasker.applyVisibility(
          '',
          ContactVisibility.full,
          ContactType.email,
        );

        expect(result, isNull);
      });
    });
  });

  group('ContactType Tests', () {
    test('has all expected values', () {
      expect(ContactType.values.length, equals(3));
      expect(ContactType.values, contains(ContactType.email));
      expect(ContactType.values, contains(ContactType.phone));
      expect(ContactType.values, contains(ContactType.name));
    });
  });
}
