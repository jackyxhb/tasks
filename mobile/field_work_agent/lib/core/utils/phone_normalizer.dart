class PhoneNormalizer {
  const PhoneNormalizer._();

  static String? normalizeNullable(String? value) {
    if (value == null) {
      return null;
    }
    final digits = value.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.isEmpty) {
      return null;
    }
    if (digits.startsWith('+')) {
      final remainder = digits.substring(1).replaceAll('+', '');
      return '+$remainder';
    }
    return digits.replaceAll('+', '');
  }
}