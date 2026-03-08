import 'dart:io';

class LocalFileReference {
  const LocalFileReference({
    required this.relativePath,
    required this.absolutePath,
  });

  final String relativePath;
  final String absolutePath;

  File get file => File(absolutePath);
}