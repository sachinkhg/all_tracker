import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/trip_cubit.dart';
import '../bloc/trip_state.dart';
import '../../core/injection.dart';
import '../../core/app_icons.dart';
import '../widgets/trip_list_item.dart';
import '../widgets/trip_form_bottom_sheet.dart';
import '../../../../widgets/primary_app_bar.dart';
import '../../../../widgets/loading_view.dart';
import '../../../../widgets/error_view.dart';
import '../../../../widgets/app_drawer.dart';
import 'trip_detail_page.dart';

/// Page displaying the list of trips.
class TripListPage extends StatelessWidget {
  const TripListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = createTripCubit();
        cubit.loadTrips();
        return cubit;
      },
      child: const TripListPageView(),
    );
  }
}

class TripListPageView extends StatefulWidget {
  const TripListPageView({super.key});

  @override
  State<TripListPageView> createState() => _TripListPageViewState();
}

class _TripListPageViewState extends State<TripListPageView> {
  @override
  void initState() {
    super.initState();
    // Load trips when page is first created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TripCubit>().loadTrips();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TripCubit>();

    return Scaffold(
      drawer: const AppDrawer(currentPage: AppPage.travelTracker),
      appBar: PrimaryAppBar(
        title: 'Travel Tracker',
        actions: [
          IconButton(
            tooltip: 'Home Page',
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
      body: BlocBuilder<TripCubit, TripState>(
        builder: (context, state) {
          if (state is TripsLoading) {
            return const LoadingView();
          }

          if (state is TripsLoaded) {
            final trips = state.trips;

            if (trips.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      TravelTrackerIcons.trip,
                      size: 64,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No trips yet',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create your first trip to get started',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: trips.length,
              itemBuilder: (context, index) {
                final trip = trips[index];
                return TripListItem(
                  trip: trip,
                  onTap: () async {
                    // Navigate to detail page and refresh list when returning
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => TripDetailPage(tripId: trip.id),
                      ),
                    );
                    // Refresh the trip list when returning from detail page
                    if (mounted) {
                      context.read<TripCubit>().loadTrips();
                    }
                  },
                );
              },
            );
          }

          if (state is TripsError) {
            return ErrorView(
              message: state.message,
              onRetry: () => cubit.loadTrips(),
            );
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateTripSheet(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCreateTripSheet(BuildContext context) {
    final cubit = context.read<TripCubit>();
    TripFormBottomSheet.show(
      context,
      title: 'Create Trip',
      onSubmit: (title, destination, startDate, endDate, description) async {
        await cubit.createNewTrip(
          title: title,
          destination: destination,
          startDate: startDate,
          endDate: endDate,
          description: description,
        );
        // The cubit.loadTrips() is called in createNewTrip, so list will refresh automatically
      },
    );
  }
}

