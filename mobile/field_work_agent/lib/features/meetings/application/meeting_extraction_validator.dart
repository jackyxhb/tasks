import 'dart:convert';

import '../../../domain/enums/task_type.dart';
import 'meeting_extraction_payload.dart';

class MeetingExtractionValidationIssue {
  const MeetingExtractionValidationIssue({
    required this.path,
    required this.message,
  });

  final String path;
  final String message;

  Map<String, String> toJson() {
    return <String, String>{
      'path': path,
      'message': message,
    };
  }
}

class MeetingExtractionValidationResult {
  const MeetingExtractionValidationResult({
    required this.payload,
    required this.issues,
  });

  final MeetingExtractionPayload? payload;
  final List<MeetingExtractionValidationIssue> issues;

  bool get isValid => payload != null && issues.isEmpty;
}

class MeetingExtractionValidator {
  const MeetingExtractionValidator();

  MeetingExtractionValidationResult validateJson(String payloadJson) {
    final issues = <MeetingExtractionValidationIssue>[];
    final decoded = _decodeJson(payloadJson, issues);
    if (decoded == null) {
      return MeetingExtractionValidationResult(payload: null, issues: issues);
    }
    return validateDecoded(decoded);
  }

  MeetingExtractionValidationResult validateDecoded(Object? decoded) {
    final issues = <MeetingExtractionValidationIssue>[];
    final payload = _parsePayload(decoded, issues);
    return MeetingExtractionValidationResult(payload: payload, issues: issues);
  }

  Object? _decodeJson(
    String payloadJson,
    List<MeetingExtractionValidationIssue> issues,
  ) {
    try {
      return jsonDecode(payloadJson);
    } on FormatException catch (error) {
      issues.add(
        MeetingExtractionValidationIssue(
          path: r'$',
          message: 'Invalid JSON: ${error.message}',
        ),
      );
      return null;
    }
  }

  MeetingExtractionPayload? _parsePayload(
    Object? decoded,
    List<MeetingExtractionValidationIssue> issues,
  ) {
    final root = _requireObject(decoded, r'$', issues);
    if (root == null) {
      return null;
    }

    final schemaVersion = _requireString(root['schema_version'], 'schema_version', issues);
    final requestId = _requireString(root['request_id'], 'request_id', issues);
    final provider = _parseProvider(root['provider'], 'provider', issues);
    final transcription = _parseTranscription(root['transcription'], 'transcription', issues);
    final meeting = _parseMeeting(root['meeting'], 'meeting', issues);
    final projectCandidates = _parseProjectCandidates(root['project_candidates'], 'project_candidates', issues);
    final peopleMentions = _parsePeopleMentions(root['people_mentions'], 'people_mentions', issues);
    final taskCandidates = _parseTaskCandidates(root['task_candidates'], 'task_candidates', issues);
    final confidence = _parseConfidence(root['confidence'], 'confidence', issues);
    final warnings = _requireStringList(root['warnings'], 'warnings', issues);

    if (schemaVersion != null && schemaVersion != 'v1') {
      issues.add(
        const MeetingExtractionValidationIssue(
          path: 'schema_version',
          message: 'Only schema_version "v1" is supported.',
        ),
      );
    }

    if (schemaVersion == null ||
        requestId == null ||
        provider == null ||
        transcription == null ||
        meeting == null ||
        projectCandidates == null ||
        peopleMentions == null ||
        taskCandidates == null ||
        confidence == null ||
        warnings == null ||
        issues.isNotEmpty) {
      return null;
    }

    return MeetingExtractionPayload(
      schemaVersion: schemaVersion,
      requestId: requestId,
      provider: provider,
      transcription: transcription,
      meeting: meeting,
      projectCandidates: projectCandidates,
      peopleMentions: peopleMentions,
      taskCandidates: taskCandidates,
      confidence: confidence,
      warnings: warnings,
    );
  }

  MeetingExtractionProvider? _parseProvider(
    Object? raw,
    String path,
    List<MeetingExtractionValidationIssue> issues,
  ) {
    final object = _requireObject(raw, path, issues);
    if (object == null) {
      return null;
    }
    final name = _requireString(object['name'], '$path.name', issues);
    final model = _requireString(object['model'], '$path.model', issues);
    if (name == null || model == null) {
      return null;
    }
    return MeetingExtractionProvider(name: name, model: model);
  }

