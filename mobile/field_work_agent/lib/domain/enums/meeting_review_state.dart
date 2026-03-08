enum MeetingReviewState {
  draftRecording,
  recordedPendingTranscription,
  transcribing,
  transcriptionFailed,
  transcribedPendingExtraction,
  extracting,
  extractionFailed,
  manualReviewOnly,
  reviewRequired,
  reviewInProgress,
  taskCandidateResolution,
  finalized,
  reopened,
  archived,
  cancelled,
}

extension MeetingReviewStateCodec on MeetingReviewState {
  String get storageValue {
    switch (this) {
      case MeetingReviewState.draftRecording:
        return 'draft_recording';
      case MeetingReviewState.recordedPendingTranscription:
        return 'recorded_pending_transcription';
      case MeetingReviewState.transcribing:
        return 'transcribing';
      case MeetingReviewState.transcriptionFailed:
        return 'transcription_failed';
      case MeetingReviewState.transcribedPendingExtraction:
        return 'transcribed_pending_extraction';
      case MeetingReviewState.extracting:
        return 'extracting';
      case MeetingReviewState.extractionFailed:
        return 'extraction_failed';
      case MeetingReviewState.manualReviewOnly:
        return 'manual_review_only';
      case MeetingReviewState.reviewRequired:
        return 'review_required';
      case MeetingReviewState.reviewInProgress:
        return 'review_in_progress';
      case MeetingReviewState.taskCandidateResolution:
        return 'task_candidate_resolution';
      case MeetingReviewState.finalized:
        return 'finalized';
      case MeetingReviewState.reopened:
        return 'reopened';
      case MeetingReviewState.archived:
        return 'archived';
      case MeetingReviewState.cancelled:
        return 'cancelled';
    }
  }
}

MeetingReviewState meetingReviewStateFromStorage(String value) {
  for (final state in MeetingReviewState.values) {
    if (state.storageValue == value) {
      return state;
    }
  }
  return MeetingReviewState.reviewRequired;
}