enum TaskCandidateState {
  newCandidate,
  acceptedAsNewTask,
  mergedIntoExistingTask,
  savedAsProvisionalTask,
  rejected,
}

extension TaskCandidateStateCodec on TaskCandidateState {
  String get storageValue {
    switch (this) {
      case TaskCandidateState.newCandidate:
        return 'new_candidate';
      case TaskCandidateState.acceptedAsNewTask:
        return 'accepted_as_new_task';
      case TaskCandidateState.mergedIntoExistingTask:
        return 'merged_into_existing_task';
      case TaskCandidateState.savedAsProvisionalTask:
        return 'saved_as_provisional_task';
      case TaskCandidateState.rejected:
        return 'rejected';
    }
  }
}

TaskCandidateState taskCandidateStateFromStorage(String value) {
  for (final state in TaskCandidateState.values) {
    if (state.storageValue == value) {
      return state;
    }
  }
  return TaskCandidateState.newCandidate;
}