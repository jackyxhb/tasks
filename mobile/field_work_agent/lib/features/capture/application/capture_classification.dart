class CaptureClassification {
  const CaptureClassification({
    required this.type,
    this.confidence,
    this.parseVersion,
  });

  final String type;
  final double? confidence;
  final String? parseVersion;
}