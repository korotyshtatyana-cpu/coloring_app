/// Utility for scrubbing personally identifiable information (PII) from log strings.
abstract final class PiiScrubber {
  static final RegExp _emailRegExp = RegExp(
    r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}',
  );

  static final RegExp _bearerRegExp = RegExp(
    r'Bearer\s+[A-Za-z0-9\-\._~\+\/]+=*',
    caseSensitive: false,
  );

  static final RegExp _jwtRegExp = RegExp(
    r'eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+',
  );

  static final RegExp _uuidRegExp = RegExp(
    r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}',
  );

  static final RegExp _longTokenRegExp = RegExp(
    r'\b[A-Za-z0-9_-]{24,}\b',
  );

  /// Replaces sensitive data patterns (emails, tokens, JWTs, UUIDs) in [input].
  static String scrub(String input) {
    if (input.isEmpty) {
      return input;
    }

    String result = input.replaceAllMapped(
      _emailRegExp,
      (_) => '[EMAIL]',
    );

    result = result.replaceAllMapped(
      _bearerRegExp,
      (_) => 'Bearer [TOKEN]',
    );

    result = result.replaceAllMapped(
      _jwtRegExp,
      (_) => '[JWT]',
    );

    result = result.replaceAllMapped(
      _uuidRegExp,
      (_) => '[UUID]',
    );

    result = result.replaceAllMapped(
      _longTokenRegExp,
      (Match match) {
        final String matchStr = match.group(0)!;
        if (matchStr == '[EMAIL]' ||
            matchStr == '[TOKEN]' ||
            matchStr == '[JWT]' ||
            matchStr == '[UUID]') {
          return matchStr;
        }
        return '[TOKEN]';
      },
    );

    return result;
  }
}
