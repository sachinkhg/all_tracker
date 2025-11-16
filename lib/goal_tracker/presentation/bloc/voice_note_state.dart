import 'package:equatable/equatable.dart';
import '../../domain/usecases/voice_note/process_voice_note.dart';
import '../../domain/usecases/voice_note/voice_entity_type.dart';

/// States for voice note recording and processing
abstract class VoiceNoteState extends Equatable {
  final VoiceEntityType? selectedEntityType;
  
  const VoiceNoteState({this.selectedEntityType});

  @override
  List<Object?> get props => [selectedEntityType];
}

/// Initial state - ready to record
class VoiceNoteInitial extends VoiceNoteState {
  const VoiceNoteInitial({super.selectedEntityType});
}

/// Recording state - actively recording audio
class VoiceNoteRecording extends VoiceNoteState {
  final String currentTranscription;

  const VoiceNoteRecording({
    required this.currentTranscription,
    super.selectedEntityType,
  });

  @override
  List<Object?> get props => [currentTranscription, selectedEntityType];
}

/// Processing state - transcribing and extracting information
class VoiceNoteProcessing extends VoiceNoteState {
  final String transcribedText;

  const VoiceNoteProcessing({
    required this.transcribedText,
    super.selectedEntityType,
  });

  @override
  List<Object?> get props => [transcribedText, selectedEntityType];
}

/// Processed state - name and description extracted and ready for review
class VoiceNoteProcessed extends VoiceNoteState {
  final ProcessVoiceNoteResult result;
  final String fullTranscription;

  const VoiceNoteProcessed({
    required this.result,
    required this.fullTranscription,
    super.selectedEntityType,
  });

  @override
  List<Object?> get props => [result, fullTranscription, selectedEntityType];
}

/// Error state - something went wrong
class VoiceNoteError extends VoiceNoteState {
  final String message;

  const VoiceNoteError({
    required this.message,
    super.selectedEntityType,
  });

  @override
  List<Object?> get props => [message, selectedEntityType];
}

