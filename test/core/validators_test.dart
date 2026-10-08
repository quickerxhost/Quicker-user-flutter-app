import 'package:flutter_test/flutter_test.dart';
import 'package:quickerx/core/utils/validators.dart';

void main() {
  group('Validators.mobileNumber', () {
    test('rejects empty input', () {
      expect(Validators.mobileNumber(''), isNotNull);
    });

    test('rejects fewer than 10 digits', () {
      expect(Validators.mobileNumber('12345'), isNotNull);
    });

    test('accepts exactly 10 digits', () {
      expect(Validators.mobileNumber('9876543210'), isNull);
    });
  });

  group('Validators.otp', () {
    test('rejects wrong length', () {
      expect(Validators.otp('123'), isNotNull);
    });

    test('rejects non-numeric', () {
      expect(Validators.otp('12a45b'), isNotNull);
    });

    test('accepts a valid 6-digit code', () {
      expect(Validators.otp('123456'), isNull);
    });
  });

  group('Validators.email', () {
    test('optional field allows empty', () {
      expect(Validators.email(''), isNull);
    });

    test('rejects malformed address', () {
      expect(Validators.email('not-an-email'), isNotNull);
    });

    test('accepts a valid address', () {
      expect(Validators.email('user@quickerx.in'), isNull);
    });
  });

  group('Validators.fullName', () {
    test('rejects empty', () {
      expect(Validators.fullName(''), isNotNull);
    });

    test('rejects single character', () {
      expect(Validators.fullName('A'), isNotNull);
    });

    test('accepts a normal name', () {
      expect(Validators.fullName('Rajesh Kumar'), isNull);
    });
  });
}
