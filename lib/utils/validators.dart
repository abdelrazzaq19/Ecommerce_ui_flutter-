/// Form validation.
///
/// Each function returns null when the value is acceptable, or a message to
/// show under the field. Kept free of Flutter imports so the rules can be
/// tested directly, without pumping a widget.
abstract final class Validators {
  static final RegExp _email = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');
  static final RegExp _digits = RegExp(r'\d');
  static final RegExp _letters = RegExp('[A-Za-z]');
  static final RegExp _phoneAllowed = RegExp(r'^[\d\s()+-]+$');

  static const int minPasswordLength = 8;

  static String? name(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Enter your name';
    if (trimmed.length < 2) return 'That name looks too short';
    return null;
  }

  static String? email(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Enter your email address';
    if (!_email.hasMatch(trimmed)) return 'Enter a valid email address';
    return null;
  }

  /// Accepts the shapes people actually type: spaces, dashes, brackets and a
  /// leading country code. Only the digit count is really checked.
  static String? phone(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Enter your phone number';
    if (!_phoneAllowed.hasMatch(trimmed)) {
      return 'Use digits, spaces, brackets, + or -';
    }

    final digitCount = trimmed.replaceAll(RegExp(r'\D'), '').length;
    if (digitCount < 8) return 'That number is too short';
    if (digitCount > 15) return 'That number is too long';
    return null;
  }

  /// Sign-in rule: long enough to be a real password, nothing more. Judging the
  /// strength of a password someone already has is not useful.
  static String? password(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return 'Enter your password';
    if (text.length < minPasswordLength) {
      return 'Use at least $minPasswordLength characters';
    }
    return null;
  }

  /// Sign-up rule: length plus a letter and a digit.
  static String? newPassword(String? value) {
    final lengthError = password(value);
    if (lengthError != null) return lengthError;

    final text = value ?? '';
    if (!_letters.hasMatch(text) || !_digits.hasMatch(text)) {
      return 'Mix letters and numbers';
    }
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if ((value ?? '').isEmpty) return 'Repeat your password';
    if (value != original) return 'Those passwords do not match';
    return null;
  }
}