  MeetingExtractionTranscription? _parseTranscription(
    Object? raw,
    String path,
    List<MeetingExtractionValidationIssue> issues,
  ) {
    final object = _requireObject(raw, path, issues);
    if (object == null) {
      return null;
    }

    final languageMode = _optionalString(object['language_mode'], '$path.language_mode', issues);
    final detectedLanguages = _requireStringList(
      object['detected_languages'],
      '$path.detected_languages',
      issues,
    );
    final rawTranscript = _optionalString(object['raw_transcript'], '$path.raw_transcript', issues);
    final cleanedTranscript = _optionalString(
      object['cleaned_transcript'],
      '$path.cleaned_transcript',
      issues,
    );
    _validateSpeakerSegments(object['speaker_segments'], '$path.speaker_segments', issues);

    if ((rawTranscript == null || rawTranscript.isEmpty) &&
        (cleanedTranscript == null || cleanedTranscript.isEmpty)) {
      issues.add(
        MeetingExtractionValidationIssue(
          path: path,
          message: 'At least one of raw_transcript or cleaned_transcript must be present.',
        ),
      );
    }

    if (detectedLanguages == null) {
      return null;
    }

    return MeetingExtractionTranscription(
      languageMode: languageMode,
      detectedLanguages: detectedLanguages,
      rawTranscript: rawTranscript,
      cleanedTranscript: cleanedTranscript,
    );
  }

  MeetingExtractionMeeting? _parseMeeting(
    Object? raw,
    String path,
    List<MeetingExtractionValidationIssue> issues,
  ) {
    final object = _requireObject(raw, path, issues);
    if (object == null) {
      return null;
    }

    final title = _requireString(object['title'], '$path.title', issues);
    final dateTimeText = _optionalString(
      object['meeting_datetime_text'],
      '$path.meeting_datetime_text',
      issues,
    );
    final locationText = _optionalString(
      object['meeting_location_text'],
      '$path.meeting_location_text',
      issues,
    );
    final summary = _requireString(object['summary'], '$path.summary', issues);
    final minutesItems = _parseEvidenceItems(
      object['minutes_items'],
      '$path.minutes_items',
      issues,
      requireSequence: true,
    );
    final decisionItems = _parseEvidenceItems(
      object['decision_items'],
      '$path.decision_items',
      issues,
      requireSequence: true,
    );
    final openQuestions = _parseOpenQuestions(
      object['open_questions'],
      '$path.open_questions',
      issues,
    );

    if (title == null ||
        summary == null ||
        minutesItems == null ||
        decisionItems == null ||
        openQuestions == null) {
      return null;
    }

    return MeetingExtractionMeeting(
      title: title,
      meetingDateTimeText: dateTimeText,
      meetingLocationText: locationText,
      summary: summary,
      minutesItems: minutesItems,
      decisionItems: decisionItems,
      openQuestions: openQuestions,
    );
  }

  List<MeetingExtractionEvidenceItem>? _parseEvidenceItems(
    Object? raw,
    String path,
    List<MeetingExtractionValidationIssue> issues, {
    required bool requireSequence,
  }) {
    final list = _requireList(raw, path, issues);
    if (list == null) {
      return null;
    }

    final items = <MeetingExtractionEvidenceItem>[];
    for (var index = 0; index < list.length; index += 1) {
      final itemPath = '$path[$index]';
      final object = _requireObject(list[index], itemPath, issues);
      if (object == null) {
        continue;
      }
      final sequence = requireSequence
          ? _requireInt(object['sequence'], '$itemPath.sequence', issues)
          : _optionalInt(object['sequence'], '$itemPath.sequence', issues);
      final text = _requireString(object['text'], '$itemPath.text', issues);
      final confidence = _requireConfidence(object['confidence'], '$itemPath.confidence', issues);
      final sourceSnippet = _requireString(
        object['source_snippet'],
        '$itemPath.source_snippet',
        issues,
      );

      if (text == null || confidence == null || sourceSnippet == null) {
        continue;
      }

      items.add(
        MeetingExtractionEvidenceItem(
          sequence: sequence,
          text: text,
          confidence: confidence,
          sourceSnippet: sourceSnippet,
        ),
      );
    }
    return items;
  }

