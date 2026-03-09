import 'dart:convert';

import '../../../domain/entities/meeting_entity.dart';
import '../../../domain/entities/meeting_task_candidate_entity.dart';
import '../../../domain/enums/meeting_review_state.dart';
import '../../../domain/enums/task_candidate_state.dart';
import '../../../domain/enums/task_type.dart';
import '../database_executor.dart';
import '../database_value_codec.dart';

class MeetingRepository {
  const MeetingRepository(this.executor);

  final DatabaseExecutor executor;

  Future<void> save(MeetingEntity meeting) {
    return executor.transaction((txn) async {
      await txn.execute(
        'INSERT OR REPLACE INTO meetings ('
        'id, title, meeting_datetime, meeting_timezone, location_text, '
        'summary, minutes_markdown, transcript_text, source_capture_id, '
        'source_hash, review_state, needs_review, created_at, updated_at, '
        'archived_at'
        ') VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        <Object?>[
          meeting.id,
          meeting.title,
          meeting.meetingDateTime?.toUtc().toIso8601String(),
          meeting.meetingTimezone,
          meeting.locationText,
          meeting.summary,
          meeting.minutesMarkdown,
          meeting.transcriptText,
          meeting.sourceCaptureId,
          meeting.sourceHash,
          meeting.reviewState.storageValue,
          DatabaseValueCodec.boolToSql(meeting.needsReview),
          meeting.createdAt.toUtc().toIso8601String(),
          meeting.updatedAt.toUtc().toIso8601String(),
          meeting.archivedAt?.toUtc().toIso8601String(),
        ],
      );
      await txn.execute(
        'DELETE FROM meeting_projects WHERE meeting_id = ?',
        <Object?>[meeting.id],
      );
      for (final projectId in meeting.projectIds) {
        await txn.execute(
          'INSERT INTO meeting_projects(meeting_id, project_id) VALUES (?, ?)',
          <Object?>[meeting.id, projectId],
        );
      }
      await txn.execute(
        'DELETE FROM meeting_task_candidates WHERE meeting_id = ?',
        <Object?>[meeting.id],
      );
      await txn.execute(
        'DELETE FROM meeting_tasks WHERE meeting_id = ?',
        <Object?>[meeting.id],
      );
      for (final candidate in meeting.taskCandidates) {
        await txn.execute(
          'INSERT INTO meeting_task_candidates ('
          'meeting_id, candidate_id, task_type, task_title, description, '
          'project_name, worker_name, worker_phone, coordinator_name, '
          'project_manager_name, scheduled_date_text, start_time_text, '
          'duration_text, location_text, state, confidence, source_snippet, '
          'ambiguities_json, linked_task_id'
          ') VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
          <Object?>[
            meeting.id,
            candidate.id,
            candidate.taskType.storageValue,
            candidate.taskTitle,
            candidate.description,
            candidate.projectName,
            candidate.workerName,
            candidate.workerPhone,
            candidate.coordinatorName,
            candidate.projectManagerName,
            candidate.scheduledDateText,
            candidate.startTimeText,
            candidate.durationText,
            candidate.locationText,
            candidate.state.storageValue,
            candidate.confidence,
            candidate.sourceSnippet,
            jsonEncode(candidate.ambiguities),
            candidate.linkedTaskId,
          ],
        );
        if (candidate.linkedTaskId != null) {
          await txn.execute(
            'INSERT INTO meeting_tasks(meeting_id, task_id, extraction_confidence) VALUES (?, ?, ?)',
            <Object?>[meeting.id, candidate.linkedTaskId, candidate.confidence],
          );
        }
      }
    });
  }

  Future<MeetingEntity?> findById(String id) async {
    final rows = await executor.query(
      'SELECT * FROM meetings WHERE id = ? LIMIT 1',
      <Object?>[id],
    );
    if (rows.isEmpty) {
      return null;
    }
    return _fromRow(rows.first);
  }

  Future<List<MeetingEntity>> listAll() async {
    final rows = await executor.query(
      'SELECT * FROM meetings ORDER BY updated_at DESC',
    );
    return Future.wait(rows.map(_fromRow));
  }

  Future<MeetingEntity> _fromRow(DatabaseRow row) async {
    final meetingId = DatabaseValueCodec.string(row['id']);
    final projectRows = await executor.query(
      'SELECT project_id FROM meeting_projects WHERE meeting_id = ? ORDER BY project_id ASC',
      <Object?>[meetingId],
    );
    final candidateRows = await executor.query(
      'SELECT * FROM meeting_task_candidates WHERE meeting_id = ? ORDER BY candidate_id ASC',
      <Object?>[meetingId],
    );

    return MeetingEntity(
      id: meetingId,
      title: DatabaseValueCodec.stringOrNull(row['title']),
      meetingDateTime: DatabaseValueCodec.dateTimeOrNull(
        row['meeting_datetime'],
      ),
      meetingTimezone: DatabaseValueCodec.stringOrNull(row['meeting_timezone']),
      locationText: DatabaseValueCodec.stringOrNull(row['location_text']),
      summary: DatabaseValueCodec.stringOrNull(row['summary']),
      minutesMarkdown: DatabaseValueCodec.stringOrNull(row['minutes_markdown']),
      transcriptText: DatabaseValueCodec.stringOrNull(row['transcript_text']),
      sourceCaptureId: DatabaseValueCodec.stringOrNull(row['source_capture_id']),
      sourceHash: DatabaseValueCodec.stringOrNull(row['source_hash']),
      reviewState: meetingReviewStateFromStorage(
        DatabaseValueCodec.string(row['review_state']),
      ),
      needsReview: DatabaseValueCodec.boolFromSql(row['needs_review']),
      projectIds: projectRows
          .map((projectRow) => DatabaseValueCodec.string(projectRow['project_id']))
          .toList(growable: false),
      taskCandidates: candidateRows.map(_candidateFromRow).toList(growable: false),
      createdAt: DatabaseValueCodec.dateTime(row['created_at']),
      updatedAt: DatabaseValueCodec.dateTime(row['updated_at']),
      archivedAt: DatabaseValueCodec.dateTimeOrNull(row['archived_at']),
    );
  }

  MeetingTaskCandidateEntity _candidateFromRow(DatabaseRow row) {
    final ambiguitiesJson = DatabaseValueCodec.string(row['ambiguities_json']);
    final decodedAmbiguities = jsonDecode(ambiguitiesJson);
    final ambiguities = decodedAmbiguities is List
        ? decodedAmbiguities.map((item) => item.toString()).toList(growable: false)
        : const <String>[];

    return MeetingTaskCandidateEntity(
      id: DatabaseValueCodec.string(row['candidate_id']),
      taskType: taskTypeFromStorage(DatabaseValueCodec.string(row['task_type'])),
      state: taskCandidateStateFromStorage(DatabaseValueCodec.string(row['state'])),
      confidence: (row['confidence'] as num).toDouble(),
      sourceSnippet: DatabaseValueCodec.string(row['source_snippet']),
      taskTitle: DatabaseValueCodec.stringOrNull(row['task_title']),
      description: DatabaseValueCodec.stringOrNull(row['description']),
      projectName: DatabaseValueCodec.stringOrNull(row['project_name']),
      workerName: DatabaseValueCodec.stringOrNull(row['worker_name']),
      workerPhone: DatabaseValueCodec.stringOrNull(row['worker_phone']),
      coordinatorName: DatabaseValueCodec.stringOrNull(row['coordinator_name']),
      projectManagerName: DatabaseValueCodec.stringOrNull(row['project_manager_name']),
      scheduledDateText: DatabaseValueCodec.stringOrNull(row['scheduled_date_text']),
      startTimeText: DatabaseValueCodec.stringOrNull(row['start_time_text']),
      durationText: DatabaseValueCodec.stringOrNull(row['duration_text']),
      locationText: DatabaseValueCodec.stringOrNull(row['location_text']),
      ambiguities: ambiguities,
      linkedTaskId: DatabaseValueCodec.stringOrNull(row['linked_task_id']),
    );
  }
}