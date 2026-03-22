import 'dart:io';

class LocalFileChecksum {
  const LocalFileChecksum._();

  static Future<String> forFile(File file) async {
    final bytes = await file.readAsBytes();
    return WebChecksumService().compute(bytes);
  }
}

class WebChecksumService {
  String compute(List<int> bytes) {
    BigInt hash = BigInt.parse('0xcbf29ce484222325');
    const int fnvPrime = 0x100000001b3;
    for (final byte in bytes) {
      hash ^= BigInt.from(byte);
      hash =
          (hash * BigInt.from(fnvPrime)) & BigInt.parse('0xFFFFFFFFFFFFFFFF');
    }
    return hash.toRadixString(16).padLeft(16, '0');
  }
}