  List<MeetingExtractionOpenQuestion>? _parseOpenQuestions(
    Object? raw,
    String path,
    List<MeetingExtractionValidationIssue> issues,
  ) {
    final list = _requireList(raw, path, issues);
    if (list == null) {
      return null;
    }

    final items = <MeetingExtractionOpenQuestion>[];
    for (var index = 0; index < list.length; index += 1) {
      final itemPath = '$path[$index]';
      final object = _requireObject(list[index], itemPath, issues);
      if (object == null) {
        continue;
      }
      final text = _requireString(object['text'], '$itemPath.text', issues);
      final confidence = _requireConfidence(object['confidence'], '$itemPath.confidence', issues);
      final sourceSnippet = _requireString(
        object['source_snippet'],
        '$itemPath.source_snippet',
        issues,
      );

      if (text == null || confidence == null || sourceSnippet == null) {
        continue;
      }

      items.add(
        MeetingExtractionOpenQuestion(
          text: text,
          confidence: confidence,
          sourceSnippet: sourceSnippet,
        ),
      );
    }
    return items;
  }

  List<MeetingExtractionProjectCandidate>? _parseProjectCandidates(
    Object? raw,
    String path,
    List<MeetingExtractionValidationIssue> issues,
  ) {
    final list = _requireList(raw, path, issues);
    if (list == null) {
      return null;
    }

    const allowedMatchTypes = <String>{'existing', 'new', 'existing_or_new'};
    final items = <MeetingExtractionProjectCandidate>[];
    for (var index = 0; index < list.length; index += 1) {
      final itemPath = '$path[$index]';
      final object = _requireObject(list[index], itemPath, issues);
      if (object == null) {
        continue;
      }

      final projectName = _requireString(object['project_name'], '$itemPath.project_name', issues);
      final matchType = _requireString(object['match_type'], '$itemPath.match_type', issues);
      final confidence = _requireConfidence(object['confidence'], '$itemPath.confidence', issues);
      final sourceSnippet = _requireString(
        object['source_snippet'],
        '$itemPath.source_snippet',
        issues,
      );

      if (matchType != null && !allowedMatchTypes.contains(matchType)) {
        issues.add(
          MeetingExtractionValidationIssue(
            path: '$itemPath.match_type',
            message: 'Expected one of: ${allowedMatchTypes.join(', ')}.',
          ),
        );
      }

      if (projectName == null || matchType == null || confidence == null || sourceSnippet == null) {
        continue;
      }

      items.add(
        MeetingExtractionProjectCandidate(
          projectName: projectName,
          matchType: matchType,
          confidence: confidence,
          sourceSnippet: sourceSnippet,
          clientOem: _optionalString(object['client_oem'], '$itemPath.client_oem', issues),
          siteLocation: _optionalString(object['site_location'], '$itemPath.site_location', issues),
          siteContactName: _optionalString(
            object['site_contact_name'],
            '$itemPath.site_contact_name',
            issues,
          ),
          siteContactPhone: _optionalString(
            object['site_contact_phone'],
            '$itemPath.site_contact_phone',
            issues,
          ),
          coordinatorName: _optionalString(
            object['coordinator_name'],
            '$itemPath.coordinator_name',
            issues,
          ),
          projectManagerName: _optionalString(
            object['project_manager_name'],
            '$itemPath.project_manager_name',
            issues,
          ),
        ),
      );
    }

    return items;
  }

  List<MeetingExtractionPersonMention>? _parsePeopleMentions(
    Object? raw,
    String path,
    List<MeetingExtractionValidationIssue> issues,
  ) {
    final list = _requireList(raw, path, issues);
    if (list == null) {
      return null;
    }

    final items = <MeetingExtractionPersonMention>[];
    for (var index = 0; index < list.length; index += 1) {
      final itemPath = '$path[$index]';
      final object = _requireObject(list[index], itemPath, issues);
      if (object == null) {
        continue;
      }
      final name = _requireString(object['name'], '$itemPath.name', issues);
      final confidence = _requireConfidence(object['confidence'], '$itemPath.confidence', issues);
      final sourceSnippet = _requireString(
        object['source_snippet'],
        '$itemPath.source_snippet',
        issues,
      );

      if (name == null || confidence == null || sourceSnippet == null) {
        continue;
      }

      items.add(
        MeetingExtractionPersonMention(
          name: name,
          confidence: confidence,
          sourceSnippet: sourceSnippet,
          phone: _optionalString(object['phone'], '$itemPath.phone', issues),
          roleHint: _optionalString(object['role_hint'], '$itemPath.role_hint', issues),
        ),
      );
    }
    return items;
  }

