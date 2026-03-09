import '../../../domain/enums/task_type.dart';

class MeetingExtractionPayload {
  const MeetingExtractionPayload({
    required this.schemaVersion,
    required this.requestId,
    required this.provider,
    required this.transcription,
    required this.meeting,
    required this.projectCandidates,
    required this.peopleMentions,
    required this.taskCandidates,
    required this.confidence,
    required this.warnings,
  });

  final String schemaVersion;
  final String requestId;
  final MeetingExtractionProvider provider;
  final MeetingExtractionTranscription transcription;
  final MeetingExtractionMeeting meeting;
  final List<MeetingExtractionProjectCandidate> projectCandidates;
  final List<MeetingExtractionPersonMention> peopleMentions;
  final List<MeetingExtractionTaskCandidate> taskCandidates;
  final MeetingExtractionConfidence confidence;
  final List<String> warnings;
}

class MeetingExtractionProvider {
  const MeetingExtractionProvider({
    required this.name,
    required this.model,
  });

  final String name;
  final String model;
}

class MeetingExtractionTranscription {
  const MeetingExtractionTranscription({
    required this.languageMode,
    required this.detectedLanguages,
    required this.rawTranscript,
    required this.cleanedTranscript,
  });

  final String? languageMode;
  final List<String> detectedLanguages;
  final String? rawTranscript;
  final String? cleanedTranscript;
}

class MeetingExtractionMeeting {
  const MeetingExtractionMeeting({
    required this.title,
    required this.meetingDateTimeText,
    required this.meetingLocationText,
    required this.summary,
    required this.minutesItems,
    required this.decisionItems,
    required this.openQuestions,
  });

  final String title;
  final String? meetingDateTimeText;
  final String? meetingLocationText;
  final String summary;
  final List<MeetingExtractionEvidenceItem> minutesItems;
  final List<MeetingExtractionEvidenceItem> decisionItems;
  final List<MeetingExtractionOpenQuestion> openQuestions;
}

class MeetingExtractionEvidenceItem {
  const MeetingExtractionEvidenceItem({
    required this.text,
    required this.confidence,
    required this.sourceSnippet,
    this.sequence,
  });

  final int? sequence;
  final String text;
  final double confidence;
  final String sourceSnippet;
}

class MeetingExtractionOpenQuestion {
  const MeetingExtractionOpenQuestion({
    required this.text,
    required this.confidence,
    required this.sourceSnippet,
  });

  final String text;
  final double confidence;
  final String sourceSnippet;
}

class MeetingExtractionProjectCandidate {
  const MeetingExtractionProjectCandidate({
    required this.projectName,
    required this.matchType,
    required this.confidence,
    required this.sourceSnippet,
    this.clientOem,
    this.siteLocation,
    this.siteContactName,
    this.siteContactPhone,
    this.coordinatorName,
    this.projectManagerName,
  });

  final String projectName;
  final String matchType;
  final double confidence;
  final String sourceSnippet;
  final String? clientOem;
  final String? siteLocation;
  final String? siteContactName;
  final String? siteContactPhone;
  final String? coordinatorName;
  final String? projectManagerName;
}

class MeetingExtractionPersonMention {
  const MeetingExtractionPersonMention({
    required this.name,
    required this.confidence,
    required this.sourceSnippet,
    this.phone,
    this.roleHint,
  });

  final String name;
  final String? phone;
  final String? roleHint;
  final double confidence;
  final String sourceSnippet;
}

class MeetingExtractionTaskCandidate {
  const MeetingExtractionTaskCandidate({
    required this.id,
    required this.taskType,
    required this.taskTitle,
    required this.projectName,
    required this.confidence,
    required this.sourceSnippet,
    required this.ambiguities,
    this.description,
    this.workerName,
    this.workerPhone,
    this.coordinatorName,
    this.projectManagerName,
    this.scheduledDateText,
    this.startTimeText,
    this.durationText,
    this.locationText,
    this.statusSuggestion,
    this.prioritySuggestion,
  });

  final String id;
  final TaskType taskType;
  final String taskTitle;
  final String? description;
  final String projectName;
  final String? workerName;
  final String? workerPhone;
  final String? coordinatorName;
  final String? projectManagerName;
  final String? scheduledDateText;
  final String? startTimeText;
  final String? durationText;
  final String? locationText;
  final String? statusSuggestion;
  final String? prioritySuggestion;
  final double confidence;
  final List<String> ambiguities;
  final String sourceSnippet;
}

class MeetingExtractionConfidence {
  const MeetingExtractionConfidence({
    required this.overall,
    required this.transcript,
    required this.meetingSummary,
    required this.projectLinking,
    required this.taskExtraction,
  });

  final double overall;
  final double transcript;
  final double meetingSummary;
  final double projectLinking;
  final double taskExtraction;
}