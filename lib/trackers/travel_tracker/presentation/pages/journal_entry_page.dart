import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../bloc/journal_cubit.dart';
import '../bloc/journal_state.dart';
import '../bloc/photo_cubit.dart';
import '../bloc/photo_state.dart';
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
      final cubit = context.read<JournalCubit>();
      // Provider exists, use it and ensure entries are loaded
      return JournalEntryPageView(tripId: tripId, cubit: cubit);
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
  final JournalCubit? cubit;

  const JournalEntryPageView({
    super.key,
    required this.tripId,
    this.cubit,
  });

  @override
  Widget build(BuildContext context) {
    final journalCubit = cubit ?? context.read<JournalCubit>();

    return BlocBuilder<JournalCubit, JournalState>(
      bloc: journalCubit,
      builder: (context, state) {
        if (state is JournalLoading) {
          return const LoadingView();
        }

        if (state is JournalLoaded) {
          final entries = state.entries;
          final isRefreshing = state.isRefreshing;

          return Stack(
            children: [
              if (entries.isEmpty)
                Center(
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
                )
              else
                ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return BlocProvider(
                      create: (_) {
                        final photoCubit = createPhotoCubit();
                        photoCubit.loadPhotos(entry.id);
                        return photoCubit;
                      },
                      child: _TwitterStyleJournalEntry(
                        entry: entry,
                        onEdit: () => _editEntry(context, entry),
                        onDelete: () async {
                          await journalCubit.deleteEntry(entry.id, tripId);
                        },
                      ),
                    );
                  },
                ),
              // Animated loading indicator at the top when refreshing
              if (isRefreshing)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _RefreshingIndicator(),
                ),
            ],
          );
        }


        if (state is JournalError) {
          return ErrorView(
            message: state.message,
            onRetry: () => journalCubit.loadEntries(tripId),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  void _addEntry(BuildContext context) {
    final cubit = context.read<JournalCubit>();
    JournalEntryFormBottomSheet.show(
      context,
      tripId: tripId,
      onSubmit: (date, content) async {
        final createdEntry = await cubit.createEntry(
          tripId: tripId,
          date: date,
          content: content,
        );
        return createdEntry?.id;
      },
    ).then((_) {
      // Explicitly refresh when form closes to ensure latest state
      if (context.mounted) {
        cubit.loadEntries(tripId, isRefreshing: false);
      }
    });
  }

  void _editEntry(BuildContext context, entry) {
    final cubit = context.read<JournalCubit>();
    JournalEntryFormBottomSheet.show(
      context,
      tripId: tripId,
      entryId: entry.id,
      initialDate: entry.date,
      initialContent: entry.content,
      onSubmit: (date, content) async {
        final updated = JournalEntry(
          id: entry.id,
          tripId: entry.tripId,
          date: date,
          content: content,
          createdAt: entry.createdAt,
          updatedAt: DateTime.now(),
        );
        await cubit.updateEntry(updated);
        return entry.id; // Return entry ID for consistency
      },
    ).then((_) {
      // Explicitly refresh when form closes to ensure latest state
      if (context.mounted) {
        cubit.loadEntries(tripId, isRefreshing: false);
      }
    });
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
                    const SizedBox(height: 12),
                    // Photos section
                    BlocBuilder<PhotoCubit, PhotoState>(
                      builder: (context, photoState) {
                        if (photoState is PhotosLoading) {
                          return const SizedBox(
                            height: 100,
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        
                        if (photoState is PhotosLoaded) {
                          final photos = photoState.photos;
                          if (photos.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Photo grid
                              SizedBox(
                                height: 100,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: photos.length,
                                  itemBuilder: (context, index) {
                                    final photo = photos[index];
                                    return Container(
                                      width: 100,
                                      margin: const EdgeInsets.only(right: 8),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: cs.outline.withOpacity(0.2),
                                        ),
                                      ),
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.file(
                                              File(photo.filePath),
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                return Container(
                                                  color: Colors.grey[300],
                                                  child: const Icon(Icons.broken_image),
                                                );
                                              },
                                            ),
                                          ),
                                          Positioned(
                                            top: 4,
                                            right: 4,
                                            child: Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                onTap: () {
                                                  context.read<PhotoCubit>().deletePhotoById(
                                                    photo.id,
                                                    entry.id,
                                                  );
                                                },
                                                borderRadius: BorderRadius.circular(12),
                                                child: Container(
                                                  padding: const EdgeInsets.all(4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.black54,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    Icons.close,
                                                    color: Colors.white,
                                                    size: 16,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          );
                        }
                        
                        return const SizedBox.shrink();
                      },
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

/// Animated loading indicator shown at the top when refreshing journal entries.
class _RefreshingIndicator extends StatefulWidget {
  const _RefreshingIndicator();

  @override
  State<_RefreshingIndicator> createState() => _RefreshingIndicatorState();
}

class _RefreshingIndicatorState extends State<_RefreshingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          height: 3,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                cs.primary.withOpacity(0.3),
                cs.primary,
                cs.primary.withOpacity(0.3),
              ],
              stops: [
                (_animation.value - 0.3).clamp(0.0, 1.0),
                _animation.value,
                (_animation.value + 0.3).clamp(0.0, 1.0),
              ],
            ),
          ),
          child: LinearProgressIndicator(
            backgroundColor: Colors.transparent,
            valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
          ),
        );
      },
    );
  }
}

