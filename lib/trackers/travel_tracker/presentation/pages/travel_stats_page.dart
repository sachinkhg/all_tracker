import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/trip_cubit.dart';
import '../bloc/trip_state.dart';
import '../../core/injection.dart';
import '../../data/services/stats_service.dart';
import '../../../../widgets/loading_view.dart';

/// Page displaying travel statistics for a trip.
class TravelStatsPage extends StatelessWidget {
  final String tripId;

  const TravelStatsPage({
    super.key,
    required this.tripId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = createTripCubit();
        cubit.loadTrips();
        return cubit;
      },
      child: TravelStatsPageView(tripId: tripId),
    );
  }
}

class TravelStatsPageView extends StatelessWidget {
  final String tripId;

  const TravelStatsPageView({
    super.key,
    required this.tripId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TripCubit, TripState>(
      builder: (context, state) {
        if (state is TripsLoading) {
          return const LoadingView();
        }

        if (state is TripsLoaded) {
          final trip = state.trips.firstWhere(
            (t) => t.id == tripId,
            orElse: () => throw Exception('Trip not found'),
          );

          final startDate = trip.startDate ?? DateTime.now();
          final endDate = trip.endDate ?? DateTime.now();
          final daysTraveled = endDate.difference(startDate).inDays + 1;

          final countries = StatsService.getCountriesVisited([trip]);
          final totalDays = StatsService.getTotalDaysTraveled([trip]);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _StatsCard(
                  title: 'Trip Duration',
                  value: '$daysTraveled days',
                  icon: Icons.calendar_today,
                ),
                const SizedBox(height: 16),
                _StatsCard(
                  title: 'Countries Visited',
                  value: '${countries.length}',
                  icon: Icons.public,
                ),
                const SizedBox(height: 16),
                _StatsCard(
                  title: 'Total Days Traveled',
                  value: '$totalDays days',
                  icon: Icons.flight_takeoff,
                ),
              ],
            ),
          );
        }

        return const Center(child: Text('Error loading stats'));
      },
    );
  }
}

class _StatsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatsCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: cs.primary, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

