import 'dart:convert';

class ContentHash {
  const ContentHash._();

  static String forText(String value) {
    BigInt hash = BigInt.parse('0xcbf29ce484222325');
    const int fnvPrime = 0x100000001b3;
    for (final byte in utf8.encode(value)) {
      hash ^= BigInt.from(byte);
      hash =
          (hash * BigInt.from(fnvPrime)) & BigInt.parse('0xFFFFFFFFFFFFFFFF');
    }
    return hash.toRadixString(16).padLeft(16, '0');
  }
}
