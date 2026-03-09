import 'dart:convert';

class ContentHash {
  const ContentHash._();

  static String forText(String value) {
    const int fnvOffsetBasis = 0xcbf29ce484222325;
    const int fnvPrime = 0x100000001b3;
    const int maxUint64 = 0xffffffffffffffff;

    var hash = fnvOffsetBasis;
    for (final byte in utf8.encode(value)) {
      hash ^= byte;
      hash = (hash * fnvPrime) & maxUint64;
    }
    return hash.toRadixString(16).padLeft(16, '0');
  }
}