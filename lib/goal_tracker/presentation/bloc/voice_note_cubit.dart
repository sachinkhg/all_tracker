import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'voice_note_state.dart';
import '../../data/services/voice_recording_service.dart';
import '../../domain/usecases/voice_note/voice_entity_type.dart';

/// Cubit for managing voice note recording and processing state
class VoiceNoteCubit extends Cubit<VoiceNoteState> {
  final VoiceRecordingService _voiceRecordingService;
  VoiceEntityType? _selectedEntityType;

  VoiceNoteCubit({
    required VoiceRecordingService voiceRecordingService,
  })  : _voiceRecordingService = voiceRecordingService,
        super(const VoiceNoteInitial());

  /// Set the selected entity type (Goal/Milestone/Task/Habit)
  void setEntityType(VoiceEntityType entityType) {
    _selectedEntityType = entityType;
    // Emit current state with updated entity type to trigger UI rebuild
    final currentState = state;
    if (currentState is VoiceNoteInitial) {
      emit(VoiceNoteInitial(selectedEntityType: entityType));
    } else if (currentState is VoiceNoteRecording) {
      emit(VoiceNoteRecording(
        currentTranscription: currentState.currentTranscription,
        selectedEntityType: entityType,
      ));
    } else if (currentState is VoiceNoteProcessing) {
      emit(VoiceNoteProcessing(
        transcribedText: currentState.transcribedText,
        selectedEntityType: entityType,
      ));
    } else if (currentState is VoiceNoteProcessed) {
      emit(VoiceNoteProcessed(
        result: currentState.result,
        fullTranscription: currentState.fullTranscription,
        selectedEntityType: entityType,
      ));
    } else if (currentState is VoiceNoteError) {
      emit(VoiceNoteError(
        message: currentState.message,
        selectedEntityType: entityType,
      ));
    }
  }

  /// Get the currently selected entity type
  VoiceEntityType? get selectedEntityType => state.selectedEntityType;

  /// Start recording
  Future<void> startRecording() async {
    if (_selectedEntityType == null) {
      emit(VoiceNoteError(
        message: 'Please select an entity type first',
        selectedEntityType: null,
      ));
      return;
    }

    try {
      final started = await _voiceRecordingService.startRecording(
        onTranscriptionUpdate: (text) {
          try {
            // Ensure we're on the main isolate before emitting
            if (!isClosed) {
              emit(VoiceNoteRecording(
                currentTranscription: text,
                selectedEntityType: _selectedEntityType,
              ));
            }
          } catch (e) {
            print('Error emitting transcription state: $e');
          }
        },
        onStatusChange: (status) {
          try {
            print('Recording status changed: $status');
            
            // When status becomes "listening", we know recording actually started
            // Update state to recording if we're still in initial state
            if (status == 'listening' && state is VoiceNoteInitial) {
              if (!isClosed) {
                emit(VoiceNoteRecording(
                  currentTranscription: '',
                  selectedEntityType: _selectedEntityType,
                ));
              }
            }
            
            if (status == 'done' || status == 'notListening') {
              // Recording stopped, process the transcription
              // Use a microtask to ensure we're on the main isolate
              Future.microtask(() {
                if (!isClosed) {
                  _processTranscription();
                }
              });
            }
          } catch (e) {
            print('Error processing status change: $e');
          }
        },
      );

      // Don't immediately show error - give it a moment to start
      // The service layer already does some waiting, but we'll do one more check
      if (!started) {
        // Wait a bit more to see if recording starts via status callback
        await Future.delayed(const Duration(milliseconds: 800));
        
        // Check if we're actually recording now (state might have changed via status callback)
        final currentState = state;
        if (currentState is VoiceNoteRecording) {
          // Recording actually started, don't show error
          print('Recording started after delay - continuing');
          return;
        }
        
        // Still not recording - show error
        final errorMessage = _voiceRecordingService.lastError ?? 
            'Failed to start recording. Please check microphone permissions.';
        if (!isClosed) {
          emit(VoiceNoteError(
            message: errorMessage,
            selectedEntityType: _selectedEntityType,
          ));
        }
      } else {
        // Started successfully, but wait a moment to see if we get a status update
        // The status callback will update the state to VoiceNoteRecording when listening starts
        await Future.delayed(const Duration(milliseconds: 300));
        
        // If we're still in initial state but started was true, emit recording state
        // The status callback should have already updated it, but just in case
        if (state is VoiceNoteInitial) {
          if (!isClosed) {
            emit(VoiceNoteRecording(
              currentTranscription: '',
              selectedEntityType: _selectedEntityType,
            ));
          }
        }
      }
    } catch (e, stackTrace) {
      print('Exception in startRecording: $e');
      print('Stack trace: $stackTrace');
      if (!isClosed) {
        emit(VoiceNoteError(
          message: 'Error starting recording: $e',
          selectedEntityType: _selectedEntityType,
        ));
      }
    }
  }

  /// Stop recording and process transcription
  Future<void> stopRecording() async {
    try {
      final transcription = await _voiceRecordingService.stopRecording();
      if (transcription == null || transcription.isEmpty) {
        emit(VoiceNoteError(
        message: 'No audio recorded. Please try again.',
        selectedEntityType: _selectedEntityType,
      ));
        return;
      }

      emit(VoiceNoteProcessing(
        transcribedText: transcription,
        selectedEntityType: _selectedEntityType,
      ));
      _processTranscription();
    } catch (e) {
      emit(VoiceNoteError(
        message: 'Error stopping recording: $e',
        selectedEntityType: _selectedEntityType,
      ));
    }
  }

  /// Cancel recording without processing
  Future<void> cancelRecording() async {
    try {
      await _voiceRecordingService.cancelRecording();
      emit(VoiceNoteInitial(selectedEntityType: _selectedEntityType));
    } catch (e) {
      emit(VoiceNoteError(
        message: 'Error canceling recording: $e',
        selectedEntityType: _selectedEntityType,
      ));
    }
  }

  /// Process the current transcription
  void _processTranscription() {
    final result = _voiceRecordingService.processCurrentTranscription();
    if (result == null) {
      emit(VoiceNoteError(
        message: 'Failed to process transcription.',
        selectedEntityType: _selectedEntityType,
      ));
      return;
    }

    final transcription = _voiceRecordingService.currentTranscription ?? '';
    emit(VoiceNoteProcessed(
      result: result,
      fullTranscription: transcription,
      selectedEntityType: _selectedEntityType,
    ));
  }

  /// Reset to initial state
  void reset() {
    _selectedEntityType = null;
    emit(const VoiceNoteInitial(selectedEntityType: null));
  }

  @override
  Future<void> close() {
    _voiceRecordingService.dispose();
    return super.close();
  }
}

