import 'dart:convert';
import 'local_file_reference.dart';
import 'local_file_checksum.dart';

abstract class StorageService {
  Future<void> initialize();
  Future<LocalFileReference> writeFile({
    required String directory,
    required String fileName,
    required List<int> bytes,
  });
  Future<List<int>?> readFile(String relativePath);
  Future<void> deleteFile(String relativePath);
  Future<List<String>> listFiles(String directory);
  Future<bool> fileExists(String relativePath);
  Future<String> checksum(String relativePath);
}

class WebStorageService implements StorageService {
  WebStorageService();

  final Map<String, List<int>> _memory = {};

  @override
  Future<void> initialize() async {}

  @override
  Future<LocalFileReference> writeFile({
    required String directory,
    required String fileName,
    required List<int> bytes,
  }) async {
    final relativePath = '$directory/$fileName';
    _memory[relativePath] = bytes;
    return LocalFileReference(
      relativePath: relativePath,
      absolutePath: relativePath,
    );
  }

  @override
  Future<List<int>?> readFile(String relativePath) async {
    return _memory[relativePath];
  }

  @override
  Future<void> deleteFile(String relativePath) async {
    _memory.remove(relativePath);
  }

  @override
  Future<List<String>> listFiles(String directory) async {
    return _memory.keys.where((k) => k.startsWith('$directory/')).toList();
  }

  @override
  Future<bool> fileExists(String relativePath) async {
    return _memory.containsKey(relativePath);
  }

  @override
  Future<String> checksum(String relativePath) async {
    final bytes = _memory[relativePath];
    if (bytes == null) return '0' * 16;
    return WebChecksumService().compute(bytes);
  }
}
