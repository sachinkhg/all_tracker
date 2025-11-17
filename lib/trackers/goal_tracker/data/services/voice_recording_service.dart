import 'package:permission_handler/permission_handler.dart';
import 'speech_to_text_service.dart';
import 'text_processing_service.dart';
import '../../domain/usecases/voice_note/process_voice_note.dart';

/// Service for managing voice recording lifecycle
///
/// Handles permissions, recording start/stop, and transcription
class VoiceRecordingService {
  final SpeechToTextService _speechToTextService;
  final TextProcessingService _textProcessingService;
  
  String? _currentTranscription;
  bool _isRecording = false;
  String? _lastError;

  VoiceRecordingService({
    required SpeechToTextService speechToTextService,
    required TextProcessingService textProcessingService,
  })  : _speechToTextService = speechToTextService,
        _textProcessingService = textProcessingService;

  /// Check and request microphone permission
  Future<bool> requestPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// Check if microphone permission is granted
  Future<bool> hasPermission() async {
    final status = await Permission.microphone.status;
    return status.isGranted;
  }

  /// Initialize speech recognition
  Future<bool> initialize() async {
    // Note: speech_to_text package handles permissions internally
    // It will automatically request microphone and speech recognition permissions if needed
    // We let it handle all permission requests to avoid conflicts
    
    final initialized = await _speechToTextService.initialize();
    if (!initialized) {
      final error = _speechToTextService.lastError ?? '';
      
      // Don't fail initialization if the only error is "error_no_match"
      // This is a non-fatal error that just means no speech detected yet
      if (error.contains('no_match') || error == 'error_no_match') {
        print('Ignoring non-fatal "error_no_match" during initialization - checking if available anyway');
        // The initialization may have actually succeeded, just with a warning
        // Let's check if speech is available despite the error
        if (_speechToTextService.isAvailable) {
          return true; // Continue - it's available
        }
      }
      
      // Provide helpful error message for real errors
      _lastError = error.isNotEmpty ? error : 
          'Speech recognition is not available. Please ensure microphone and speech recognition permissions are granted.';
      print('Speech recognition initialization failed: $_lastError');
    }
    return initialized;
  }

  /// Start recording
  ///
  /// [onTranscriptionUpdate] called whenever transcribed text updates
  /// [onStatusChange] called when recording status changes
  Future<bool> startRecording({
    required void Function(String text) onTranscriptionUpdate,
    void Function(String status)? onStatusChange,
  }) async {
    if (_isRecording) {
      _lastError = 'Recording is already in progress';
      return false;
    }

    _lastError = null;
    
    final initialized = await initialize();
    if (!initialized) {
      _lastError = _speechToTextService.lastError ?? 
          'Failed to initialize speech recognition. Please check microphone permissions.';
      print('Recording initialization failed: $_lastError');
      return false;
    }

    if (!_speechToTextService.isAvailable) {
      _lastError = 'Speech recognition is not available on this device';
      print('Speech recognition not available');
      return false;
    }

    _currentTranscription = '';
    _isRecording = true;

    try {
      final started = await _speechToTextService.startListening(
        onResult: (text) {
          try {
            if (text.isNotEmpty) {
              _currentTranscription = text;
              onTranscriptionUpdate(text);
            }
          } catch (e) {
            print('Error processing transcription update: $e');
          }
        },
        onStatus: (status) {
          try {
            onStatusChange?.call(status);
            if (status == 'done' || status == 'notListening') {
              _isRecording = false;
            }
          } catch (e) {
            print('Error processing status change: $e');
          }
        },
      );

      // Wait a bit more to see if listening actually starts
      // Sometimes there's a delay between calling listen() and actually starting
      if (!started) {
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Check again if it started listening
        if (_speechToTextService.isListening) {
          print('Recording started after initial delay');
          return true;
        }
        
        // Still not listening - check for errors
        final error = _speechToTextService.lastError ?? '';
        
        // Don't show error if it's just "error_no_match" - that's normal
        if (error.contains('no_match') || error == 'error_no_match') {
          print('Got "error_no_match" but continuing - this is normal');
          // Check if service is available despite the error
          if (_speechToTextService.isAvailable) {
            // Service is available, might start listening soon
            // Don't return false yet - let the status callback handle it
            print('Service is available, waiting for listening to start...');
            // Give it one more moment
            await Future.delayed(const Duration(milliseconds: 500));
            if (_speechToTextService.isListening) {
              return true;
            }
          }
        }
        
        // If we get here, listening really didn't start
        _isRecording = false;
        _lastError = error.isNotEmpty && !error.contains('no_match') 
            ? error 
            : 'Failed to start listening. Please check microphone permissions.';
        print('Failed to start listening: $_lastError');
      }

      return started;
    } catch (e, stackTrace) {
      _isRecording = false;
      _lastError = 'Error starting recording: $e';
      print('Exception starting recording: $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Get the last error message
  String? get lastError => _lastError;

  /// Stop recording and return final transcription
  Future<String?> stopRecording() async {
    if (!_isRecording) return _currentTranscription;

    await _speechToTextService.stopListening();
    _isRecording = false;

    // Wait a bit for final transcription
    await Future.delayed(const Duration(milliseconds: 500));

    return _currentTranscription;
  }

  /// Cancel recording without getting transcription
  Future<void> cancelRecording() async {
    if (!_isRecording) return;

    await _speechToTextService.cancel();
    _isRecording = false;
    _currentTranscription = null;
  }

  /// Get current transcription
  String? get currentTranscription => _currentTranscription;

  /// Check if currently recording
  bool get isRecording => _isRecording;

  /// Process current transcription to extract name and description
  ProcessVoiceNoteResult? processCurrentTranscription() {
    if (_currentTranscription == null || _currentTranscription!.isEmpty) {
      return null;
    }
    return _textProcessingService.extractNameAndDescription(_currentTranscription!);
  }

  /// Dispose resources
  void dispose() {
    _speechToTextService.dispose();
  }
}

