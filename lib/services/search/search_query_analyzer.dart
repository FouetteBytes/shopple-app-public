import '../../models/contact_models.dart';

class SearchQueryAnalyzer {
  /// Detect query type for intelligent optimized search strategy
  static QueryType detectQueryType(String query) {
    // SMART EMAIL DETECTION: Match email patterns early, not just complete emails
    if (query.contains('@')) {
      return QueryType.email; // Don't wait for the dot
    }

    // Smart email domain detection (common domains)
    List<String> emailDomains = [
      'gmail',
      'yahoo',
      'hotmail',
      'outlook',
      'duck',
      'icloud',
    ];
    for (String domain in emailDomains) {
      if (query.toLowerCase().contains(domain)) {
        return QueryType.email;
      }
    }

    // SMART PHONE NUMBER DETECTION: More flexible patterns
    // Check for phone patterns without requiring complete numbers
    if (RegExp(r'^[+]?[\d\s\-\(\)]+$').hasMatch(query) && query.length >= 3) {
      return QueryType.phone;
    }

    // Check for phone starting patterns
    if (RegExp(r'^(\+1|1|\+|0|\(\d)').hasMatch(query)) {
      return QueryType.phone;
    }

    // INTELLIGENT MIXED DETECTION: Look for email-like or phone-like patterns
    if (RegExp(r'[a-zA-Z].*[@+\d]|[@+\d].*[a-zA-Z]').hasMatch(query)) {
      return QueryType.mixed;
    }

    // SMART PARTIAL DETECTION: Single or double character for instant suggestions
    if (query.length <= 2) {
      return QueryType.partial;
    }

    // SMART NAME DETECTION: Pure letters or letters with spaces/hyphens
    if (RegExp(r'^[a-zA-Z\s\-\.]+$').hasMatch(query)) {
      return QueryType.name;
    }

    // Default to mixed for anything else
    return QueryType.mixed;
  }
}
