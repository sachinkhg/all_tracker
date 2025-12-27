import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/trip.dart';
import '../../domain/entities/itinerary_day.dart';
import '../bloc/trip_cubit.dart';
import '../bloc/itinerary_cubit.dart';
import '../bloc/itinerary_state.dart';
import '../bloc/journal_cubit.dart';
import '../bloc/journal_state.dart';
import '../bloc/expense_cubit.dart';
import '../bloc/expense_state.dart';
import '../bloc/traveler_cubit.dart';
import '../bloc/traveler_state.dart';
import '../../domain/entities/traveler.dart';
import '../../core/injection.dart';
import '../../core/constants.dart';
import '../../../../widgets/loading_view.dart';
import '../../../../core/design_tokens.dart';
import 'itinerary_view_page.dart';
import 'journal_entry_page.dart';
import 'expense_list_page.dart';
import 'travelers_page.dart';
import '../widgets/trip_form_bottom_sheet.dart';
import '../widgets/journal_entry_form_bottom_sheet.dart';
import '../widgets/expense_form_bottom_sheet.dart';
import '../widgets/traveler_form_bottom_sheet.dart';
import '../widgets/shift_dates_bottom_sheet.dart';

/// Detail page for a trip showing tabs for Itinerary, Journal, Expenses, and Stats.
class TripDetailPage extends StatelessWidget {
  final String tripId;

  const TripDetailPage({
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
      child: TripDetailPageView(tripId: tripId),
    );
  }
}

class TripDetailPageView extends StatefulWidget {
  final String tripId;

  const TripDetailPageView({
    super.key,
    required this.tripId,
  });

  @override
  State<TripDetailPageView> createState() => _TripDetailPageViewState();
}

