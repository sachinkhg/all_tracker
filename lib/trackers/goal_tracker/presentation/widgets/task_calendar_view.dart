import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../domain/entities/task.dart';
import 'task_list_item.dart';

/// Calendar view widget for task display.
///
/// This widget displays a monthly calendar showing tasks
/// organized by their target dates.
class TaskCalendarView extends StatefulWidget {
  final List<Task> tasks;
  final Function(BuildContext, Task) onEdit;
  final Function(BuildContext, Task)? onSwipeComplete;
  final Map<String, String> milestoneNameById;
  final Map<String, String> goalNameById;
  final Map<String, bool>? visibleFields;
  final bool filterActive;

  const TaskCalendarView({
    super.key,
    required this.tasks,
    required this.onEdit,
    this.onSwipeComplete,
    required this.milestoneNameById,
    required this.goalNameById,
    this.visibleFields,
    this.filterActive = false,
  });

  @override
  State<TaskCalendarView> createState() => _TaskCalendarViewState();
}

class _TaskCalendarViewState extends State<TaskCalendarView> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now(); // Default to today to show tasks for current day

  List<Task> _getTasksForDay(DateTime day) {
    return widget.tasks.where((task) {
      if (task.targetDate == null) return false;
      final taskDate = task.targetDate!;
      return taskDate.year == day.year &&
          taskDate.month == day.month &&
          taskDate.day == day.day;
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
              // When tasks are shown, give calendar more space but constrain it
              Expanded(
                child: calendarOrLoader,
              ),
            if (_selectedDay != null) ...[
              // Constrain the tasks section to a smaller maximum height (25% of screen)
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: heightIsBounded 
                      ? (constraints.maxHeight * 0.50)
                      : 180,
                ),
                child: _buildSelectedDayTasks(theme),
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
    return TableCalendar<Task>(
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
        // Reduce cell padding to make calendar more compact
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
        // Reduce header padding
        headerPadding: const EdgeInsets.symmetric(vertical: 8),
        leftChevronPadding: EdgeInsets.zero,
        rightChevronPadding: EdgeInsets.zero,
      ),
      eventLoader: (day) {
        return _getTasksForDay(day);
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
          final tasksForDay = _getTasksForDay(day);
          final hasTasks = tasksForDay.isNotEmpty;
          final isToday = isSameDay(day, DateTime.now());
          final isSelected = isSameDay(day, _selectedDay);

          // Color based on task status
          Color? dayColor;
          if (hasTasks) {
            final hasComplete =
                tasksForDay.any((t) => t.status == 'Complete');
            final hasInProgress =
                tasksForDay.any((t) => t.status == 'In Progress');
            final hasToDo = tasksForDay.any((t) => t.status == 'To Do');

            if (hasComplete && !hasToDo && !hasInProgress) {
              dayColor = theme.colorScheme.tertiary.withValues(alpha: 0.3);
            } else if (hasInProgress) {
              dayColor = theme.colorScheme.primary.withValues(alpha: 0.3);
            } else if (hasToDo) {
              dayColor = theme.colorScheme.secondary.withValues(alpha: 0.3);
            }
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

  Widget _buildSelectedDayTasks(ThemeData theme) {
    if (_selectedDay == null) return const SizedBox.shrink();

    final tasksForDay = _getTasksForDay(_selectedDay!);

    if (tasksForDay.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'No tasks on ${_formatDate(_selectedDay!)}',
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
            'Tasks on ${_formatDate(_selectedDay!)}',
            style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          // Make the task list scrollable to handle overflow
          Expanded(
            child: ListView.builder(
              shrinkWrap: false,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: tasksForDay.length,
              itemBuilder: (context, index) {
                final task = tasksForDay[index];
                return TaskListItem(
                  id: task.id,
                  title: task.name,
                  targetDate: task.targetDate,
                  status: task.status,
                  milestoneName: task.milestoneId != null ? widget.milestoneNameById[task.milestoneId] : null,
                  goalName: task.goalId != null ? widget.goalNameById[task.goalId] : null,
                  onEdit: () => widget.onEdit(context, task),
                  onSwipeComplete: widget.onSwipeComplete != null
                      ? () => widget.onSwipeComplete!(context, task)
                      : null,
                  visibleFields: widget.visibleFields,
                  filterActive: widget.filterActive,
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

