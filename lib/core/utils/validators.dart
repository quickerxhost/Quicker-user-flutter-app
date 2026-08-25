/// Pure validation helpers used by login/registration forms. No context/
/// widget dependency so these are trivially unit-testable.
abstract final class Validators {
  static String? mobileNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your mobile number';
    }
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length != 10) {
      return 'Enter a valid 10-digit mobile number';
    }
    return null;
  }

  static String? otp(String? value, {int length = 6}) {
    if (value == null || value.length != length) {
      return 'Enter the $length-digit code';
    }
    if (!RegExp(r'^\d+$').hasMatch(value)) {
      return 'OTP must contain digits only';
    }
    return null;
  }

  static String? fullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your full name';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // email is optional at registration in the Stitch flow
    }
    final regex = RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$');
    if (!regex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? required(String? value, {String field = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$field is required';
    }
    return null;
  }
}
