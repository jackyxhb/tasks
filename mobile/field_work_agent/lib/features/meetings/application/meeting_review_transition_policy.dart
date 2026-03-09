import '../../../domain/enums/meeting_review_state.dart';

class MeetingReviewTransitionPolicy {
  const MeetingReviewTransitionPolicy();

  static const Map<MeetingReviewState, Set<MeetingReviewState>> _allowedTransitions = <MeetingReviewState, Set<MeetingReviewState>>{
    MeetingReviewState.draftRecording: <MeetingReviewState>{
      MeetingReviewState.recordedPendingTranscription,
      MeetingReviewState.cancelled,
    },
    MeetingReviewState.recordedPendingTranscription: <MeetingReviewState>{
      MeetingReviewState.transcribing,
      MeetingReviewState.manualReviewOnly,
      MeetingReviewState.cancelled,
    },
    MeetingReviewState.transcribing: <MeetingReviewState>{
      MeetingReviewState.transcribedPendingExtraction,
      MeetingReviewState.transcriptionFailed,
    },
    MeetingReviewState.transcriptionFailed: <MeetingReviewState>{
      MeetingReviewState.transcribing,
      MeetingReviewState.manualReviewOnly,
    },
    MeetingReviewState.transcribedPendingExtraction: <MeetingReviewState>{
      MeetingReviewState.extracting,
      MeetingReviewState.manualReviewOnly,
    },
    MeetingReviewState.extracting: <MeetingReviewState>{
      MeetingReviewState.reviewRequired,
      MeetingReviewState.extractionFailed,
    },
    MeetingReviewState.extractionFailed: <MeetingReviewState>{
      MeetingReviewState.extracting,
      MeetingReviewState.manualReviewOnly,
    },
    MeetingReviewState.manualReviewOnly: <MeetingReviewState>{
      MeetingReviewState.reviewRequired,
      MeetingReviewState.finalized,
    },
    MeetingReviewState.reviewRequired: <MeetingReviewState>{
      MeetingReviewState.reviewInProgress,
      MeetingReviewState.finalized,
      MeetingReviewState.archived,
    },
    MeetingReviewState.reviewInProgress: <MeetingReviewState>{
      MeetingReviewState.reviewRequired,
      MeetingReviewState.taskCandidateResolution,
      MeetingReviewState.finalized,
    },
    MeetingReviewState.taskCandidateResolution: <MeetingReviewState>{
      MeetingReviewState.reviewInProgress,
      MeetingReviewState.finalized,
    },
    MeetingReviewState.finalized: <MeetingReviewState>{
      MeetingReviewState.reopened,
      MeetingReviewState.archived,
    },
    MeetingReviewState.reopened: <MeetingReviewState>{
      MeetingReviewState.reviewInProgress,
      MeetingReviewState.finalized,
    },
    MeetingReviewState.archived: <MeetingReviewState>{
      MeetingReviewState.reopened,
    },
    MeetingReviewState.cancelled: <MeetingReviewState>{},
  };

  bool canTransition({
    required MeetingReviewState from,
    required MeetingReviewState to,
  }) {
    if (from == to) {
      return true;
    }
    final allowedTargets = _allowedTransitions[from];
    return allowedTargets?.contains(to) ?? false;
  }

  void requireTransition({
    required MeetingReviewState from,
    required MeetingReviewState to,
  }) {
    if (canTransition(from: from, to: to)) {
      return;
    }

    final allowedTargets = (_allowedTransitions[from] ?? const <MeetingReviewState>{})
        .map((state) => state.storageValue)
        .join(', ');
    throw StateError(
      'Invalid meeting review-state transition: ${from.storageValue} -> ${to.storageValue}. '
      'Allowed targets: ${allowedTargets.isEmpty ? 'none' : allowedTargets}',
    );
  }
}