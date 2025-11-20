import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/journal_cubit.dart';
import '../bloc/journal_state.dart';
import '../../domain/entities/journal_entry.dart';
import '../../core/injection.dart';
import '../../core/app_icons.dart';
import '../../../../widgets/loading_view.dart';
import '../../../../widgets/error_view.dart';
import '../widgets/journal_entry_form_bottom_sheet.dart';

/// Page displaying journal entries for a trip.
class JournalEntryPage extends StatelessWidget {
  final String tripId;

  const JournalEntryPage({
    super.key,
    required this.tripId,
  });

  @override
  Widget build(BuildContext context) {
    // Try to use existing provider from parent, otherwise create new one
    try {
      context.read<JournalCubit>();
      // Provider exists, use it
      return JournalEntryPageView(tripId: tripId);
    } catch (_) {
      // No provider exists, create one
      return BlocProvider(
        create: (_) {
          final cubit = createJournalCubit();
          cubit.loadEntries(tripId);
          return cubit;
        },
        child: JournalEntryPageView(tripId: tripId),
      );
    }
  }
}

class JournalEntryPageView extends StatelessWidget {
  final String tripId;

  const JournalEntryPageView({
    super.key,
    required this.tripId,
  });

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<JournalCubit>();

    return BlocBuilder<JournalCubit, JournalState>(
      builder: (context, state) {
        if (state is JournalLoading) {
          return const LoadingView();
        }

        if (state is JournalLoaded) {
          final entries = state.entries;

          if (entries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    TravelTrackerIcons.journal,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No journal entries yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _addEntry(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Entry'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return _TwitterStyleJournalEntry(
                entry: entry,
                onEdit: () => _editEntry(context, entry),
                onDelete: () async {
                  await cubit.deleteEntry(entry.id, tripId);
                },
              );
            },
          );
        }

        if (state is JournalError) {
          return ErrorView(
            message: state.message,
            onRetry: () => cubit.loadEntries(tripId),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  void _addEntry(BuildContext context) {
    JournalEntryFormBottomSheet.show(
      context,
      tripId: tripId,
      onSubmit: (date, content) async {
        final cubit = context.read<JournalCubit>();
        await cubit.createEntry(
          tripId: tripId,
          date: date,
          content: content,
        );
      },
    );
  }

  void _editEntry(BuildContext context, entry) {
    JournalEntryFormBottomSheet.show(
      context,
      tripId: tripId,
      initialDate: entry.date,
      initialContent: entry.content,
      onSubmit: (date, content) async {
        final cubit = context.read<JournalCubit>();
        final updated = JournalEntry(
          id: entry.id,
          tripId: entry.tripId,
          date: date,
          content: content,
          createdAt: entry.createdAt,
          updatedAt: DateTime.now(),
        );
        await cubit.updateEntry(updated);
      },
    );
  }
}

/// Twitter-style journal entry card widget.
class _TwitterStyleJournalEntry extends StatelessWidget {
  final JournalEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TwitterStyleJournalEntry({
    required this.entry,
    required this.onEdit,
    required this.onDelete,
  });

  String _formatFullDate(DateTime date) {
    return DateFormat('MMM dd, yyyy · h:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: cs.outline.withOpacity(0.2),
            width: 0.5,
          ),
        ),
      ),
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              CircleAvatar(
                radius: 24,
                backgroundColor: cs.primaryContainer,
                child: Icon(
                  Icons.book,
                  color: cs.onPrimaryContainer,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row with date and actions
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _formatFullDate(entry.date),
                            style: textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: Icon(
                            Icons.more_vert,
                            size: 18,
                            color: cs.onSurfaceVariant,
                          ),
                          padding: EdgeInsets.zero,
                          onSelected: (value) {
                            if (value == 'edit') {
                              onEdit();
                            } else if (value == 'delete') {
                              onDelete();
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, size: 18),
                                  const SizedBox(width: 8),
                                  const Text('Edit'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete,
                                    size: 18,
                                    color: cs.error,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Delete',
                                    style: TextStyle(color: cs.error),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Content text
                    Text(
                      entry.content,
                      style: textTheme.bodyLarge?.copyWith(
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

