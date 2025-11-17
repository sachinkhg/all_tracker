import '../../domain/usecases/voice_note/process_voice_note.dart';

/// Service for processing transcribed text to extract structured information
///
/// Delegates to ProcessVoiceNote use case
class TextProcessingService {
  final ProcessVoiceNote _processVoiceNote = ProcessVoiceNote();

  /// Extract name and description from transcribed text
  ProcessVoiceNoteResult extractNameAndDescription(String transcribedText) {
    return _processVoiceNote.execute(transcribedText);
  }
}

