class TranscriptionResult {
  const TranscriptionResult({
    required this.providerName,
    required this.providerModel,
    required this.rawTranscript,
    this.cleanedTranscript,
    this.parseVersion,
  });

  final String providerName;
  final String providerModel;
  final String rawTranscript;
  final String? cleanedTranscript;
  final String? parseVersion;
}

class TranscriptionFailure {
  const TranscriptionFailure({
    required this.providerName,
    required this.providerModel,
    required this.message,
    this.parseVersion,
  });

  final String providerName;
  final String providerModel;
  final String message;
  final String? parseVersion;
}