import '../../../domain/entities/meeting_entity.dart';
import '../../../domain/entities/raw_capture_entity.dart';

class MeetingRecordingSession {
  const MeetingRecordingSession({
    required this.meeting,
    required this.rawCapture,
    required this.audioRelativePath,
    required this.isPaused,
    required this.startedAt,
    this.stoppedAt,
  });

  final MeetingEntity meeting;
  final RawCaptureEntity rawCapture;
  final String audioRelativePath;
  final bool isPaused;
  final DateTime startedAt;
  final DateTime? stoppedAt;
}