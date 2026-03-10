import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:field_work_agent/domain/entities/export_run_entity.dart';
import 'package:field_work_agent/domain/entities/import_run_entity.dart';
import 'package:field_work_agent/domain/entities/meeting_entity.dart';
import 'package:field_work_agent/domain/entities/meeting_task_candidate_entity.dart';
import 'package:field_work_agent/domain/entities/project_entity.dart';
import 'package:field_work_agent/domain/entities/raw_capture_entity.dart';
import 'package:field_work_agent/domain/entities/report_run_entity.dart';
import 'package:field_work_agent/domain/entities/task_entity.dart';
import 'package:field_work_agent/domain/enums/meeting_review_state.dart';
import 'package:field_work_agent/domain/enums/raw_capture_channel.dart';
import 'package:field_work_agent/domain/enums/raw_capture_parse_status.dart';
import 'package:field_work_agent/domain/enums/task_candidate_state.dart';
import 'package:field_work_agent/domain/enums/task_type.dart';
import 'package:field_work_agent/src/app_runtime.dart';
import 'package:field_work_agent/src/section_screens.dart';

void main() {
  testWidgets('meeting screen shows pending, failed, and manual fallback states', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final now = DateTime.utc(2026, 3, 9, 8, 0);

    final data = AppShellData(
      projects: const <ProjectEntity>[],
      tasks: const <TaskEntity>[],
      meetings: <MeetingEntity>[
        MeetingEntity(
          id: 'meeting_pending',
          title: 'Morning coordination',
          reviewState: MeetingReviewState.transcribedPendingExtraction,
          needsReview: true,
          transcriptText: 'Transcript is ready.',
          sourceCaptureId: 'capture_pending',
          createdAt: now,
          updatedAt: now,
        ),
        MeetingEntity(
          id: 'meeting_failed',
          title: 'Lift handover',
          reviewState: MeetingReviewState.transcriptionFailed,
          needsReview: true,
          sourceCaptureId: 'capture_failed',
          createdAt: now,
          updatedAt: now,
        ),
        MeetingEntity(
          id: 'meeting_manual',
          title: 'Site walk review',
          reviewState: MeetingReviewState.manualReviewOnly,
          needsReview: true,
          summary: 'Manual notes captured after a network outage.',
          minutesMarkdown: '- Confirm shaft access\n- Recheck lock timing',
          taskCandidates: const <MeetingTaskCandidateEntity>[
            MeetingTaskCandidateEntity(
              id: 'candidate_1',
              taskType: TaskType.maintenance,
              state: TaskCandidateState.newCandidate,
              confidence: 0.74,
              sourceSnippet: 'Recheck lock timing tomorrow morning.',
              taskTitle: 'Recheck lock timing',
              projectName: 'Pompallier Ponsonby',
            ),
          ],
          createdAt: now,
          updatedAt: now,
        ),
      ],
      rawCaptures: <RawCaptureEntity>[
        RawCaptureEntity(
          id: 'capture_pending',
          channel: RawCaptureChannel.audio,
          captureTime: now,
          classificationType: 'meeting',
          parseStatus: RawCaptureParseStatus.parsed,
          createdAt: now,
          audioFilePath: '/tmp/pending.m4a',
        ),
        RawCaptureEntity(
          id: 'capture_failed',
          channel: RawCaptureChannel.audio,
          captureTime: now,
          classificationType: 'meeting',
          parseStatus: RawCaptureParseStatus.failed,
          createdAt: now,
          audioFilePath: '/tmp/failed.m4a',
          transcriptionError: 'Offline: no provider available',
        ),
      ],
      reportRuns: const <ReportRunEntity>[],
      importRuns: const <ImportRunEntity>[],
      exportRuns: const <ExportRunEntity>[],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MeetingsScreen(
            data: data,
            controller: StaticAppShellController(data),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('AI Pending'), findsOneWidget);
    expect(find.text('Manual Fallback'), findsOneWidget);
    expect(find.text('Morning coordination'), findsOneWidget);
    expect(find.text('Lift handover'), findsOneWidget);
    expect(find.text('Site walk review'), findsOneWidget);
    expect(find.text('AI pending'), findsWidgets);
    expect(find.text('Manual fallback'), findsWidgets);
    expect(find.text('Transcription failed'), findsWidgets);
    expect(find.textContaining('Offline: no provider available'), findsOneWidget);
  });
}