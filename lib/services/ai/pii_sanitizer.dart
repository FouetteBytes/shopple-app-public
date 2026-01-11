/// Simple PII redaction utility to avoid sending raw sensitive data to LLM.
/// Redacts email addresses, phone numbers, and long digit sequences (>6).
class PIISanitizer {
  static final _emailRegex = RegExp(
    r'[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}',
    caseSensitive: false,
  );
  static final _phoneRegex = RegExp(
    r'(?:(?:\+?\d{1,3}[ -]?)?(?:\(?\d{3}\)?)[ -]?\d{3}[ -]?\d{4})',
  );
  static final _longDigits = RegExp(r'\b\d{6,}\b');

  static String redact(String input) {
    var out = input;
    out = out.replaceAllMapped(_emailRegex, (_) => '[REDACTED_EMAIL]');
    out = out.replaceAllMapped(_phoneRegex, (_) => '[REDACTED_PHONE]');
    out = out.replaceAllMapped(_longDigits, (_) => '[REDACTED_NUMBER]');
    return out;
  }
}
