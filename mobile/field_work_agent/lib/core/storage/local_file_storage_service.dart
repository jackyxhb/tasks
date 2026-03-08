import 'dart:io';

import 'local_file_checksum.dart';
import 'local_file_reference.dart';

enum LocalStorageDirectory {
  audio,
  attachments,
  exports,
  imports,
  reports,
  temp,
}

extension LocalStorageDirectoryPath on LocalStorageDirectory {
  String get pathSegment {
    switch (this) {
      case LocalStorageDirectory.audio:
        return 'audio';
      case LocalStorageDirectory.attachments:
        return 'attachments';
      case LocalStorageDirectory.exports:
        return 'exports';
      case LocalStorageDirectory.imports:
        return 'imports';
      case LocalStorageDirectory.reports:
        return 'reports';
      case LocalStorageDirectory.temp:
        return 'temp';
    }
  }
}

class LocalFileStorageService {
  LocalFileStorageService({required this.rootDirectory});

  final Directory rootDirectory;

  Future<void> ensureInitialized() async {
    await rootDirectory.create(recursive: true);
    for (final directory in LocalStorageDirectory.values) {
      await directoryFor(directory).create(recursive: true);
    }
  }

  Directory directoryFor(LocalStorageDirectory directory) {
    return Directory(_join(rootDirectory.path, directory.pathSegment));
  }

  Future<LocalFileReference> prepareFile({
    required LocalStorageDirectory directory,
    required String fileName,
  }) async {
    await ensureInitialized();
    final target = File(_join(directoryFor(directory).path, fileName));
    return referenceForFile(target);
  }

  LocalFileReference referenceForFile(File file) {
    final normalizedRoot = _normalizePath(rootDirectory.path);
    final normalizedTarget = _normalizePath(file.absolute.path);

    if (!normalizedTarget.startsWith('$normalizedRoot/')) {
      throw StateError(
        'File must be stored under the local storage root: ${file.path}',
      );
    }

    final relativePath = normalizedTarget.substring(normalizedRoot.length + 1);
    return LocalFileReference(
      relativePath: relativePath,
      absolutePath: normalizedTarget,
    );
  }

  File resolveRelativePath(String relativePath) {
    final sanitized = relativePath.replaceAll('\\', '/');
    if (sanitized.startsWith('/') || sanitized.contains('..')) {
      throw StateError(
        'Relative storage paths must stay under the storage root: $relativePath',
      );
    }
    return File(_join(rootDirectory.path, sanitized));
  }

  Future<String> checksumForRelativePath(String relativePath) {
    return LocalFileChecksum.forFile(resolveRelativePath(relativePath));
  }

  Future<String> checksumForFile(File file) {
    final reference = referenceForFile(file);
    return LocalFileChecksum.forFile(reference.file);
  }

  String _normalizePath(String path) {
    return path.replaceAll('\\', '/').replaceAll(RegExp('/+'), '/');
  }

  String _join(String left, String right) {
    final normalizedLeft = _normalizePath(left).replaceFirst(RegExp('/$'), '');
    final normalizedRight = right.replaceAll('\\', '/').replaceFirst(RegExp('^/'), '');
    return '$normalizedLeft/$normalizedRight';
  }
}