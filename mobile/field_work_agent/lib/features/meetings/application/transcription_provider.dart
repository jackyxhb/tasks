import 'transcription_result.dart';

abstract class TranscriptionProvider {
  Future<TranscriptionResult> transcribe({
    required String audioFilePath,
  });
}