import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/voice_note_cubit.dart';
import '../bloc/voice_note_state.dart';
import '../../domain/usecases/voice_note/voice_entity_type.dart';
import '../../domain/usecases/voice_note/process_voice_note.dart';
import '../../../../widgets/context_dropdown_bottom_sheet.dart';

/// Bottom sheet for recording voice notes and processing them
///
/// Displays entity type selector, recording controls, transcription preview,
/// and extracted name/description for user review before creating entity.
class VoiceNoteRecorderBottomSheet extends StatelessWidget {
  final VoiceNoteCubit cubit;
  final Future<void> Function(String name, String description)? onProcessed;

  const VoiceNoteRecorderBottomSheet({
    super.key,
    required this.cubit,
    this.onProcessed,
  });

  static Future<void> show(
    BuildContext context, {
    required VoiceNoteCubit cubit,
    Future<void> Function(String name, String description)? onProcessed,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return BlocProvider.value(
          value: cubit,
          child: VoiceNoteRecorderBottomSheet(
            cubit: cubit,
            onProcessed: onProcessed,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return BlocListener<VoiceNoteCubit, VoiceNoteState>(
      listener: (context, state) {
        if (state is VoiceNoteError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: BlocBuilder<VoiceNoteCubit, VoiceNoteState>(
            builder: (context, state) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          'Record Voice Note',
                          style: textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: cs.onSurfaceVariant),
                        tooltip: 'Close',
                        onPressed: () {
                          if (state is VoiceNoteRecording) {
                            cubit.cancelRecording();
                          }
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Entity Type Selector
                  _EntityTypeSelector(
                    selectedType: state.selectedEntityType,
                    onTypeSelected: (type) {
                      cubit.setEntityType(type);
                    },
                  ),
                  const SizedBox(height: 24),

                  // Recording UI based on state
                  if (state is VoiceNoteInitial) ...[
                    _InitialView(
                      hasEntityType: state.selectedEntityType != null,
                      onStartRecording: () => cubit.startRecording(),
                    ),
                  ] else if (state is VoiceNoteRecording) ...[
                    _RecordingView(
                      transcription: state.currentTranscription,
                      onStop: () => cubit.stopRecording(),
                      onCancel: () {
                        cubit.cancelRecording();
                        Navigator.of(context).pop();
                      },
                    ),
                  ] else if (state is VoiceNoteProcessing) ...[
                    _ProcessingView(transcription: state.transcribedText),
                  ] else if (state is VoiceNoteProcessed) ...[
                    _ProcessedView(
                      result: state.result,
                      fullTranscription: state.fullTranscription,
                      onRetry: () => cubit.reset(),
                      onCreate: (name, description) async {
                        // Close the voice note recorder first
                        Navigator.of(context).pop();
                        
                        // Wait a frame for the bottom sheet to close
                        await Future.delayed(const Duration(milliseconds: 100));
                        
                        // Then call the callback to open the form
                        onProcessed?.call(name, description);
                      },
                    ),
                  ] else if (state is VoiceNoteError) ...[
                    _ErrorView(
                      message: state.message,
                      onRetry: () => cubit.reset(),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Entity type selector widget
class _EntityTypeSelector extends StatelessWidget {
  final VoiceEntityType? selectedType;
  final void Function(VoiceEntityType) onTypeSelected;

  const _EntityTypeSelector({
    required this.selectedType,
    required this.onTypeSelected,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final options = [
      'Goal',
      'Milestone',
      'Task',
      'Habit',
    ];

    return InkWell(
      onTap: () async {
        final selected = await ContextDropdownBottomSheet.showContextPicker(
          context,
          title: 'Select Entity Type',
          options: options,
          initialContext: selectedType != null
              ? options[selectedType!.index]
              : null,
        );

        if (selected != null && selected.isNotEmpty) {
          final index = options.indexOf(selected);
          if (index >= 0 && index < VoiceEntityType.values.length) {
            onTypeSelected(VoiceEntityType.values[index]);
          }
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Entity Type *',
          border: const OutlineInputBorder(),
          errorText: selectedType == null ? 'Please select an entity type' : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                selectedType != null
                    ? options[selectedType!.index]
                    : 'Select Entity Type',
                style: TextStyle(
                  color: selectedType == null ? cs.onSurfaceVariant : null,
                ),
              ),
            ),
            Icon(Icons.arrow_drop_down, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

/// Initial view - shows start recording button
class _InitialView extends StatelessWidget {
  final bool hasEntityType;
  final VoidCallback onStartRecording;

  const _InitialView({
    required this.hasEntityType,
    required this.onStartRecording,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.mic, size: 64, color: Colors.grey),
        const SizedBox(height: 16),
        Text(
          'Tap the button below to start recording',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: hasEntityType ? onStartRecording : null,
          icon: const Icon(Icons.mic),
          label: const Text('Start Recording'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    );
  }
}

/// Recording view - shows recording animation and live transcription
class _RecordingView extends StatefulWidget {
  final String transcription;
  final VoidCallback onStop;
  final VoidCallback onCancel;

  const _RecordingView({
    required this.transcription,
    required this.onStop,
    required this.onCancel,
  });

  @override
  State<_RecordingView> createState() => _RecordingViewState();
}

class _RecordingViewState extends State<_RecordingView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.error.withOpacity(0.2 + (_animationController.value * 0.3)),
              ),
              child: Icon(
                Icons.mic,
                size: 40,
                color: cs.error,
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        Text(
          'Recording...',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: cs.error,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          constraints: const BoxConstraints(maxHeight: 200),
          child: SingleChildScrollView(
            child: Text(
              widget.transcription.isEmpty
                  ? 'Listening...'
                  : widget.transcription,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: widget.onCancel,
              icon: const Icon(Icons.cancel),
              label: const Text('Cancel'),
            ),
            const SizedBox(width: 16),
            FilledButton.icon(
              onPressed: widget.onStop,
              icon: const Icon(Icons.stop),
              label: const Text('Stop Recording'),
              style: FilledButton.styleFrom(
                backgroundColor: cs.error,
                foregroundColor: cs.onError,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Processing view - shows processing indicator
class _ProcessingView extends StatelessWidget {
  final String transcription;

  const _ProcessingView({required this.transcription});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 16),
        Text(
          'Processing...',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          constraints: const BoxConstraints(maxHeight: 200),
          child: SingleChildScrollView(
            child: Text(
              transcription,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      ],
    );
  }
}

/// Processed view - shows extracted name and description
class _ProcessedView extends StatelessWidget {
  final ProcessVoiceNoteResult result;
  final String fullTranscription;
  final VoidCallback onRetry;
  final Future<void> Function(String name, String description) onCreate;

  const _ProcessedView({
    required this.result,
    required this.fullTranscription,
    required this.onRetry,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Review Extracted Information',
          style: textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        // Full transcription
        Text('Full Transcription:', style: textTheme.labelLarge),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          constraints: const BoxConstraints(maxHeight: 100),
          child: SingleChildScrollView(
            child: Text(
              fullTranscription,
              style: textTheme.bodySmall,
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Extracted Name
        Text('Extracted Name:', style: textTheme.labelLarge),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: cs.primary),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            result.name.isEmpty ? '(No name extracted)' : result.name,
            style: textTheme.bodyLarge,
          ),
        ),
        const SizedBox(height: 16),
        // Extracted Description
        Text('Extracted Description:', style: textTheme.labelLarge),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: cs.secondary),
            borderRadius: BorderRadius.circular(8),
          ),
          constraints: const BoxConstraints(maxHeight: 100),
          child: SingleChildScrollView(
            child: Text(
              result.description.isEmpty ? '(No description extracted)' : result.description,
              style: textTheme.bodyMedium,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: () => onCreate(result.name, result.description),
                child: const Text('Create'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Error view - shows error message
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        Icon(Icons.error_outline, size: 64, color: cs.error),
        const SizedBox(height: 16),
        Text(
          'Error',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: cs.error,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: onRetry,
          child: const Text('Try Again'),
        ),
      ],
    );
  }
}