class _TripDetailPageViewState extends State<TripDetailPageView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late PageController _pageController;
  Trip? _trip;
  final GlobalKey _builderKey = GlobalKey();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _pageController = PageController();
    _loadTrip();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadTrip() async {
    final cubit = context.read<TripCubit>();
    final trip = await cubit.getTripById(widget.tripId);
    if (mounted) {
      setState(() {
        _trip = trip;
      });
    }
  }

  void _refreshItinerary() {
    // Access the ItineraryCubit from the builder context
    // Use post-frame callback to ensure the context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final BuildContext? builderContext = _builderKey.currentContext;
        if (builderContext != null && mounted) {
          final itineraryCubit = builderContext.read<ItineraryCubit>();
          itineraryCubit.loadItinerary(widget.tripId);
        }
      } catch (e) {
        debugPrint('Error refreshing itinerary: $e');
      }
    });
  }

  Future<void> _editTrip(BuildContext context, Trip trip, TripCubit cubit) async {
    await TripFormBottomSheet.show(
      context,
      title: 'Edit Trip',
      tripId: trip.id,
      initialTitle: trip.title,
      initialTripType: trip.tripType,
      initialDestination: trip.destination,
      initialDestinationLatitude: trip.destinationLatitude,
      initialDestinationLongitude: trip.destinationLongitude,
      initialDestinationMapLink: trip.destinationMapLink,
      initialStartDate: trip.startDate,
      initialEndDate: trip.endDate,
      initialDescription: trip.description,
      onSubmit: (title, tripType, destination, destinationLatitude, destinationLongitude, destinationMapLink, startDate, endDate, description) async {
        // Check if dates changed
        final oldStartDate = trip.startDate != null
            ? DateTime(trip.startDate!.year, trip.startDate!.month, trip.startDate!.day)
            : null;
        final oldEndDate = trip.endDate != null
            ? DateTime(trip.endDate!.year, trip.endDate!.month, trip.endDate!.day)
            : null;
        final newStartDate = startDate != null
            ? DateTime(startDate.year, startDate.month, startDate.day)
            : null;
        final newEndDate = endDate != null
            ? DateTime(endDate.year, endDate.month, endDate.day)
            : null;

        final datesChanged = oldStartDate != newStartDate || oldEndDate != newEndDate;

        final updated = Trip(
          id: trip.id,
          title: title,
          tripType: tripType,
          destination: destination,
          destinationLatitude: destinationLatitude,
          destinationLongitude: destinationLongitude,
          destinationMapLink: destinationMapLink,
          startDate: startDate,
          endDate: endDate,
          description: description,
          createdAt: trip.createdAt,
          updatedAt: DateTime.now(),
        );
        await cubit.updateTrip(updated);
        // Reload trip data after updating
        if (mounted) {
          await _loadTrip();
          // Always refresh itinerary when dates change to reset days based on new date range
          // Days outside the range will be deleted, days within the range will be preserved
          if (datesChanged) {
            _refreshItinerary();
          }
        }
      },
      onDelete: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Trip'),
            content: Text('Are you sure you want to delete "${trip.title}"? This action cannot be undone.'),
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
        if (confirmed == true && mounted) {
          await cubit.deleteTrip(trip.id);
          // Navigate back to trip list if trip is deleted
          if (mounted) {
            Navigator.of(context).pop();
          }
        }
      },
    );
  }

  // Future<void> _deleteTrip(BuildContext context, Trip trip, TripCubit cubit) async {
  //   final confirmed = await showDialog<bool>(
  //     context: context,
  //     builder: (ctx) => AlertDialog(
  //       title: const Text('Delete Trip'),
  //       content: Text('Are you sure you want to delete "${trip.title}"? This action cannot be undone.'),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.of(ctx).pop(false),
  //           child: const Text('Cancel'),
  //         ),
  //         TextButton(
  //           onPressed: () => Navigator.of(ctx).pop(true),
  //           style: TextButton.styleFrom(
  //             foregroundColor: Theme.of(ctx).colorScheme.error,
  //           ),
  //           child: const Text('Delete'),
  //         ),
  //       ],
  //     ),
  //   );
  //   if (confirmed == true && mounted) {
  //     await cubit.deleteTrip(trip.id);
  //     // Navigate back to trip list if trip is deleted
  //     if (mounted) {
  //       Navigator.of(context).pop();
  //     }
  //   }
  // }

  Future<void> _shiftDates(BuildContext context, Trip trip, TripCubit cubit) async {
    if (trip.startDate == null || trip.endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trip must have both start and end dates to shift dates'),
        ),
      );
      return;
    }

    await ShiftDatesBottomSheet.show(
      context,
      initialStartDate: trip.startDate,
      initialEndDate: trip.endDate,
      onSubmit: (newStartDate, newEndDate, shiftItinerary) async {
        if (newStartDate == null || newEndDate == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Both start and end dates are required'),
            ),
          );
          return;
        }

        // Normalize dates to date-only for comparison
        final oldStartDate = DateTime(
          trip.startDate!.year,
          trip.startDate!.month,
          trip.startDate!.day,
        );
        final newStartDateNormalized = DateTime(
          newStartDate.year,
          newStartDate.month,
          newStartDate.day,
        );
        final newEndDateNormalized = DateTime(
          newEndDate.year,
          newEndDate.month,
          newEndDate.day,
        );

        // Calculate the shift amount (difference in days)
        final shiftDays = newStartDateNormalized.difference(oldStartDate).inDays;

        // Update trip dates
        final updated = Trip(
          id: trip.id,
          title: trip.title,
          destination: trip.destination,
          startDate: newStartDateNormalized,
          endDate: newEndDateNormalized,
          description: trip.description,
          createdAt: trip.createdAt,
          updatedAt: DateTime.now(),
        );
        await cubit.updateTrip(updated);

        // If shiftItinerary is checked, shift all itinerary days
        if (shiftItinerary && shiftDays != 0) {
          try {
            // Access the ItineraryCubit from the builder context
            final BuildContext? builderContext = _builderKey.currentContext;
            if (builderContext != null && mounted) {
              final itineraryCubit = builderContext.read<ItineraryCubit>();
              
              // Get current itinerary state
              final state = itineraryCubit.state;
              if (state is ItineraryLoaded) {
                // Shift each itinerary day by the calculated number of days
                // Days that end up outside the new range will be deleted by the refresh
                for (final day in state.days) {
                  final newDayDate = day.date.add(Duration(days: shiftDays));
                  
                  // Update the day with the new date
                  // The refresh will handle deleting days outside the new range
                  final updatedDay = ItineraryDay(
                    id: day.id,
                    tripId: day.tripId,
                    date: newDayDate,
                    notes: day.notes,
                    createdAt: day.createdAt,
                    updatedAt: DateTime.now(),
                  );
                  await itineraryCubit.updateDayEntry(updatedDay);
                }
              }
              
              // Refresh itinerary to handle days outside the new range
              itineraryCubit.loadItinerary(trip.id);
            }
          } catch (e) {
            debugPrint('Error shifting itinerary: $e');
            // Still refresh itinerary to clean up days outside range
            try {
              final BuildContext? builderContext = _builderKey.currentContext;
              if (builderContext != null && mounted) {
                final itineraryCubit = builderContext.read<ItineraryCubit>();
                itineraryCubit.loadItinerary(trip.id);
              }
            } catch (_) {
              // Ignore errors in cleanup
            }
          }
        } else {
          // Even if not shifting itinerary, refresh to remove days outside new range
          try {
            final BuildContext? builderContext = _builderKey.currentContext;
            if (builderContext != null && mounted) {
              final itineraryCubit = builderContext.read<ItineraryCubit>();
              itineraryCubit.loadItinerary(trip.id);
            }
          } catch (e) {
            debugPrint('Error refreshing itinerary: $e');
          }
        }

        // Reload trip data after updating
        if (mounted) {
          await _loadTrip();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cubit = context.read<TripCubit>();

    String formatDate(DateTime? date) {
      if (date == null) return 'Not set';
      return DateFormat('MMM dd, yyyy').format(date);
    }

    String dateRange() {
      if (_trip == null) return 'Not set';
      final trip = _trip!;
      if (trip.startDate == null && trip.endDate == null) {
        return 'Not set';
      }
      if (trip.startDate != null && trip.endDate != null) {
        return '${formatDate(trip.startDate)} - ${formatDate(trip.endDate)}';
      }
      if (trip.startDate != null) {
        return 'From ${formatDate(trip.startDate)}';
      }
      return 'Until ${formatDate(trip.endDate)}';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Details'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: AppGradients.appBar(cs),
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: cs.onPrimary,
        iconTheme: IconThemeData(
          color: cs.brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.95)
              : Colors.black87,
          opacity: 1.0,
        ),
        actionsIconTheme: IconThemeData(
          color: cs.brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.95)
              : Colors.black87,
          opacity: 1.0,
        ),
        elevation: 0,
        actions: [
          if (_trip != null) ...[
            IconButton(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.calendar_today),
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: cs.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: cs.surface,
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.edit,
                        size: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              tooltip: 'Shift Dates',
              onPressed: () => _shiftDates(context, _trip!, cubit),
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Edit Trip',
              onPressed: () => _editTrip(context, _trip!, cubit),
            ),
            // IconButton(
            //   icon: const Icon(Icons.delete),
            //   tooltip: 'Delete Trip',
            //   onPressed: () => _deleteTrip(context, _trip!, cubit),
            // ),
          ],
        ],
      ),
      body: _trip == null
          ? const LoadingView()
          : Column(
              children: [
                // Swipeable Section: Trip Info and Expense Summary
                SizedBox(
                  height: 220,
                  child: Column(
                    children: [
                      Expanded(
                        child: PageView(
                          controller: _pageController,
                          onPageChanged: (index) {
                            setState(() {
                              _currentPage = index;
                            });
                          },
                          children: [
                            // Page 1: Trip Information Card
                            if (_trip != null)
                              Card(
                                margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                                elevation: 2,
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Trip Title with Description Tooltip
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              _trip!.title,
                                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                          ),
                                          if (_trip!.description != null && _trip!.description!.isNotEmpty)
                                            Tooltip(
                                              message: _trip!.description!,
                                              preferBelow: false,
                                              waitDuration: const Duration(milliseconds: 500),
                                              child: InkWell(
                                                onTap: () {
                                                  showDialog(
                                                    context: context,
                                                    builder: (context) => AlertDialog(
                                                      title: const Text('Description'),
                                                      content: Text(_trip!.description!),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () => Navigator.of(context).pop(),
                                                          child: const Text('Close'),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                },
                                                child: Padding(
                                                  padding: const EdgeInsets.all(4.0),
                                                  child: Icon(
                                                    Icons.info_outline,
                                                    size: 20,
                                                    color: cs.onSurfaceVariant,
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      // Trip Type
                                      if (_trip!.tripType != null)
                                        _DetailRow(
                                          label: tripTypeLabels[_trip!.tripType]!,
                                          icon: tripTypeIcons[_trip!.tripType]!,
                                        ),
                                      // Destination
                                      if (_trip!.destination != null && _trip!.destination!.isNotEmpty) ...[
                                        if (_trip!.tripType != null)
                                          const SizedBox(height: 12),
                                        _DetailRow(
                                          label:  _trip!.destination!,
                                          //value: _trip!.destination!,
                                          icon: Icons.location_on,
                                        ),
                                      ],
                                      // Date Range
                                      if (_trip!.startDate != null || _trip!.endDate != null) ...[
                                        if ((_trip!.destination != null && _trip!.destination!.isNotEmpty) || _trip!.tripType != null)
                                          const SizedBox(height: 12),
                                        _DetailRow(
                                          label: dateRange(),
                                          //value: dateRange(),
                                          icon: Icons.calendar_today,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            // Page 2: Expense Summary
                            _ExpenseSummarySection(tripId: widget.tripId),
                          ],
                        ),
                      ),
                      // Page Indicators
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(2, (index) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentPage == index
                                  ? cs.primary
                                  : cs.onSurfaceVariant.withValues(alpha: 0.4),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
                // TabBar
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Itinerary', icon: Icon(Icons.calendar_today)),
                    Tab(text: 'Journal', icon: Icon(Icons.book)),
                    Tab(text: 'Expenses', icon: Icon(Icons.attach_money)),
                    Tab(text: 'Travelers', icon: Icon(Icons.people)),
                  ],
                ),
                // Tab Bar View
                Expanded(
                  child: MultiBlocProvider(
                    providers: [
                      BlocProvider(
                        create: (_) {
                          final cubit = createItineraryCubit();
                          cubit.loadItinerary(widget.tripId);
                          return cubit;
                        },
                      ),
                      BlocProvider(
                        create: (_) {
                          final cubit = createJournalCubit();
                          cubit.loadEntries(widget.tripId);
                          return cubit;
                        },
                      ),
                      BlocProvider(
                        create: (_) {
                          final cubit = createExpenseCubit();
                          cubit.loadExpenses(widget.tripId);
                          return cubit;
                        },
                      ),
                      BlocProvider(
                        create: (_) {
                          final cubit = createTravelerCubit();
                          cubit.loadTravelers(widget.tripId);
                          return cubit;
                        },
                      ),
                    ],
                    child: Builder(
                      key: _builderKey,
                      builder: (builderContext) => Stack(
                        children: [
                          TabBarView(
                            controller: _tabController,
                            children: [
                              ItineraryViewPage(tripId: widget.tripId),
                              JournalEntryPage(tripId: widget.tripId),
                              ExpenseListPage(tripId: widget.tripId),
                              TravelersPage(tripId: widget.tripId),
                            ],
                          ),
                          Positioned(
                            bottom: 16,
                            right: 16,
                            child: AnimatedBuilder(
                              animation: _tabController,
                              builder: (context, child) {
                                return _QuickAddButton(
                                  tripId: widget.tripId,
                                  currentTab: _tabController.index,
                                  builderContext: builderContext,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _QuickAddButton extends StatelessWidget {
  final String tripId;
  final int currentTab;
  final BuildContext builderContext;

  const _QuickAddButton({
    required this.tripId,
    required this.currentTab,
    required this.builderContext,
  });

  @override
  Widget build(BuildContext context) {
    // Show FAB for journal (1), expenses (2), and travelers (3) tabs
    // Itinerary tab (0) doesn't need FAB
    if (currentTab == 0) {
      return const SizedBox.shrink();
    }

    if (currentTab == 1) {
      // Journal tab - show FAB only if there are entries
      return BlocBuilder<JournalCubit, JournalState>(
        builder: (context, state) {
          if (state is JournalLoaded && state.entries.isNotEmpty) {
            return FloatingActionButton(
              heroTag: 'journalFab',
              tooltip: 'Add Journal Entry',
              backgroundColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
              onPressed: () => _addJournalEntry(builderContext),
              child: const Icon(Icons.add),
            );
          }
          return const SizedBox.shrink();
        },
        buildWhen: (previous, current) => current is JournalLoaded,
      );
    } else if (currentTab == 2) {
      // Expenses tab - show FAB only if there are expenses
      return BlocBuilder<ExpenseCubit, ExpenseState>(
        builder: (context, state) {
          if (state is ExpensesLoaded && state.expenses.isNotEmpty) {
            return FloatingActionButton(
              heroTag: 'expenseFab',
              tooltip: 'Add Expense',
              backgroundColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
              onPressed: () => _addExpense(builderContext),
              child: const Icon(Icons.add),
            );
          }
          return const SizedBox.shrink();
        },
        buildWhen: (previous, current) => current is ExpensesLoaded,
      );
    } else if (currentTab == 3) {
      // Travelers tab - show FAB if there are travelers
      return BlocBuilder<TravelerCubit, TravelerState>(
        builder: (context, state) {
          if (state is TravelersLoaded && state.travelers.isNotEmpty) {
            return FloatingActionButton(
              heroTag: 'travelerFab',
              tooltip: 'Add Traveler',
              backgroundColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
              onPressed: () => _addTraveler(builderContext),
              child: const Icon(Icons.add),
            );
          }
          return const SizedBox.shrink();
        },
        buildWhen: (previous, current) => current is TravelersLoaded,
      );
    }

    return const SizedBox.shrink();
  }

  void _addJournalEntry(BuildContext context) {
    try {
      JournalEntryFormBottomSheet.show(
        context,
        tripId: tripId,
        onSubmit: (date, content) async {
          final cubit = context.read<JournalCubit>();
          final createdEntry = await cubit.createEntry(
            tripId: tripId,
            date: date,
            content: content,
          );
          return createdEntry?.id;
        },
      );
    } catch (e) {
      debugPrint('Error adding journal entry: $e');
    }
  }

  void _addExpense(BuildContext context) {
    try {
      // Get travelers if TravelerCubit is available
      List<Traveler> travelers = [];
      try {
        final travelerCubit = context.read<TravelerCubit>();
        final travelerState = travelerCubit.state;
        if (travelerState is TravelersLoaded) {
          travelers = travelerState.travelers;
        }
      } catch (_) {
        // TravelerCubit not available
      }

      ExpenseFormBottomSheet.show(
        context,
        tripId: tripId,
        travelers: travelers.isNotEmpty ? travelers : null,
        onSubmit: (date, category, amount, currency, description, paidBy) async {
          final cubit = context.read<ExpenseCubit>();
          await cubit.createExpenseEntry(
            tripId: tripId,
            date: date,
            category: category,
            amount: amount,
            currency: currency,
            description: description,
            paidBy: paidBy,
          );
        },
      );
    } catch (e) {
      debugPrint('Error adding expense: $e');
    }
  }

  void _addTraveler(BuildContext context) {
    try {
      TravelerFormBottomSheet.show(
        context,
        tripId: tripId,
        onSubmit: (name, relationship, email, phone, notes, isMainTraveler) async {
          final cubit = context.read<TravelerCubit>();
          await cubit.createTraveler(
            tripId: tripId,
            name: name,
            relationship: relationship,
            email: email,
            phone: phone,
            notes: notes,
            isMainTraveler: isMainTraveler,
          );
        },
      );
    } catch (e) {
      debugPrint('Error adding traveler: $e');
    }
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  //final String value;
  final IconData icon;

  const _DetailRow({
    required this.label,
    //required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: cs.onSurfaceVariant,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
              ),
              // const SizedBox(height: 4),
              // Text(
              //   value,
              //   style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              //         fontWeight: FontWeight.w500,
              //       ),
              // ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Expense Summary Section widget showing total expense and per-category breakdown.
class _ExpenseSummarySection extends StatelessWidget {
  final String tripId;

  const _ExpenseSummarySection({
    required this.tripId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = createExpenseCubit();
        cubit.loadExpenses(tripId);
        return cubit;
      },
      child: BlocBuilder<ExpenseCubit, ExpenseState>(
        builder: (context, state) {
          if (state is ExpensesLoading) {
            return Card(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              elevation: 2,
              child: const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              ),
            );
          }

          if (state is ExpensesError) {
            return Card(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    'Error loading expenses',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                  ),
                ),
              ),
            );
          }

          if (state is ExpensesLoaded) {
            final expenses = state.expenses;
            
            if (expenses.isEmpty) {
              return Card(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      'No expenses recorded',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                ),
              );
            }

            // Calculate total and per-category expenses
            double totalExpense = 0.0;
            final Map<ExpenseCategory, double> categoryExpenses = {};
            String? primaryCurrency;

            for (final expense in expenses) {
              // For now, we'll show total in the first currency we encounter
              // In a real app, you might want to handle currency conversion
              primaryCurrency ??= expense.currency;
              
              // Only sum expenses in the primary currency for simplicity
              if (expense.currency == primaryCurrency) {
                totalExpense += expense.amount;
                categoryExpenses[expense.category] = 
                    (categoryExpenses[expense.category] ?? 0.0) + expense.amount;
              }
            }

            final cs = Theme.of(context).colorScheme;

            return Card(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Row(
                      children: [
                        const SizedBox(width: 8),
                        Text(
                          'Expense Summary: ${NumberFormat('#,##0.00').format(totalExpense)}',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                         
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    // Category Breakdown
                    Expanded(
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 2.8,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: ExpenseCategory.values.length,
                        itemBuilder: (context, index) {
                          final category = ExpenseCategory.values[index];
                          final amount = categoryExpenses[category] ?? 0.0;
                          final percentage = totalExpense > 0 
                              ? (amount / totalExpense * 100) 
                              : 0.0;

                          return Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      _getCategoryIcon(category),
                                      size: 14,
                                      color: cs.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        expenseCategoryLabels[category]!,
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 11,
                                            ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        NumberFormat('#,##0.00').format(amount),
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 11,
                                            ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (totalExpense > 0)
                                      Text(
                                        '${percentage.toStringAsFixed(0)}%',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: cs.onSurfaceVariant,
                                              fontSize: 9,
                                            ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  IconData _getCategoryIcon(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.food:
        return Icons.restaurant;
      case ExpenseCategory.travel:
        return Icons.directions_transit;
      case ExpenseCategory.stay:
        return Icons.hotel;
      case ExpenseCategory.other:
        return Icons.category;
    }
  }
}

