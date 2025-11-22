import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/itinerary_cubit.dart';
import '../bloc/itinerary_state.dart';
import '../../domain/entities/itinerary_day.dart';
import '../../domain/entities/itinerary_item.dart';
import '../../core/injection.dart';
import '../../core/app_icons.dart';
import '../../../../widgets/loading_view.dart';
import '../../../../widgets/error_view.dart';
import '../widgets/itinerary_day_card.dart';
import '../widgets/itinerary_item_form_bottom_sheet.dart';
import '../widgets/itinerary_day_notes_form_bottom_sheet.dart';

/// Page displaying itinerary for a trip (day-wise).
class ItineraryViewPage extends StatelessWidget {
  final String tripId;

  const ItineraryViewPage({
    super.key,
    required this.tripId,
  });

  @override
  Widget build(BuildContext context) {
    // Try to use existing provider from parent, otherwise create new one
    try {
      context.read<ItineraryCubit>();
      // Provider exists, use it
      return ItineraryViewPageView(tripId: tripId);
    } catch (_) {
      // No provider exists, create one
      return BlocProvider(
        create: (_) {
          final cubit = createItineraryCubit();
          cubit.loadItinerary(tripId);
          return cubit;
        },
        child: ItineraryViewPageView(tripId: tripId),
      );
    }
  }
}

class ItineraryViewPageView extends StatelessWidget {
  final String tripId;

  const ItineraryViewPageView({
    super.key,
    required this.tripId,
  });

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ItineraryCubit>();

    return BlocBuilder<ItineraryCubit, ItineraryState>(
      builder: (context, state) {
        if (state is ItineraryLoading) {
          return const LoadingView();
        }

        if (state is ItineraryLoaded) {
          final days = state.days;
          final itemsByDay = state.itemsByDay;

          if (days.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    TravelTrackerIcons.itinerary,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No itinerary days yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Days will be automatically generated based on trip dates',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: days.length,
            itemBuilder: (context, index) {
              final day = days[index];
              final items = itemsByDay[day.id] ?? [];
              return ItineraryDayCard(
                day: day,
                items: items,
                onAddItem: () => _showAddItemSheet(context, day.id),
                onEditDay: () => _editDay(context, day),
                onEditItem: (item) => _editItem(context, item),
                onDeleteItem: (itemId) async {
                  await cubit.deleteItemById(itemId, tripId);
                },
              );
            },
          );
        }

        if (state is ItineraryError) {
          return ErrorView(
            message: state.message,
            onRetry: () => cubit.loadItinerary(tripId),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  void _editDay(BuildContext context, day) async {
    final cubit = context.read<ItineraryCubit>();
    final notes = await ItineraryDayNotesFormBottomSheet.show(
      context,
      initialNotes: day.notes,
    );
    // notes is null if user cancelled, empty string if cleared, or string if saved
    if (notes != null) {
      final updated = ItineraryDay(
        id: day.id,
        tripId: day.tripId,
        date: day.date,
        notes: notes.isEmpty ? null : notes,
        createdAt: day.createdAt,
        updatedAt: DateTime.now(),
      );
      await cubit.updateDayEntry(updated);
    }
  }

  void _showAddItemSheet(BuildContext context, String dayId) {
    ItineraryItemFormBottomSheet.show(
      context,
      dayId: dayId,
      tripId: tripId,
      onSubmit: (type, title, time, location, notes, mapLink) async {
        final cubit = context.read<ItineraryCubit>();
        await cubit.createItemForDay(
          dayId: dayId,
          type: type,
          title: title,
          time: time,
          location: location,
          notes: notes,
          mapLink: mapLink,
          tripId: tripId,
        );
      },
    );
  }

  void _editItem(BuildContext context, item) {
    ItineraryItemFormBottomSheet.show(
      context,
      dayId: item.dayId,
      tripId: tripId,
      initialType: item.type,
      initialTitle: item.title,
      initialTime: item.time,
      initialLocation: item.location,
      initialNotes: item.notes,
      initialMapLink: item.mapLink,
      onSubmit: (type, title, time, location, notes, mapLink) async {
        final cubit = context.read<ItineraryCubit>();
        final updated = ItineraryItem(
          id: item.id,
          dayId: item.dayId,
          type: type,
          title: title,
          time: time,
          location: location,
          notes: notes,
          mapLink: mapLink,
          createdAt: item.createdAt,
          updatedAt: DateTime.now(),
        );
        await cubit.updateItemEntry(updated, tripId);
      },
      onDelete: () async {
        final cubit = context.read<ItineraryCubit>();
        await cubit.deleteItemById(item.id, tripId);
      },
    );
  }
}

