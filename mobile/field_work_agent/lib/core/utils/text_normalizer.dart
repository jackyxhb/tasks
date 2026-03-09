class TextNormalizer {
  const TextNormalizer._();

  static String normalize(String value) {
    final collapsedWhitespace = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    return collapsedWhitespace.toLowerCase();
  }

  static String? normalizeNullable(String? value) {
    if (value == null) {
      return null;
    }
    final normalized = normalize(value);
    return normalized.isEmpty ? null : normalized;
  }
}