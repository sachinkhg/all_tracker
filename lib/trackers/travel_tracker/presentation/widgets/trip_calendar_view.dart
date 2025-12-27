import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/trip.dart';
import '../widgets/trip_list_item.dart';

/// Calendar view widget for trip display.
///
/// This widget displays a monthly calendar showing trips
/// organized by their start dates.
class TripCalendarView extends StatefulWidget {
  final List<Trip> trips;
  final Function(BuildContext, Trip) onTap;
  final Map<String, bool>? visibleFields;
  final bool filterActive;

  const TripCalendarView({
    super.key,
    required this.trips,
    required this.onTap,
    this.visibleFields,
    this.filterActive = false,
  });

  @override
  State<TripCalendarView> createState() => _TripCalendarViewState();
}

class _TripCalendarViewState extends State<TripCalendarView> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  List<Trip> _getTripsForDay(DateTime day) {
    return widget.trips.where((trip) {
      if (trip.startDate == null) return false;
      final tripDate = trip.startDate!;
      return tripDate.year == day.year &&
          tripDate.month == day.month &&
          tripDate.day == day.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool heightIsBounded =
            constraints.hasBoundedHeight && constraints.maxHeight.isFinite;
        final bool tightHeight = heightIsBounded && constraints.maxHeight < 380;

        final Widget calendarOrLoader = _buildCalendar(theme);

        final column = Column(
          children: [
            if (!heightIsBounded || tightHeight)
              calendarOrLoader
            else
              Expanded(
                child: calendarOrLoader,
              ),
            if (_selectedDay != null) ...[
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: heightIsBounded 
                      ? (constraints.maxHeight * 0.50)
                      : 180,
                ),
                child: _buildSelectedDayTrips(theme),
              ),
            ],
          ],
        );

        return (!heightIsBounded || tightHeight)
            ? SingleChildScrollView(child: column)
            : column;
      },
    );
  }

  Widget _buildCalendar(ThemeData theme) {
    return TableCalendar<Trip>(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      onDaySelected: (selectedDay, focusedDay) {
        if (!isSameDay(_selectedDay, selectedDay)) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        }
      },
      onPageChanged: (focusedDay) {
        setState(() {
          _focusedDay = focusedDay;
          _selectedDay = null;
        });
      },
      calendarFormat: CalendarFormat.month,
      startingDayOfWeek: StartingDayOfWeek.monday,
      calendarStyle: CalendarStyle(
        outsideDaysVisible: false,
        weekendTextStyle: TextStyle(color: theme.colorScheme.primary),
        holidayTextStyle: TextStyle(color: theme.colorScheme.primary),
        defaultTextStyle: TextStyle(color: theme.colorScheme.onSurface),
        selectedTextStyle: TextStyle(color: theme.colorScheme.onPrimary),
        todayTextStyle: TextStyle(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
        selectedDecoration: BoxDecoration(
          color: theme.colorScheme.primary,
          shape: BoxShape.circle,
        ),
        todayDecoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
        markerDecoration: BoxDecoration(
          color: theme.colorScheme.secondary,
          shape: BoxShape.circle,
        ),
        cellPadding: EdgeInsets.zero,
      ),
      headerStyle: HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        titleTextStyle: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ) ??
            const TextStyle(fontWeight: FontWeight.w600),
        leftChevronIcon: Icon(
          Icons.chevron_left,
          color: theme.colorScheme.primary,
        ),
        rightChevronIcon: Icon(
          Icons.chevron_right,
          color: theme.colorScheme.primary,
        ),
        headerPadding: const EdgeInsets.symmetric(vertical: 8),
        leftChevronPadding: EdgeInsets.zero,
        rightChevronPadding: EdgeInsets.zero,
      ),
      eventLoader: (day) {
        return _getTripsForDay(day);
      },
      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, day, events) {
          if (events.isNotEmpty) {
            return Positioned(
              bottom: 1,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary,
                  shape: BoxShape.circle,
                ),
              ),
            );
          }
          return null;
        },
        defaultBuilder: (context, day, focusedDay) {
          final tripsForDay = _getTripsForDay(day);
          final hasTrips = tripsForDay.isNotEmpty;
          final isToday = isSameDay(day, DateTime.now());
          final isSelected = isSameDay(day, _selectedDay);

          Color? dayColor;
          if (hasTrips) {
            dayColor = theme.colorScheme.primary.withValues(alpha: 0.3);
          }

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primary.withValues(alpha: 0.5)
                  : dayColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${day.day}',
                style: TextStyle(
                  color: isSelected
                      ? theme.colorScheme.onPrimary
                      : isToday
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSelectedDayTrips(ThemeData theme) {
    if (_selectedDay == null) return const SizedBox.shrink();

    final tripsForDay = _getTripsForDay(_selectedDay!);

    if (tripsForDay.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'No trips on ${_formatDate(_selectedDay!)}',
          style: theme.textTheme.bodyMedium,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trips on ${_formatDate(_selectedDay!)}',
            style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: ListView.builder(
              shrinkWrap: false,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: tripsForDay.length,
              itemBuilder: (context, index) {
                final trip = tripsForDay[index];
                return TripListItem(
                  trip: trip,
                  onTap: () => widget.onTap(context, trip),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }
}

