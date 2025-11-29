import 'package:flutter/material.dart';
import 'package:all_tracker/trackers/goal_tracker/core/app_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../domain/entities/habit.dart';
import '../../domain/entities/habit_completion.dart';
import '../bloc/habit_completion_cubit.dart';
import '../bloc/habit_completion_state.dart';

/// Calendar view widget for habit completion tracking.
///
/// This widget displays a monthly calendar showing habit completions
/// with the ability to toggle completions by tapping dates.
/// It shows streaks, completion rates, and expected vs actual completions.
class HabitCalendarView extends StatefulWidget {
  final Habit habit;
  final HabitCompletionCubit completionCubit;

  const HabitCalendarView({
    super.key,
    required this.habit,
    required this.completionCubit,
  });

  @override
  State<HabitCalendarView> createState() => _HabitCalendarViewState();
}

class _HabitCalendarViewState extends State<HabitCalendarView> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<HabitCompletion> _completions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCompletions();
  }

  Future<void> _loadCompletions() async {
    setState(() => _isLoading = true);
    
    // Load completions for the current month
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    
    await widget.completionCubit.loadCompletionsByDateRange(
      widget.habit.id,
      startOfMonth,
      endOfMonth,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<HabitCompletionCubit, HabitCompletionState>(
      bloc: widget.completionCubit,
      listener: (context, state) {
        if (state is CompletionsLoaded) {
          setState(() {
            _completions = state.completions;
            _isLoading = false;
          });
        } else if (state is CompletionsError) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Fallback to scroll if vertical space is too tight to avoid RenderFlex overflow
          // If constraints are unbounded (e.g., inside SingleChildScrollView), avoid Expanded.
          final bool heightIsBounded = constraints.hasBoundedHeight && constraints.maxHeight.isFinite;
          final bool tightHeight = heightIsBounded && constraints.maxHeight < 380;

          final Widget calendarOrLoader = _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildCalendar();

          final column = Column(
            children: [
              _buildStatisticsHeader(),
              const SizedBox(height: 16),
              if (!heightIsBounded || tightHeight)
                calendarOrLoader
              else
                Expanded(child: calendarOrLoader),
            ],
          );

          return (!heightIsBounded || tightHeight)
              ? SingleChildScrollView(child: column)
              : column;
        },
      ),
    );
  }

  Widget _buildStatisticsHeader() {
    final theme = Theme.of(context);
    final currentStreak = widget.completionCubit.getCurrentStreak(widget.habit.id);
    final totalCompletions = widget.completionCubit.getCompletionCount(widget.habit.id);
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    final monthCompletions = widget.completionCubit.getCompletionCountInRange(
      widget.habit.id,
      startOfMonth,
      endOfMonth,
    );
    
    // Calculate expected completions for the month (simplified)
    final expectedCompletions = _calculateExpectedCompletions(startOfMonth, endOfMonth);
    final habitWeight = widget.habit.targetCompletions ?? 1;
    final completionRate = habitWeight > 0 
        ? (totalCompletions / habitWeight * 100)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                AppIcons.habit,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Statistics',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Current Streak',
                  '$currentStreak days',
                  Icons.local_fire_department,
                  theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'This Month',
                  '$monthCompletions/$expectedCompletions',
                  Icons.calendar_month,
                  theme.colorScheme.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total',
                  '$totalCompletions',
                  Icons.check_circle,
                  theme.colorScheme.tertiary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Rate',
                  '${completionRate.toStringAsFixed(0)}%',
                  Icons.trending_up,
                  _getRateColor(completionRate, theme),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    final theme = Theme.of(context);
    
    return TableCalendar<HabitCompletion>(
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
          _toggleCompletion(selectedDay);
        }
      },
      onPageChanged: (focusedDay) {
        setState(() {
          _focusedDay = focusedDay;
        });
        _loadCompletionsForMonth(focusedDay);
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
      ),
      headerStyle: HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        titleTextStyle: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ) ?? const TextStyle(fontWeight: FontWeight.w600),
        leftChevronIcon: Icon(
          Icons.chevron_left,
          color: theme.colorScheme.primary,
        ),
        rightChevronIcon: Icon(
          Icons.chevron_right,
          color: theme.colorScheme.primary,
        ),
      ),
      eventLoader: (day) {
        return _getCompletionsForDay(day);
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
          final isCompleted = _isCompletedOnDay(day);
          final isToday = isSameDay(day, DateTime.now());
          final isSelected = isSameDay(day, _selectedDay);
          
          return Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isCompleted
                  ? theme.colorScheme.primary.withValues(alpha: 0.8)
                  : isSelected
                      ? theme.colorScheme.primary.withValues(alpha: 0.3)
                      : null,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${day.day}',
                style: TextStyle(
                  color: isCompleted
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

  List<HabitCompletion> _getCompletionsForDay(DateTime day) {
    return _completions.where((completion) {
      return completion.completionDate.year == day.year &&
             completion.completionDate.month == day.month &&
             completion.completionDate.day == day.day;
    }).toList();
  }

  bool _isCompletedOnDay(DateTime day) {
    return _getCompletionsForDay(day).isNotEmpty;
  }

  void _toggleCompletion(DateTime day) {
    widget.completionCubit.toggleCompletionForDate(widget.habit.id, day);
  }

  Future<void> _loadCompletionsForMonth(DateTime month) async {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0);
    
    await widget.completionCubit.loadCompletionsByDateRange(
      widget.habit.id,
      startOfMonth,
      endOfMonth,
    );
  }

  int _calculateExpectedCompletions(DateTime start, DateTime end) {
    // Simplified calculation - assumes daily habits
    // In a real implementation, you'd parse the RRULE to calculate expected days
    if (widget.habit.rrule == 'FREQ=DAILY') {
      return end.difference(start).inDays + 1;
    }
    // For other frequencies, return a rough estimate
    return (end.difference(start).inDays / 7).ceil();
  }

  Color _getRateColor(double rate, ThemeData theme) {
    if (rate >= 80) return Colors.green;
    if (rate >= 60) return Colors.orange;
    return Colors.red;
  }
}
