import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/traveler_cubit.dart';
import '../bloc/traveler_state.dart';
import '../../domain/entities/traveler.dart';
import '../../core/injection.dart';
import '../../../../widgets/loading_view.dart';
import '../../../../widgets/error_view.dart';
import '../widgets/traveler_form_bottom_sheet.dart';

/// Page displaying travelers for a trip.
class TravelersPage extends StatelessWidget {
  final String tripId;

  const TravelersPage({
    super.key,
    required this.tripId,
  });

  @override
  Widget build(BuildContext context) {
    // Try to use existing provider from parent, otherwise create new one
    try {
      context.read<TravelerCubit>();
      // Provider exists, use it
      return TravelersPageView(tripId: tripId);
    } catch (_) {
      // No provider exists, create one
      return BlocProvider(
        create: (_) {
          final cubit = createTravelerCubit();
          cubit.loadTravelers(tripId);
          return cubit;
        },
        child: TravelersPageView(tripId: tripId),
      );
    }
  }
}

class TravelersPageView extends StatelessWidget {
  final String tripId;

  const TravelersPageView({
    super.key,
    required this.tripId,
  });

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TravelerCubit>();

    return BlocListener<TravelerCubit, TravelerState>(
      listener: (context, state) {
        if (state is TravelersError) {
          // Show snackbar for validation errors
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Theme.of(context).colorScheme.error,
              action: SnackBarAction(
                label: 'Dismiss',
                textColor: Theme.of(context).colorScheme.onError,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
            ),
          );
        }
      },
      child: BlocBuilder<TravelerCubit, TravelerState>(
        builder: (context, state) {
        if (state is TravelersLoading) {
          return const LoadingView();
        }

        if (state is TravelersLoaded) {
          final travelers = state.travelers;

          if (travelers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No travelers yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _addTraveler(context, isMainTraveler: true),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Yourself'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: travelers.length,
            itemBuilder: (context, index) {
              final traveler = travelers[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: traveler.isMainTraveler
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.secondary,
                    child: Icon(
                      traveler.isMainTraveler ? Icons.person : Icons.people,
                      color: traveler.isMainTraveler
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSecondary,
                    ),
                  ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            traveler.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                          ),
                        ),
                      if (traveler.isMainTraveler)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Self',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                          ),
                        ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // if (traveler.relationship != null && !traveler.isMainTraveler)
                      //   Text(
                      //     'Relationship: ${traveler.relationship}',
                      //     style: Theme.of(context).textTheme.bodySmall,
                      //   ),
                      if (traveler.email != null)
                        Text(
                          traveler.email!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      if (traveler.phone != null)
                        Text(
                          traveler.phone!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      if (traveler.notes != null && traveler.notes!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            traveler.notes!,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editTraveler(context, traveler);
                      } else if (value == 'delete') {
                        _deleteTraveler(context, traveler);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.red),
                            const SizedBox(width: 8),
                            Text(
                              'Delete',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }

        if (state is TravelersError) {
          return ErrorView(
            message: state.message,
            onRetry: () => cubit.loadTravelers(tripId),
          );
        }

        return const SizedBox.shrink();
      },
      ),
    );
  }

  void _addTraveler(BuildContext context, {bool isMainTraveler = false}) {
    // Check if main traveler already exists
    final cubit = context.read<TravelerCubit>();
    final state = cubit.state;
    bool hasMainTraveler = false;
    if (state is TravelersLoaded) {
      hasMainTraveler = state.travelers.any((t) => t.isMainTraveler);
    }

    TravelerFormBottomSheet.show(
      context,
      tripId: tripId,
      title: isMainTraveler ? 'Add Yourself' : 'Add Traveler',
      initialIsMainTraveler: isMainTraveler,
      initialRelationship: isMainTraveler ? 'Self' : null,
      hasMainTraveler: hasMainTraveler,
      onSubmit: (name, relationship, email, phone, notes, isMain) async {
        await cubit.createTraveler(
          tripId: tripId,
          name: name,
          relationship: relationship,
          email: email,
          phone: phone,
          notes: notes,
          isMainTraveler: isMain,
        );
      },
    );
  }

  void _editTraveler(BuildContext context, Traveler traveler) {
    // Check if main traveler already exists (excluding the current traveler being edited)
    final cubit = context.read<TravelerCubit>();
    final state = cubit.state;
    bool hasMainTraveler = false;
    if (state is TravelersLoaded) {
      hasMainTraveler = state.travelers.any((t) => t.isMainTraveler && t.id != traveler.id);
    }

    TravelerFormBottomSheet.show(
      context,
      tripId: tripId,
      travelerId: traveler.id,
      title: 'Edit Traveler',
      initialName: traveler.name,
      initialRelationship: traveler.relationship,
      initialEmail: traveler.email,
      initialPhone: traveler.phone,
      initialNotes: traveler.notes,
      initialIsMainTraveler: traveler.isMainTraveler,
      hasMainTraveler: hasMainTraveler,
      onSubmit: (name, relationship, email, phone, notes, isMain) async {
        final updated = Traveler(
          id: traveler.id,
          tripId: traveler.tripId,
          name: name,
          relationship: relationship,
          email: email,
          phone: phone,
          notes: notes,
          isMainTraveler: isMain,
          createdAt: traveler.createdAt,
          updatedAt: DateTime.now(),
        );
        await cubit.updateTraveler(updated);
      },
      onDelete: () => _deleteTraveler(context, traveler),
    );
  }

  Future<void> _deleteTraveler(BuildContext context, Traveler traveler) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Traveler'),
        content: Text('Are you sure you want to delete "${traveler.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final cubit = context.read<TravelerCubit>();
      await cubit.deleteTraveler(traveler.id, tripId);
    }
  }
}

