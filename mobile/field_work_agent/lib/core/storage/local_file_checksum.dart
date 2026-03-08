import 'dart:io';

class LocalFileChecksum {
  const LocalFileChecksum._();

  static Future<String> forFile(File file) async {
    const int fnvOffsetBasis = 0xcbf29ce484222325;
    const int fnvPrime = 0x100000001b3;
    const int maxUint64 = 0xffffffffffffffff;

    var hash = fnvOffsetBasis;
    final bytes = await file.readAsBytes();
    for (final byte in bytes) {
      hash ^= byte;
      hash = (hash * fnvPrime) & maxUint64;
    }
    return hash.toRadixString(16).padLeft(16, '0');
  }
}