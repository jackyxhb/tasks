import 'dart:io';

import '../core/storage/local_file_storage_service.dart';

class LocalFileStorageBootstrap {
  const LocalFileStorageBootstrap._();

  static Future<LocalFileStorageService> initialize({
    required Directory rootDirectory,
  }) async {
    final storage = LocalFileStorageService(rootDirectory: rootDirectory);
    await storage.ensureInitialized();
    return storage;
  }
}