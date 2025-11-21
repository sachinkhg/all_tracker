import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/trip.dart';
import '../bloc/trip_cubit.dart';
import '../bloc/itinerary_cubit.dart';
import '../bloc/journal_cubit.dart';
import '../bloc/journal_state.dart';
import '../bloc/expense_cubit.dart';
import '../bloc/expense_state.dart';
import '../bloc/traveler_cubit.dart';
import '../bloc/traveler_state.dart';
import '../../core/injection.dart';
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
  Trip? _trip;
  final GlobalKey _builderKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadTrip();
  }

  @override
  void dispose() {
    _tabController.dispose();
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
      initialDestination: trip.destination,
      initialStartDate: trip.startDate,
      initialEndDate: trip.endDate,
      initialDescription: trip.description,
      onSubmit: (title, destination, startDate, endDate, description) async {
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
          destination: destination,
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

  Future<void> _deleteTrip(BuildContext context, Trip trip, TripCubit cubit) async {
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
              ? Colors.white.withOpacity(0.95)
              : Colors.black87,
          opacity: 1.0,
        ),
        actionsIconTheme: IconThemeData(
          color: cs.brightness == Brightness.dark
              ? Colors.white.withOpacity(0.95)
              : Colors.black87,
          opacity: 1.0,
        ),
        elevation: 0,
        actions: [
          if (_trip != null) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Edit Trip',
              onPressed: () => _editTrip(context, _trip!, cubit),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: 'Delete Trip',
              onPressed: () => _deleteTrip(context, _trip!, cubit),
            ),
          ],
        ],
      ),
      body: _trip == null
          ? const LoadingView()
          : Column(
              children: [
                // Trip Information Card
                if (_trip != null)
                  Card(
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Trip Title
                          Text(
                            _trip!.title,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 16),
                          // Destination
                          if (_trip!.destination != null && _trip!.destination!.isNotEmpty)
                            _DetailRow(
                              label: 'Destination',
                              value: _trip!.destination!,
                              icon: Icons.location_on,
                            ),
                          // Date Range
                          if (_trip!.startDate != null || _trip!.endDate != null) ...[
                            if (_trip!.destination != null && _trip!.destination!.isNotEmpty)
                              const SizedBox(height: 12),
                            _DetailRow(
                              label: 'Dates',
                              value: dateRange(),
                              icon: Icons.calendar_today,
                            ),
                          ],
                          // Description
                          if (_trip!.description != null && _trip!.description!.isNotEmpty) ...[
                            if (_trip!.startDate != null || _trip!.endDate != null)
                              const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.description,
                                  size: 20,
                                  color: cs.onSurfaceVariant,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Description',
                                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                              color: cs.onSurfaceVariant,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _trip!.description!,
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
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
              onPressed: () => _addJournalEntry(builderContext),
              tooltip: 'Add Journal Entry',
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
              onPressed: () => _addExpense(builderContext),
              tooltip: 'Add Expense',
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
              onPressed: () => _addTraveler(builderContext),
              tooltip: 'Add Traveler',
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
          await cubit.createEntry(
            tripId: tripId,
            date: date,
            content: content,
          );
        },
      );
    } catch (e) {
      debugPrint('Error adding journal entry: $e');
    }
  }

  void _addExpense(BuildContext context) {
    try {
      ExpenseFormBottomSheet.show(
        context,
        tripId: tripId,
        onSubmit: (date, category, amount, currency, description) async {
          final cubit = context.read<ExpenseCubit>();
          await cubit.createExpenseEntry(
            tripId: tripId,
            date: date,
            category: category,
            amount: amount,
            currency: currency,
            description: description,
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
  final String value;
  final IconData icon;

  const _DetailRow({
    required this.label,
    required this.value,
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
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

