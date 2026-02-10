import 'package:flutter_test/flutter_test.dart';
import 'package:hipster/utils.dart';

void main() {
  group('extractUuid', () {
    test('extracts UUID from a Suno URL', () {
      const url =
          'https://suno.com/song/a1b2c3d4-e5f6-7890-abcd-ef1234567890';
      expect(
        extractUuid(url),
        equals('a1b2c3d4-e5f6-7890-abcd-ef1234567890'),
      );
    });

    test('extracts a bare UUID', () {
      const uuid = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';
      expect(extractUuid(uuid), equals(uuid));
    });

    test('returns null when no UUID is present', () {
      expect(extractUuid('not-a-uuid'), isNull);
      expect(extractUuid(''), isNull);
      expect(extractUuid('12345'), isNull);
    });

    test('extracts UUID with uppercase letters', () {
      const uuid = 'A1B2C3D4-E5F6-7890-ABCD-EF1234567890';
      expect(extractUuid(uuid), equals(uuid));
    });

    test('extracts UUID embedded in surrounding text', () {
      const text =
          'Check out this song a1b2c3d4-e5f6-7890-abcd-ef1234567890 its great';
      expect(
        extractUuid(text),
        equals('a1b2c3d4-e5f6-7890-abcd-ef1234567890'),
      );
    });

    test('extracts first UUID when multiple are present', () {
      const text =
          'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee and 11111111-2222-3333-4444-555555555555';
      expect(
        extractUuid(text),
        equals('aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee'),
      );
    });
  });
}
