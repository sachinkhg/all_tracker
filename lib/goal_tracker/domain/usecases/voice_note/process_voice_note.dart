/// ProcessVoiceNote use case
///
/// Extracts name and description from transcribed voice note text using simple heuristics.
/// Since we're using on-device processing, this uses pattern matching rather than external AI.
class ProcessVoiceNote {
  /// Process transcribed text to extract name and description
  ///
  /// Strategy:
  /// - Name: First sentence (up to first period/question mark/exclamation) or first 5-10 words
  /// - Description: Remaining text after name separator, or empty if transcription is short
  /// - Fallback: If only one sentence, use first 3-5 words as name, rest as description
  ProcessVoiceNoteResult execute(String transcribedText) {
    final trimmed = transcribedText.trim();
    
    if (trimmed.isEmpty) {
      return ProcessVoiceNoteResult(name: '', description: '');
    }
    
    // Find first sentence ending (., ?, !)
    final sentenceEndRegex = RegExp(r'[.!?]\s+');
    final firstSentenceMatch = sentenceEndRegex.firstMatch(trimmed);
    
    String name;
    String description;
    
    if (firstSentenceMatch != null) {
      // Split at first sentence boundary
      final matchEnd = firstSentenceMatch.end;
      name = trimmed.substring(0, matchEnd - 1).trim(); // Remove the punctuation
      description = trimmed.substring(matchEnd).trim();
    } else {
      // No sentence boundary found - use word count heuristics
      final words = trimmed.split(RegExp(r'\s+'));
      
      if (words.length <= 5) {
        // Very short: use entire text as name
        name = trimmed;
        description = '';
      } else if (words.length <= 10) {
        // Medium: first 3-5 words as name, rest as description
        final nameWords = words.take(5).join(' ');
        name = nameWords;
        description = words.skip(5).join(' ').trim();
      } else {
        // Long: first 8-10 words as name, rest as description
        final nameWords = words.take(10).join(' ');
        name = nameWords;
        description = words.skip(10).join(' ').trim();
      }
    }
    
    // Clean up: remove leading/trailing quotes from name if present
    if (name.startsWith('"') || name.startsWith("'")) {
      name = name.substring(1);
    }
    if (name.endsWith('"') || name.endsWith("'")) {
      name = name.substring(0, name.length - 1);
    }
    name = name.trim();
    
    return ProcessVoiceNoteResult(
      name: name,
      description: description,
    );
  }
}

/// Result of processing a voice note
class ProcessVoiceNoteResult {
  final String name;
  final String description;

  ProcessVoiceNoteResult({
    required this.name,
    required this.description,
  });
}

