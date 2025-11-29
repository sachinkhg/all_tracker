import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../bloc/trip_cubit.dart';
import '../bloc/trip_state.dart';
import '../../core/injection.dart';
import '../../core/app_icons.dart';
import '../widgets/trip_list_item.dart';
import '../widgets/trip_form_bottom_sheet.dart';
import '../widgets/trip_calendar_view.dart';
import '../widgets/trip_map_view.dart';
import '../../../../widgets/primary_app_bar.dart';
import '../../../../widgets/loading_view.dart';
import '../../../../widgets/error_view.dart';
import '../../../../widgets/app_drawer.dart';
import '../../../../widgets/bottom_sheet_helpers.dart';
import '../../../../core/organization_notifier.dart';
import '../../../../pages/app_home_page.dart';
import '../../../goal_tracker/presentation/widgets/view_field_bottom_sheet.dart';
import '../../../goal_tracker/presentation/widgets/filter_group_bottom_sheet.dart';
import 'package:all_tracker/core/services/view_entity_type.dart';
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
          Consumer<OrganizationNotifier>(
            builder: (context, orgNotifier, _) {
              // Only show home icon if default home page is app_home
              if (orgNotifier.defaultHomePage == 'app_home') {
                return IconButton(
                  tooltip: 'Home Page',
                  icon: const Icon(Icons.home),
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const AppHomePage()),
                      (route) => false,
                    );
                  },
                );
              }
              return const SizedBox.shrink();
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
            final viewType = state.viewType;
            final visibleFields = state.visibleFields;

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

            // Check view type - default to 'list' if not specified
            if (viewType == 'calendar') {
              return TripCalendarView(
                trips: trips,
                onTap: (ctx, trip) async {
                  await Navigator.of(ctx).push(
                    MaterialPageRoute(
                      builder: (_) => TripDetailPage(tripId: trip.id),
                    ),
                  );
                  if (mounted) {
                    context.read<TripCubit>().loadTrips();
                  }
                },
                visibleFields: visibleFields,
                filterActive: cubit.hasActiveFilters,
              );
            } else if (viewType == 'map') {
              return TripMapView(
                trips: trips,
                onTap: (ctx, trip) async {
                  await Navigator.of(ctx).push(
                    MaterialPageRoute(
                      builder: (_) => TripDetailPage(tripId: trip.id),
                    ),
                  );
                  if (mounted) {
                    context.read<TripCubit>().loadTrips();
                  }
                },
                visibleFields: visibleFields,
                filterActive: cubit.hasActiveFilters,
              );
            } else {
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
                    visibleFields: visibleFields,
                  );
                },
              );
            }
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
      floatingActionButton: BlocBuilder<TripCubit, TripState>(
        builder: (context, state) {
          final filterActive = cubit.hasActiveFilters;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton.small(
                    heroTag: 'viewFab',
                    tooltip: 'Change View',
                    backgroundColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
                    onPressed: () => _onView(context, cubit),
                    child: const Icon(Icons.remove_red_eye),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton.small(
                    heroTag: 'filterFab',
                    tooltip: 'Filter',
                    backgroundColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
                    onPressed: () => _onFilter(context, cubit),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(Icons.filter_alt),
                        if (filterActive)
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              FloatingActionButton(
                heroTag: 'tripListFab',
                tooltip: 'Create Trip',
                backgroundColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
                onPressed: () => _showCreateTripSheet(context),
                child: const Icon(Icons.add),
              ),
            ],
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  void _showCreateTripSheet(BuildContext context) {
    final cubit = context.read<TripCubit>();
    TripFormBottomSheet.show(
      context,
      title: 'Create Trip',
      onSubmit: (title, tripType, destination, destinationLatitude, destinationLongitude, destinationMapLink, startDate, endDate, description) async {
        await cubit.createNewTrip(
          title: title,
          tripType: tripType,
          destination: destination,
          destinationLatitude: destinationLatitude,
          destinationLongitude: destinationLongitude,
          destinationMapLink: destinationMapLink,
          startDate: startDate,
          endDate: endDate,
          description: description,
        );
        // The cubit.loadTrips() is called in createNewTrip, so list will refresh automatically
      },
    );
  }

  Future<void> _onView(BuildContext context, TripCubit cubit) async {
    final currentState = cubit.state;
    final Map<String, bool>? initial =
        currentState is TripsLoaded ? currentState.visibleFields : <String, bool>{};
    final String? initialViewType =
        currentState is TripsLoaded ? currentState.viewType : 'list';

    final result = await showAppBottomSheet<Map<String, dynamic>?>(
      context,
      ViewFieldsBottomSheet(
        entity: ViewEntityType.trip,
        initial: initial,
        initialViewType: initialViewType,
      ),
    );
    if (result == null) return;
    
    final fields = result['fields'] as Map<String, bool>;
    final saveView = result['saveView'] as bool;
    final viewType = result['viewType'] as String? ?? 'list';
    
    final viewPrefsService = cubit.viewPreferencesService;
    
    if (saveView) {
      await viewPrefsService.saveViewPreferences(ViewEntityType.trip, fields);
      await viewPrefsService.saveViewType(ViewEntityType.trip, viewType);
    } else {
      await viewPrefsService.clearViewPreferences(ViewEntityType.trip);
      await viewPrefsService.clearViewType(ViewEntityType.trip);
    }
    
    cubit.setVisibleFields(fields);
    cubit.setViewType(viewType);
  }

  Future<void> _onFilter(BuildContext context, TripCubit cubit) async {
    final savedFilters = cubit.filterPreferencesService.loadFilterPreferences(FilterEntityType.trip);
    final hasSavedFilters = savedFilters != null && savedFilters['targetDate'] != null;
    
    // Use current filter from cubit if available, otherwise use saved filter
    final currentFilter = cubit.currentDateFilter ?? savedFilters?['targetDate'];
    
    final result = await showAppBottomSheet<Map<String, dynamic>?>(
      context,
      FilterGroupBottomSheet(
        entity: FilterEntityType.trip,
        initialDateFilter: currentFilter,
        initialSaveFilter: hasSavedFilters,
      ),
    );

    if (result == null) return;

    if (result.containsKey('targetDate')) {
      final saveFilter = result['saveFilter'] as bool? ?? false;
      
      if (saveFilter) {
        final filters = <String, String?>{
          'targetDate': result['targetDate'] as String?,
        };
        await cubit.filterPreferencesService.saveFilterPreferences(FilterEntityType.trip, filters);
      } else {
        await cubit.filterPreferencesService.clearFilterPreferences(FilterEntityType.trip);
      }
      
      cubit.applyFilter(
        targetDate: result['targetDate'] as String?,
      );
    }
  }
}

