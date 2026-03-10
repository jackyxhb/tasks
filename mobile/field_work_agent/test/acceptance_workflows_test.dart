import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:field_work_agent/domain/enums/meeting_review_state.dart';
import 'package:field_work_agent/features/capture/application/capture_classification.dart';
import 'package:field_work_agent/features/exchange/application/exchange_models.dart';
import 'package:field_work_agent/features/projects/application/project_draft.dart';
import 'package:field_work_agent/features/reports/application/report_models.dart';
import 'package:field_work_agent/features/search/application/search_models.dart';
import 'package:field_work_agent/features/tasks/application/task_models.dart';

import 'support/acceptance_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('acceptance workflows', () {
    late AcceptanceHarness harness;
    late ValidationSeedData seed;

    setUp(() async {
      harness = await AcceptanceHarness.create();
      seed = await loadValidationSeed();
    });

    tearDown(() async {
      await harness.dispose();
    });

    test(
        'seed fixture represents the Pompallier Ponsonby task and meeting scenario',
        () async {
      expect(seed.project.projectName, 'Pompallier Ponsonby');
      expect(seed.project.clientOem, 'OTIS');
      expect(seed.textCapture.task.taskTitle,
          'On-site training support for Lin Yong');
      expect(seed.meeting.title, 'Pompallier Ponsonby Coordination');
      expect(seed.meeting.extractionJson, contains('candidate_001'));
    });

    test('text capture to final task works', () async {
      final project = await harness.projectCrudService.create(
        ProjectDraft(
          projectName: seed.project.projectName,
          clientOem: seed.project.clientOem,
          siteLocation: seed.project.siteLocation,
          siteContactName: seed.project.siteContactName,
          siteContactPhone: seed.project.siteContactPhone,
          coordinatorName: seed.project.coordinatorName,
          projectManagerName: seed.project.projectManagerName,
        ),
      );

      final capture = await harness.rawCaptureIntakeService.createTextCapture(
        channel: seed.textCapture.channel,
        rawText: seed.textCapture.rawText,
      );
      final classifiedCapture =
          await harness.captureClassificationService.applyClassification(
        captureId: capture.id,
        classification: CaptureClassification(
          type: seed.textCapture.classificationType,
          confidence: seed.textCapture.classificationConfidence,
          parseVersion: 'acceptance-v1',
        ),
      );
      final task = await harness.taskCrudService.create(
        TaskDraft(
          projectId: project.id,
          projectName: seed.project.projectName,
          taskType: seed.textCapture.task.taskType,
          taskTitle: seed.textCapture.task.taskTitle,
          description: seed.textCapture.task.description,
          scheduledDate: seed.textCapture.task.scheduledDate,
          startTimeLocal: seed.textCapture.task.startTimeLocal,
          locationSnapshot: seed.textCapture.task.locationSnapshot,
          workerName: seed.textCapture.task.workerName,
          workerPhone: seed.textCapture.task.workerPhone,
          coordinatorName: seed.textCapture.task.coordinatorName,
          agenteeName: seed.textCapture.task.agenteeName,
          status: seed.textCapture.task.status,
          priority: seed.textCapture.task.priority,
          sourceCaptureId: classifiedCapture.id,
          isProvisional: false,
          needsReview: false,
        ),
      );

      final storedTasks = await harness.taskCrudService.browse();
      expect(task.projectId, project.id);
      expect(task.taskTitle, seed.textCapture.task.taskTitle);
      expect(task.dedupKey, isNotNull);
      expect(storedTasks.single.id, task.id);
      expect(classifiedCapture.classificationType, 'task');
    });

    test('meeting audio to reviewed meeting and task candidates works',
        () async {
      final project = await harness.projectCrudService.create(
        ProjectDraft(
          projectName: seed.project.projectName,
          clientOem: seed.project.clientOem,
          siteLocation: seed.project.siteLocation,
          siteContactName: seed.project.siteContactName,
          siteContactPhone: seed.project.siteContactPhone,
          coordinatorName: seed.project.coordinatorName,
        ),
      );

      final session = await harness.meetingRecordingService.startRecording(
        title: seed.meeting.title,
        projectIds: <String>[project.id],
      );
      final audioFile =
          harness.storageService.resolveRelativePath(session.audioRelativePath);
      await audioFile.parent.create(recursive: true);
      await audioFile.writeAsString('acceptance audio bytes');

      final stoppedSession =
          await harness.meetingRecordingService.stopRecording(session);
      final transcribedMeeting =
          await harness.meetingTranscriptService.transcribeMeeting(
        meetingId: stoppedSession.meeting.id,
        provider: StubTranscriptionProvider(seed.meeting.transcription),
      );
      final extraction =
          await harness.meetingExtractionService.applyExtractionJson(
        meetingId: transcribedMeeting.id,
        extractionJson: seed.meeting.extractionJson,
      );
      final reviewInProgress = await harness.meetingReviewService.beginReview(
        meetingId: extraction.meeting.id,
      );
      final reviewedMeeting =
          await harness.meetingReviewService.beginTaskCandidateResolution(
        meetingId: reviewInProgress.id,
      );

      expect(stoppedSession.meeting.reviewState,
          MeetingReviewState.recordedPendingTranscription);
      expect(transcribedMeeting.reviewState,
          MeetingReviewState.transcribedPendingExtraction);
      expect(extraction.isSuccess, isTrue);
      expect(reviewedMeeting.reviewState,
          MeetingReviewState.taskCandidateResolution);
      expect(reviewedMeeting.taskCandidates, hasLength(1));
      expect(reviewedMeeting.taskCandidates.single.taskTitle,
          seed.textCapture.task.taskTitle);

      final resolution = await harness.meetingTaskCandidateResolutionService
          .saveAsProvisionalTask(
        meetingId: reviewedMeeting.id,
        candidateId: reviewedMeeting.taskCandidates.single.id,
        agenteeName: seed.textCapture.task.agenteeName,
      );
      expect(resolution.task, isNotNull);
      expect(resolution.task!.isProvisional, isTrue);
    });

    test('invalid extraction payload fails safely without mutating meeting candidates',
        () async {
      final session = await harness.meetingRecordingService.startRecording(
        title: seed.meeting.title,
      );
      final audioFile =
          harness.storageService.resolveRelativePath(session.audioRelativePath);
      await audioFile.parent.create(recursive: true);
      await audioFile.writeAsString('acceptance audio bytes');

      final stoppedSession =
          await harness.meetingRecordingService.stopRecording(session);
      final transcribedMeeting =
          await harness.meetingTranscriptService.transcribeMeeting(
        meetingId: stoppedSession.meeting.id,
        provider: StubTranscriptionProvider(seed.meeting.transcription),
      );

      final extraction =
          await harness.meetingExtractionService.applyExtractionJson(
        meetingId: transcribedMeeting.id,
        extractionJson: '{"schema_version":"v1"}',
      );

      expect(extraction.isSuccess, isFalse);
      expect(extraction.validationIssues, isNotEmpty);
      expect(extraction.meeting.reviewState,
          MeetingReviewState.extractionFailed);
      expect(extraction.meeting.taskCandidates, isEmpty);
      expect(extraction.meeting.title, seed.meeting.title);
    });

    test('candidate resolution requires task-candidate-resolution state',
        () async {
      final session = await harness.meetingRecordingService.startRecording(
        title: seed.meeting.title,
      );
      final audioFile =
          harness.storageService.resolveRelativePath(session.audioRelativePath);
      await audioFile.parent.create(recursive: true);
      await audioFile.writeAsString('acceptance audio bytes');

      final stoppedSession =
          await harness.meetingRecordingService.stopRecording(session);
      final transcribedMeeting =
          await harness.meetingTranscriptService.transcribeMeeting(
        meetingId: stoppedSession.meeting.id,
        provider: StubTranscriptionProvider(seed.meeting.transcription),
      );
      final extraction =
          await harness.meetingExtractionService.applyExtractionJson(
        meetingId: transcribedMeeting.id,
        extractionJson: seed.meeting.extractionJson,
      );
      final reviewInProgress = await harness.meetingReviewService.beginReview(
        meetingId: extraction.meeting.id,
      );

      await expectLater(
        () => harness.meetingTaskCandidateResolutionService
            .saveAsProvisionalTask(
          meetingId: reviewInProgress.id,
          candidateId: reviewInProgress.taskCandidates.single.id,
          agenteeName: seed.textCapture.task.agenteeName,
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('task_candidate_resolution'),
          ),
        ),
      );
    });

    test('meeting cannot finalize until all task candidates are resolved',
        () async {
      final session = await harness.meetingRecordingService.startRecording(
        title: seed.meeting.title,
      );
      final audioFile =
          harness.storageService.resolveRelativePath(session.audioRelativePath);
      await audioFile.parent.create(recursive: true);
      await audioFile.writeAsString('acceptance audio bytes');

      final stoppedSession =
          await harness.meetingRecordingService.stopRecording(session);
      final transcribedMeeting =
          await harness.meetingTranscriptService.transcribeMeeting(
        meetingId: stoppedSession.meeting.id,
        provider: StubTranscriptionProvider(seed.meeting.transcription),
      );
      final extraction =
          await harness.meetingExtractionService.applyExtractionJson(
        meetingId: transcribedMeeting.id,
        extractionJson: seed.meeting.extractionJson,
      );
      final reviewInProgress = await harness.meetingReviewService.beginReview(
        meetingId: extraction.meeting.id,
      );
      final resolvingMeeting =
          await harness.meetingReviewService.beginTaskCandidateResolution(
        meetingId: reviewInProgress.id,
      );

      await expectLater(
        () => harness.meetingReviewService.finalizeMeeting(
          meetingId: resolvingMeeting.id,
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('unresolved task candidates'),
          ),
        ),
      );

      final resolution = await harness.meetingTaskCandidateResolutionService
          .saveAsProvisionalTask(
        meetingId: resolvingMeeting.id,
        candidateId: resolvingMeeting.taskCandidates.single.id,
        agenteeName: seed.textCapture.task.agenteeName,
      );
      final finalizedMeeting = await harness.meetingReviewService.finalizeMeeting(
        meetingId: resolution.meeting.id,
      );

      expect(finalizedMeeting.reviewState, MeetingReviewState.finalized);
      expect(finalizedMeeting.needsReview, isFalse);
    });

    test(
        'export then import round-trip plus search and reports work on created records',
        () async {
      final project = await harness.projectCrudService.create(
        ProjectDraft(
          projectName: seed.project.projectName,
          clientOem: seed.project.clientOem,
          siteLocation: seed.project.siteLocation,
          siteContactName: seed.project.siteContactName,
          siteContactPhone: seed.project.siteContactPhone,
          coordinatorName: seed.project.coordinatorName,
        ),
      );
      final task = await harness.taskCrudService.create(
        TaskDraft(
          projectId: project.id,
          projectName: seed.project.projectName,
          taskType: seed.textCapture.task.taskType,
          taskTitle: seed.textCapture.task.taskTitle,
          description: seed.textCapture.task.description,
          scheduledDate: seed.textCapture.task.scheduledDate,
          startTimeLocal: seed.textCapture.task.startTimeLocal,
          locationSnapshot: seed.textCapture.task.locationSnapshot,
          workerName: seed.textCapture.task.workerName,
          workerPhone: seed.textCapture.task.workerPhone,
          coordinatorName: seed.textCapture.task.coordinatorName,
          agenteeName: seed.textCapture.task.agenteeName,
          status: seed.textCapture.task.status,
          priority: seed.textCapture.task.priority,
          isProvisional: false,
          needsReview: false,
        ),
      );

      final session = await harness.meetingRecordingService.startRecording(
        title: seed.meeting.title,
        projectIds: <String>[project.id],
      );
      final audioFile =
          harness.storageService.resolveRelativePath(session.audioRelativePath);
      await audioFile.parent.create(recursive: true);
      await audioFile.writeAsString('acceptance audio bytes');
      final stoppedSession =
          await harness.meetingRecordingService.stopRecording(session);
      final transcribedMeeting =
          await harness.meetingTranscriptService.transcribeMeeting(
        meetingId: stoppedSession.meeting.id,
        provider: StubTranscriptionProvider(seed.meeting.transcription),
      );
      final extractedMeeting =
          (await harness.meetingExtractionService.applyExtractionJson(
        meetingId: transcribedMeeting.id,
        extractionJson: seed.meeting.extractionJson,
      ))
              .meeting;
      final reviewInProgress = await harness.meetingReviewService
          .beginReview(meetingId: extractedMeeting.id);

      final searchResults = await harness.searchService.search(
        const SearchRequest(query: 'Pompallier', limitPerGroup: 10),
      );
      final taskSearchResults = await harness.searchService.search(
        const SearchRequest(query: 'training', limitPerGroup: 10),
      );
      final meetingSearchResults = await harness.searchService.search(
        const SearchRequest(query: 'Coordination', limitPerGroup: 10),
      );
      expect(
          searchResults.projects
              .any((hit) => hit.title.contains('Pompallier Ponsonby')),
          isTrue);
      expect(
          taskSearchResults.tasks
              .any((hit) => hit.title.contains('On-site training support')),
          isTrue);
      expect(
          meetingSearchResults.meetings.any(
              (hit) => hit.title.contains('Pompallier Ponsonby Coordination')),
          isTrue);

      final dailyReport = await harness.reportService.generateDailyTaskList(
        date: seed.textCapture.task.scheduledDate,
        outputFormat: ReportOutputFormat.json,
      );
      final projectReport = await harness.reportService.generateProjectSummary(
        projectId: project.id,
        outputFormat: ReportOutputFormat.inApp,
      );
      final minutesPack =
          await harness.reportService.generateMeetingMinutesPack(
        filter: ReportFilter(projectId: project.id),
        outputFormat: ReportOutputFormat.csv,
      );

      expect(dailyReport.summary, contains('Daily task list'));
      expect(projectReport.payload['task_count'], 1);
      expect(minutesPack.outputPath, isNotNull);
      expect(
          File(harness.storageService
                  .resolveRelativePath(minutesPack.outputPath!)
                  .path)
              .existsSync(),
          isTrue);

      final bundle = await harness.exportBundleCreatorService.createBundle(
        scope: const ExportScopeRequest(
            type: 'project', value: 'Pompallier Ponsonby'),
      );
      expect(
          bundle.projects
              .any((record) => record['project_name'] == 'Pompallier Ponsonby'),
          isTrue);
      expect(bundle.tasks.any((record) => record['id'] == task.id), isTrue);
      expect(
          bundle.meetings.any((record) => record['id'] == reviewInProgress.id),
          isTrue);

      final importRelativePath = 'imports/${bundle.bundleId}.json';
      final exportFile = harness.storageService
          .resolveRelativePath('exports/${bundle.bundleId}.json');
      final importFile =
          harness.storageService.resolveRelativePath(importRelativePath);
      await importFile.parent.create(recursive: true);
      await importFile.writeAsString(await exportFile.readAsString());

      final preview = await harness.importPreviewAndApplyService.previewBundle(
        relativeImportPath: importRelativePath,
      );
      expect(preview.projectCount, greaterThanOrEqualTo(1));
      expect(preview.taskCount, greaterThanOrEqualTo(1));
      expect(preview.meetingCount, greaterThanOrEqualTo(1));

      await harness.importPreviewAndApplyService
          .applyBundle(relativeImportPath: importRelativePath);
      final importedProject =
          await harness.database.projects.findById(project.id);
      final importedTask = await harness.database.tasks.findById(task.id);
      final importedMeeting =
          await harness.database.meetings.findById(reviewInProgress.id);

      expect(importedProject, isNotNull);
      expect(importedTask, isNotNull);
      expect(importedMeeting, isNotNull);
    });
  });
}
