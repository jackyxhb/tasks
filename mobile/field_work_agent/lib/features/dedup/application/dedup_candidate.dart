class DedupCandidate {
  const DedupCandidate({
    required this.recordType,
    required this.recordId,
    required this.score,
    required this.reasons,
  });

  final String recordType;
  final String recordId;
  final double score;
  final List<String> reasons;
}