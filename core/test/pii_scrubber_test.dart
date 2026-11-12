import 'package:core/src/services/pii_scrubber.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PiiScrubber', () {
    test('1. returns empty string when input is empty', () {
      expect(PiiScrubber.scrub(''), '');
    });

    test('2. returns plain text unchanged when no PII is present', () {
      const String input = '[Monetization] Subscription purchase initiated';
      expect(PiiScrubber.scrub(input), input);
    });

    test('3. scrubs standard email address', () {
      const String input = 'User test.user@example.com logged in';
      expect(PiiScrubber.scrub(input), 'User [EMAIL] logged in');
    });

    test('4. scrubs email with complex domain', () {
      const String input = 'Contact support at dev-team_123@company.co.uk';
      expect(PiiScrubber.scrub(input), 'Contact support at [EMAIL]');
    });

    test('5. scrubs Bearer authentication header token', () {
      const String input = 'Header: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9';
      expect(PiiScrubber.scrub(input), 'Header: Bearer [TOKEN]');
    });

    test('6. scrubs standalone JWT string', () {
      const String input =
          'Token: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
          'eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIn0.'
          'SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c';
      expect(PiiScrubber.scrub(input), 'Token: [JWT]');
    });

    test('7. scrubs UUID format identifiers', () {
      const String input = 'User ID: 123e4567-e89b-12d3-a456-426614174000';
      expect(PiiScrubber.scrub(input), 'User ID: [UUID]');
    });

    test('8. scrubs long purchase tokens', () {
      const String input = 'Token value: gplay_token_1234567890abcdef1234567890';
      expect(PiiScrubber.scrub(input), 'Token value: [TOKEN]');
    });

    test('9. scrubs multiple PII entries in single message', () {
      const String input =
          'User john@domain.com with id 123e4567-e89b-12d3-a456-426614174000 failed';
      expect(
        PiiScrubber.scrub(input),
        'User [EMAIL] with id [UUID] failed',
      );
    });

    test('10. handles mixed uppercase UUIDs and email', () {
      const String input =
          'Account admin@company.org ID: 9B1DE05F-1234-5678-90AB-CDEF12345678';
      expect(
        PiiScrubber.scrub(input),
        'Account [EMAIL] ID: [UUID]',
      );
    });

    test('11. preserves structural log formatting while scrubbing PII', () {
      const String input =
          '[Auth] user=alice@test.io token=abcdef12345678901234567890 status=ok';
      expect(
        PiiScrubber.scrub(input),
        '[Auth] user=[EMAIL] token=[TOKEN] status=ok',
      );
    });
  });
}
