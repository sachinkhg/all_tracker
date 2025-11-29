import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../domain/entities/itinerary_day.dart';
import '../../domain/entities/itinerary_item.dart';
import '../../core/constants.dart';

/// Calendar view widget for itinerary display.
///
/// This widget displays a monthly calendar showing itinerary days
/// organized by their dates.
class ItineraryCalendarView extends StatefulWidget {
  final List<ItineraryDay> days;
  final Map<String, List<ItineraryItem>> itemsByDay;
  final Function(String) onAddItem;
  final Function(ItineraryDay) onEditDay;
  final Function(ItineraryItem) onEditItem;
  final Function(String) onDeleteItem;
  final Map<String, bool>? visibleFields;
  final bool filterActive;

  const ItineraryCalendarView({
    super.key,
    required this.days,
    required this.itemsByDay,
    required this.onAddItem,
    required this.onEditDay,
    required this.onEditItem,
    required this.onDeleteItem,
    this.visibleFields,
    this.filterActive = false,
  });

  @override
  State<ItineraryCalendarView> createState() => _ItineraryCalendarViewState();
}

class _ItineraryCalendarViewState extends State<ItineraryCalendarView> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  List<ItineraryDay> _getDaysForDate(DateTime date) {
    return widget.days.where((day) {
      final dayDate = day.date;
      return dayDate.year == date.year &&
          dayDate.month == date.month &&
          dayDate.day == date.day;
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
              // When items are shown, give calendar more space but constrain it
              Expanded(
                child: calendarOrLoader,
              ),
            if (_selectedDay != null) ...[
              // Constrain the items section to a smaller maximum height
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: heightIsBounded 
                      ? (constraints.maxHeight * 0.50)
                      : 180,
                ),
                child: _buildSelectedDayItems(theme),
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
    return TableCalendar<ItineraryDay>(
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
          _selectedDay = null; // Clear selection when changing months
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
        return _getDaysForDate(day);
      },
      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, day, events) {
          if (events.isNotEmpty) {
            final daysForDate = _getDaysForDate(day);
            final hasItems = daysForDate.any((d) {
              final items = widget.itemsByDay[d.id] ?? [];
              return items.isNotEmpty;
            });
            if (hasItems) {
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
          }
          return null;
        },
        defaultBuilder: (context, day, focusedDay) {
          final daysForDate = _getDaysForDate(day);
          final hasItems = daysForDate.any((d) {
            final items = widget.itemsByDay[d.id] ?? [];
            return items.isNotEmpty;
          });
          final isToday = isSameDay(day, DateTime.now());
          final isSelected = isSameDay(day, _selectedDay);

          Color? dayColor;
          if (hasItems) {
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

  Widget _buildSelectedDayItems(ThemeData theme) {
    if (_selectedDay == null) return const SizedBox.shrink();

    final daysForDate = _getDaysForDate(_selectedDay!);

    if (daysForDate.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'No itinerary on ${_formatDate(_selectedDay!)}',
          style: theme.textTheme.bodyMedium,
        ),
      );
    }

    // Get the first day (there should typically be only one day per date)
    final day = daysForDate.first;
    final items = widget.itemsByDay[day.id] ?? [];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Itinerary on ${_formatDate(_selectedDay!)}',
            style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text(
                      'No items scheduled',
                      style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: false,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return ListTile(
                        leading: Icon(
                          itineraryItemTypeIcons[item.type],
                          color: theme.colorScheme.primary,
                        ),
                        title: Text(item.title),
                        subtitle: item.time != null
                            ? Text(
                                '${item.time!.hour.toString().padLeft(2, '0')}:${item.time!.minute.toString().padLeft(2, '0')}${item.location != null ? ' • ${item.location}' : ''}',
                              )
                            : item.location != null
                                ? Text(item.location!)
                                : null,
                        onTap: () => widget.onEditItem(item),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => widget.onDeleteItem(item.id),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