  List<MeetingExtractionTaskCandidate>? _parseTaskCandidates(
    Object? raw,
    String path,
    List<MeetingExtractionValidationIssue> issues,
  ) {
    final list = _requireList(raw, path, issues);
    if (list == null) {
      return null;
    }

    final items = <MeetingExtractionTaskCandidate>[];
    for (var index = 0; index < list.length; index += 1) {
      final itemPath = '$path[$index]';
      final object = _requireObject(list[index], itemPath, issues);
      if (object == null) {
        continue;
      }

      final id = _requireString(object['candidate_id'], '$itemPath.candidate_id', issues);
      final taskTypeText = _requireString(object['task_type'], '$itemPath.task_type', issues);
      final taskTitle = _requireString(object['task_title'], '$itemPath.task_title', issues);
      final projectName = _requireString(object['project_name'], '$itemPath.project_name', issues);
      final confidence = _requireConfidence(object['confidence'], '$itemPath.confidence', issues);
      final sourceSnippet = _requireString(
        object['source_snippet'],
        '$itemPath.source_snippet',
        issues,
      );
      final ambiguities = _requireStringList(object['ambiguities'], '$itemPath.ambiguities', issues);

      final taskType = taskTypeText == null
          ? null
          : _taskTypeFromContractValue(taskTypeText, '$itemPath.task_type', issues);

      if (id == null ||
          taskType == null ||
          taskTitle == null ||
          projectName == null ||
          confidence == null ||
          sourceSnippet == null ||
          ambiguities == null) {
        continue;
      }

      items.add(
        MeetingExtractionTaskCandidate(
          id: id,
          taskType: taskType,
          taskTitle: taskTitle,
          description: _optionalString(object['description'], '$itemPath.description', issues),
          projectName: projectName,
          workerName: _optionalString(object['worker_name'], '$itemPath.worker_name', issues),
          workerPhone: _optionalString(object['worker_phone'], '$itemPath.worker_phone', issues),
          coordinatorName: _optionalString(
            object['coordinator_name'],
            '$itemPath.coordinator_name',
            issues,
          ),
          projectManagerName: _optionalString(
            object['project_manager_name'],
            '$itemPath.project_manager_name',
            issues,
          ),
          scheduledDateText: _optionalString(
            object['scheduled_date_text'],
            '$itemPath.scheduled_date_text',
            issues,
          ),
          startTimeText: _optionalString(object['start_time_text'], '$itemPath.start_time_text', issues),
          durationText: _optionalString(object['duration_text'], '$itemPath.duration_text', issues),
          locationText: _optionalString(object['location_text'], '$itemPath.location_text', issues),
          statusSuggestion: _optionalString(
            object['status_suggestion'],
            '$itemPath.status_suggestion',
            issues,
          ),
          prioritySuggestion: _optionalString(
            object['priority_suggestion'],
            '$itemPath.priority_suggestion',
            issues,
          ),
          confidence: confidence,
          ambiguities: ambiguities,
          sourceSnippet: sourceSnippet,
        ),
      );
    }
    return items;
  }

  MeetingExtractionConfidence? _parseConfidence(
    Object? raw,
    String path,
    List<MeetingExtractionValidationIssue> issues,
  ) {
    final object = _requireObject(raw, path, issues);
    if (object == null) {
      return null;
    }

    final overall = _requireConfidence(object['overall'], '$path.overall', issues);
    final transcript = _requireConfidence(object['transcript'], '$path.transcript', issues);
    final meetingSummary = _requireConfidence(
      object['meeting_summary'],
      '$path.meeting_summary',
      issues,
    );
    final projectLinking = _requireConfidence(
      object['project_linking'],
      '$path.project_linking',
      issues,
    );
    final taskExtraction = _requireConfidence(
      object['task_extraction'],
      '$path.task_extraction',
      issues,
    );

    if (overall == null ||
        transcript == null ||
        meetingSummary == null ||
        projectLinking == null ||
        taskExtraction == null) {
      return null;
    }

    return MeetingExtractionConfidence(
      overall: overall,
      transcript: transcript,
      meetingSummary: meetingSummary,
      projectLinking: projectLinking,
      taskExtraction: taskExtraction,
    );
  }

  void _validateSpeakerSegments(
    Object? raw,
    String path,
    List<MeetingExtractionValidationIssue> issues,
  ) {
    if (raw == null) {
      return;
    }
    final list = _requireList(raw, path, issues);
    if (list == null) {
      return;
    }

    for (var index = 0; index < list.length; index += 1) {
      final itemPath = '$path[$index]';
      final object = _requireObject(list[index], itemPath, issues);
      if (object == null) {
        continue;
      }
      _requireString(object['speaker_label'], '$itemPath.speaker_label', issues);
      _requireInt(object['start_ms'], '$itemPath.start_ms', issues);
      _requireInt(object['end_ms'], '$itemPath.end_ms', issues);
      _requireString(object['text'], '$itemPath.text', issues);
      _requireConfidence(object['confidence'], '$itemPath.confidence', issues);
    }
  }

