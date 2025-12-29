import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class ReadingHeatmapChart extends StatefulWidget {
  final Map<DateTime, int> dayCounts;

  const ReadingHeatmapChart({
    super.key,
    required this.dayCounts,
  });

  @override
  State<ReadingHeatmapChart> createState() => _ReadingHeatmapChartState();
}

class _ReadingHeatmapChartState extends State<ReadingHeatmapChart> {
  late DateTime _focusedDay;

  @override
  void initState() {
    super.initState();
    _updateFocusedDay();
  }

  @override
  void didUpdateWidget(ReadingHeatmapChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dayCounts != widget.dayCounts) {
      _updateFocusedDay();
    }
  }

  void _updateFocusedDay() {
    if (widget.dayCounts.isEmpty) {
      _focusedDay = DateTime.now();
      return;
    }

    final dates = widget.dayCounts.keys.toList()..sort();
    final lastDay = dates.last;
    final now = DateTime.now();
    
    // Use the later of: last day with data, or today (but not in the future)
    if (lastDay.isAfter(now)) {
      _focusedDay = now;
    } else {
      _focusedDay = lastDay;
    }
  }

  int _getCountForDay(DateTime day) {
    final dayKey = DateTime(day.year, day.month, day.day);
    return widget.dayCounts[dayKey] ?? 0;
  }

  Color _getColorForDay(DateTime day, ThemeData theme) {
    final count = _getCountForDay(day);
    if (count == 0) {
      return theme.colorScheme.surfaceContainerHighest;
    }

    final maxCount = widget.dayCounts.values.isEmpty
        ? 1
        : widget.dayCounts.values.reduce((a, b) => a > b ? a : b);

    final intensity = (count / maxCount).clamp(0.0, 1.0);
    final baseColor = theme.colorScheme.primary;

    // Create gradient from light to dark based on intensity
    if (intensity < 0.25) {
      return baseColor.withValues(alpha: 0.3);
    } else if (intensity < 0.5) {
      return baseColor.withValues(alpha: 0.5);
    } else if (intensity < 0.75) {
      return baseColor.withValues(alpha: 0.7);
    } else {
      return baseColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (widget.dayCounts.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('No reading activity data available'),
        ),
      );
    }

    // Find the earliest and latest dates
    final dates = widget.dayCounts.keys.toList()..sort();
    final now = DateTime.now();
    final firstDay = dates.isNotEmpty 
        ? dates.first 
        : DateTime(now.year - 1, now.month, 1);
    final lastDay = dates.isNotEmpty 
        ? dates.last 
        : now;

    // Calculate calendar bounds (first day of first month, last day of last month)
    final calendarFirstDay = DateTime(firstDay.year, firstDay.month, 1);
    final calendarLastDay = DateTime(lastDay.year, lastDay.month + 1, 0);

    // Ensure focusedDay is within bounds
    DateTime safeFocusedDay = _focusedDay;
    if (safeFocusedDay.isBefore(calendarFirstDay)) {
      safeFocusedDay = calendarFirstDay;
    } else if (safeFocusedDay.isAfter(calendarLastDay)) {
      safeFocusedDay = calendarLastDay;
    }

    return TableCalendar(
      firstDay: calendarFirstDay,
      lastDay: calendarLastDay,
      focusedDay: safeFocusedDay,
      calendarFormat: CalendarFormat.month,
      startingDayOfWeek: StartingDayOfWeek.monday,
      onPageChanged: (focusedDay) {
        setState(() {
          _focusedDay = focusedDay;
        });
      },
      calendarStyle: CalendarStyle(
        outsideDaysVisible: false,
        defaultTextStyle: TextStyle(color: colorScheme.onSurface),
        weekendTextStyle: TextStyle(color: colorScheme.onSurface),
        holidayTextStyle: TextStyle(color: colorScheme.onSurface),
        todayTextStyle: TextStyle(
          color: colorScheme.onPrimary,
          fontWeight: FontWeight.bold,
        ),
        todayDecoration: BoxDecoration(
          color: colorScheme.primary,
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
          color: colorScheme.primary,
        ),
        rightChevronIcon: Icon(
          Icons.chevron_right,
          color: colorScheme.primary,
        ),
        headerPadding: const EdgeInsets.symmetric(vertical: 8),
      ),
      calendarBuilders: CalendarBuilders(
        defaultBuilder: (context, date, _) {
          final count = _getCountForDay(date);
          final color = _getColorForDay(date, theme);
          return Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${date.day}',
                style: TextStyle(
                  color: count > 0
                      ? colorScheme.onPrimary
                      : colorScheme.onSurface,
                  fontSize: 12,
                  fontWeight: count > 0 ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        },
        todayBuilder: (context, date, _) {
          final count = _getCountForDay(date);
          final color = _getColorForDay(date, theme);
          return Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: colorScheme.primary,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                '${date.day}',
                style: TextStyle(
                  color: count > 0
                      ? colorScheme.onPrimary
                      : colorScheme.onSurface,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

