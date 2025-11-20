import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../presentation/bloc/itinerary_cubit.dart';
import '../../presentation/bloc/itinerary_state.dart';
import '../../presentation/bloc/journal_cubit.dart';
import '../../presentation/bloc/journal_state.dart';
import '../../domain/entities/itinerary_item.dart';
import '../../core/injection.dart';
import '../../../../widgets/primary_app_bar.dart';
import '../../../../widgets/loading_view.dart';
import '../../../../widgets/error_view.dart';
import 'timeline_service.dart';
import 'timeline_item_widget.dart';

/// Page displaying combined itinerary and journal timeline.
class TimelineViewPage extends StatelessWidget {
  final String tripId;

  const TimelineViewPage({
    super.key,
    required this.tripId,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) {
            final cubit = createItineraryCubit();
            cubit.loadItinerary(tripId);
            return cubit;
          },
        ),
        BlocProvider(
          create: (_) {
            final cubit = createJournalCubit();
            cubit.loadEntries(tripId);
            return cubit;
          },
        ),
      ],
      child: Scaffold(
        appBar: PrimaryAppBar(
          title: 'Timeline',
        ),
        body: BlocBuilder<ItineraryCubit, ItineraryState>(
          builder: (context, itineraryState) {
            return BlocBuilder<JournalCubit, JournalState>(
              builder: (context, journalState) {
                if (itineraryState is ItineraryLoading ||
                    journalState is JournalLoading) {
                  return const LoadingView();
                }

                if (itineraryState is ItineraryError) {
                  return ErrorView(
                    message: itineraryState.message,
                    onRetry: () {
                      context.read<ItineraryCubit>().loadItinerary(tripId);
                    },
                  );
                }

                if (journalState is JournalError) {
                  return ErrorView(
                    message: journalState.message,
                    onRetry: () {
                      context.read<JournalCubit>().loadEntries(tripId);
                    },
                  );
                }

                if (itineraryState is ItineraryLoaded &&
                    journalState is JournalLoaded) {
                  // Combine all items and entries
                  final allItems = <ItineraryItem>[];
                  for (final items in itineraryState.itemsByDay.values) {
                    allItems.addAll(items);
                  }

                  final timelineItems = TimelineService.combineAndSort(
                    items: allItems,
                    entries: journalState.entries,
                  );

                  if (timelineItems.isEmpty) {
                    return Center(
                      child: Text(
                        'No timeline items yet',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: timelineItems.length,
                    itemBuilder: (context, index) {
                      final item = timelineItems[index];
                      return TimelineItemWidget(item: item);
                    },
                  );
                }

                return const SizedBox.shrink();
              },
            );
          },
        ),
      ),
    );
  }
}

