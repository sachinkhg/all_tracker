import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Service wrapper for speech_to_text package
///
/// Handles initialization and provides transcription functionality
class SpeechToTextService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;
  String? _lastError;

  /// Initialize speech recognition
  ///
  /// Returns true if initialization was successful
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    _lastError = null;
    
    final available = await _speech.initialize(
      onError: (error) {
        final errorMsg = error.errorMsg.isNotEmpty ? error.errorMsg : error.toString();
        
        // "error_no_match" is a non-fatal error - it just means no speech was detected yet
        // This is normal when starting recording before speaking
        if (errorMsg.contains('no_match') || errorMsg == 'error_no_match') {
          print('Speech recognition: No match detected yet (this is normal)');
          return; // Don't treat this as a fatal error
        }
        
        // Only store fatal errors
        _lastError = errorMsg;
        print('Speech recognition error: $_lastError');
      },
      onStatus: (status) {
        print('Speech recognition status: $status');
      },
    );
    
    _isInitialized = available;
    if (!available) {
      _lastError = _lastError ?? 'Speech recognition is not available';
    }
    return available;
  }

  /// Get the last error message
  String? get lastError => _lastError;

  /// Check if speech recognition is available
  bool get isAvailable => _isInitialized && _speech.isAvailable;

  /// Start listening for speech
  ///
  /// [onResult] callback receives transcribed text
  /// [onStatus] callback receives status updates
  Future<bool> startListening({
    required void Function(String text) onResult,
    void Function(String status)? onStatus,
  }) async {
    try {
      if (!_isInitialized) {
        // Re-initialize with status callback if provided
        _lastError = null;
        final available = await _speech.initialize(
          onError: (error) {
            final errorMsg = error.errorMsg.isNotEmpty ? error.errorMsg : error.toString();
            
            // "error_no_match" is a non-fatal error - it just means no speech was detected yet
            // This is normal when starting recording before speaking
            if (errorMsg.contains('no_match') || errorMsg == 'error_no_match') {
              print('Speech recognition: No match detected yet (this is normal)');
              return; // Don't treat this as a fatal error
            }
            
            // Only store fatal errors
            _lastError = errorMsg;
            print('Speech recognition error: $_lastError');
          },
          onStatus: (status) {
            print('Speech recognition status: $status');
            try {
              onStatus?.call(status);
            } catch (e) {
              print('Error in onStatus callback: $e');
            }
          },
        );
        
        if (!available) {
          _lastError = _lastError ?? 'Speech recognition is not available';
          return false;
        }
        _isInitialized = true;
      }

      if (!_speech.isAvailable) {
        _lastError = 'Speech recognition is not available on this device';
        return false;
      }

      // The listen() method returns bool synchronously
      // Note: We use cancelOnError: false so that "error_no_match" doesn't stop listening
      // The error callback (set in initialize) will filter out non-fatal errors
      final listenResult = _speech.listen(
        onResult: (result) {
          try {
            // Send both partial and final results for live transcription
            final words = result.recognizedWords;
            if (words.isNotEmpty) {
              onResult(words);
            }
          } catch (e) {
            print('Error in onResult callback: $e');
          }
        },
        listenMode: stt.ListenMode.confirmation,
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        onSoundLevelChange: null,
        // Set cancelOnError to false - we'll handle errors in the error callback
        // and only cancel on fatal errors (not "error_no_match")
        cancelOnError: false,
        listenFor: const Duration(minutes: 5),
      );
      
      // The listen() method returns Future<dynamic>, await it and cast to bool
      final listenStarted = await listenResult;
      
      // Give the system a moment to actually start listening
      // Sometimes the method returns true but listening hasn't started yet
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Check the actual listening state rather than just the return value
      // This is more reliable as it reflects the real state
      final actuallyListening = _speech.isListening;
      
      if (listenStarted && actuallyListening) {
        return true;
      }
      
      // If listen() returned false but we're actually listening, return true anyway
      if (actuallyListening) {
        print('Listen() returned false but isListening is true - continuing anyway');
        return true;
      }
      
      // Only return false if both indicate failure
      return false;
    } catch (e, stackTrace) {
      _lastError = 'Error starting speech recognition: $e';
      print('Exception in startListening: $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Stop listening for speech
  Future<void> stopListening() async {
    if (_isInitialized && _speech.isListening) {
      await _speech.stop();
    }
  }

  /// Cancel listening
  Future<void> cancel() async {
    if (_isInitialized && _speech.isListening) {
      await _speech.cancel();
    }
  }

  /// Check if currently listening
  bool get isListening => _speech.isListening;

  /// Dispose resources
  void dispose() {
    _speech.cancel();
  }
}