  Map<String, Object?>? _requireObject(
    Object? raw,
    String path,
    List<MeetingExtractionValidationIssue> issues,
  ) {
    if (raw is Map<String, Object?>) {
      return raw;
    }
    if (raw is Map) {
      return raw.map(
        (Object? key, Object? value) => MapEntry(key.toString(), value),
      );
    }
    issues.add(
      MeetingExtractionValidationIssue(
        path: path,
        message: 'Expected an object.',
      ),
    );
    return null;
  }

  List<Object?>? _requireList(
    Object? raw,
    String path,
    List<MeetingExtractionValidationIssue> issues,
  ) {
    if (raw is List) {
      return List<Object?>.from(raw);
    }
    issues.add(
      MeetingExtractionValidationIssue(
        path: path,
        message: 'Expected an array.',
      ),
    );
    return null;
  }

  String? _requireString(
    Object? raw,
    String path,
    List<MeetingExtractionValidationIssue> issues,
  ) {
    final value = _optionalString(raw, path, issues);
    if (value == null) {
      issues.add(
        MeetingExtractionValidationIssue(
          path: path,
          message: 'Expected a non-empty string.',
        ),
      );
    }
    return value;
  }

  String? _optionalString(
    Object? raw,
    String path,
    List<MeetingExtractionValidationIssue> issues,
  ) {
    if (raw == null) {
      return null;
    }
    if (raw is! String) {
      issues.add(
        MeetingExtractionValidationIssue(
          path: path,
          message: 'Expected a string.',
        ),
      );
      return null;
    }
    final trimmed = raw.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  List<String>? _requireStringList(
    Object? raw,
    String path,
    List<MeetingExtractionValidationIssue> issues,
  ) {
    final list = _requireList(raw, path, issues);
    if (list == null) {
      return null;
    }

    final values = <String>[];
    for (var index = 0; index < list.length; index += 1) {
      final itemPath = '$path[$index]';
      final value = _requireString(list[index], itemPath, issues);
      if (value != null) {
        values.add(value);
      }
    }
    return values;
  }

  int? _requireInt(
    Object? raw,
    String path,
    List<MeetingExtractionValidationIssue> issues,
  ) {
    final value = _optionalInt(raw, path, issues);
    if (value == null) {
      issues.add(
        MeetingExtractionValidationIssue(
          path: path,
          message: 'Expected an integer.',
        ),
      );
    }
    return value;
  }

  int? _optionalInt(
    Object? raw,
    String path,
    List<MeetingExtractionValidationIssue> issues,
  ) {
    if (raw == null) {
      return null;
    }
    if (raw is int) {
      return raw;
    }
    if (raw is num) {
      return raw.toInt();
    }
    issues.add(
      MeetingExtractionValidationIssue(
        path: path,
        message: 'Expected a numeric value.',
      ),
    );
    return null;
  }

  double? _requireConfidence(
    Object? raw,
    String path,
    List<MeetingExtractionValidationIssue> issues,
  ) {
    if (raw is! num) {
      issues.add(
        MeetingExtractionValidationIssue(
          path: path,
          message: 'Expected a numeric confidence value between 0 and 1.',
        ),
      );
      return null;
    }
    final value = raw.toDouble();
    if (value < 0 || value > 1) {
      issues.add(
        MeetingExtractionValidationIssue(
          path: path,
          message: 'Confidence must be between 0 and 1.',
        ),
      );
      return null;
    }
    return value;
  }

  TaskType? _taskTypeFromContractValue(
    String value,
    String path,
    List<MeetingExtractionValidationIssue> issues,
  ) {
    switch (value.toLowerCase()) {
      case 'site survey':
      case 'site_survey':
        return TaskType.siteSurvey;
      case 'installation':
        return TaskType.installation;
      case 'tuning':
        return TaskType.tuning;
      case 'handover':
        return TaskType.handover;
      case 'maintenance':
        return TaskType.maintenance;
      case 'unknown':
        return TaskType.unknown;
      default:
        issues.add(
          MeetingExtractionValidationIssue(
            path: path,
            message: 'Expected one of: site survey, installation, tuning, handover, maintenance, unknown.',
          ),
        );
        return null;
    }
  }
}