class AttachmentEntity {
  const AttachmentEntity({
    required this.id,
    required this.ownerRecordType,
    required this.ownerRecordId,
    required this.filePath,
    required this.createdAt,
    this.mimeType,
    this.fileSize,
    this.checksum,
  });

  final String id;
  final String ownerRecordType;
  final String ownerRecordId;
  final String filePath;
  final String? mimeType;
  final int? fileSize;
  final String? checksum;
  final DateTime createdAt;
}