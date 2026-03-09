import '../../../data/database/repositories/meeting_repository.dart';
import '../../../data/database/repositories/project_repository.dart';
import '../../../domain/entities/project_entity.dart';
import '../../../domain/enums/task_candidate_state.dart';
import '../application/meeting_review_models.dart';

class MeetingReviewPresenter {
  const MeetingReviewPresenter({
    required this.meetingRepository,
    required this.projectRepository,
  });

  final MeetingRepository meetingRepository;
  final ProjectRepository projectRepository;

  Future<MeetingReviewViewModel> build(String meetingId) async {
    final meeting = await meetingRepository.findById(meetingId);
    if (meeting == null) {
      throw StateError('Meeting not found: $meetingId');
    }

    final linkedProjects = <ProjectEntity>[];
    for (final projectId in meeting.projectIds) {
      final project = await projectRepository.findById(projectId);
      if (project != null) {
        linkedProjects.add(project);
      }
    }

    final candidateViews = <MeetingReviewCandidateView>[];
    for (final candidate in meeting.taskCandidates) {
      ProjectEntity? linkedProject;
      if (candidate.projectName != null) {
        linkedProject = await projectRepository.findByNormalizedName(candidate.projectName!);
      }
      candidateViews.add(
        MeetingReviewCandidateView(
          candidate: candidate,
          linkedProject: linkedProject,
          isResolved: candidate.state != TaskCandidateState.newCandidate,
        ),
      );
    }

    return MeetingReviewViewModel(
      meeting: meeting,
      linkedProjects: linkedProjects,
      candidates: candidateViews,
      hasTranscript: _hasText(meeting.transcriptText),
      hasMinutes: _hasText(meeting.minutesMarkdown),
      unresolvedCandidateCount: candidateViews.where((candidate) => !candidate.isResolved).length,
    );
  }

  bool _hasText(String? value) {
    return value != null && value.trim().isNotEmpty;
  }
}