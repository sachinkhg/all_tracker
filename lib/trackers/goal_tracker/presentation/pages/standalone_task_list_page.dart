/*
  purpose:
    - Presentation layer page that displays standalone tasks (tasks without milestone/goal).
    - Responsible for wiring the TaskCubit for this screen, rendering loading/error/empty states,
      and providing user actions (create, edit, filter, delete).
    - Keeps UI concerns only — all business logic lives in TaskCubit / domain use cases.
*/

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/task.dart';
import '../../core/injection.dart'; // factory that wires everything (createTaskCubit)
import '../bloc/task_cubit.dart';
import '../bloc/task_state.dart';
import '../../features/task_import_export.dart';
import '../../../../widgets/primary_app_bar.dart';
import 'package:all_tracker/trackers/goal_tracker/core/app_icons.dart';
import '../widgets/task_list_item.dart';
import '../../../../widgets/loading_view.dart';
import '../../../../widgets/error_view.dart';
import '../widgets/standalone_task_form_bottom_sheet.dart';
import '../widgets/view_field_bottom_sheet.dart';
import '../widgets/filter_group_bottom_sheet.dart';
import '../../../../widgets/bottom_sheet_helpers.dart';
import 'package:all_tracker/core/services/view_entity_type.dart';
import '../../../../core/design_tokens.dart';

class StandaloneTaskListPage extends StatelessWidget {
  const StandaloneTaskListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = createTaskCubit();
        cubit.loadTasks().then((_) {
          // No need to apply filter here - filtering is done in the widget
        });
        return cubit;
      },
      child: const StandaloneTaskListPageView(),
    );
  }
}

class StandaloneTaskListPageView extends StatelessWidget {
  const StandaloneTaskListPageView({super.key});

  @override
  Widget build(BuildContext context) {
    // Obtain cubit & state here once so nested closures don't call context.read
    final cubit = context.read<TaskCubit>();
    final state = cubit.state;
    final Map<String, bool> initialVisible =
        state is TasksLoaded ? state.visibleFields ?? <String, bool>{} : <String, bool>{};

    return Scaffold(
      appBar: PrimaryAppBar(
        title: 'Task Tracker',
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
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            BlocBuilder<TaskCubit, TaskState>(
              builder: (context, state) {
                if (state is TasksLoaded) {
                  // Get all tasks and apply filters except hideCompleted
                  // This ensures dashboard always shows completed tasks
                  final allUnfilteredTasks = cubit.allTasks;
                  final filteredTasksForDashboard = _getTasksForDashboard(allUnfilteredTasks, cubit);
                  return TaskDashboard(
                    tasks: filteredTasksForDashboard,
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            const SizedBox(height: 12),
            Expanded(
              child: BlocBuilder<TaskCubit, TaskState>(
                builder: (context, state) {
                  if (state is TasksLoading) {
                    return const LoadingView();
                  }

                  if (state is TasksLoaded) {
                    // Show all tasks (both standalone and from goal tracker)
                    final allTasks = state.tasks;
                    final visible = state.visibleFields ?? <String, bool>{};

                    final bool filterActive = cubit.hasActiveFilters;
                    final String filterSummary = cubit.filterSummary;

                    if (allTasks.isEmpty) {
                      return _EmptyTasks(
                        filterActive: filterActive,
                        onClear: () {
                          cubit.clearFilters();
                        },
                      );
                    }

                    return _TasksBody(
                      tasks: allTasks,
                      visibleFields: visible,
                      filterActive: filterActive,
                      filterSummary: filterSummary,
                      onEdit: (ctx, task) => _onEditTask(ctx, task, cubit),
                      onSwipeComplete: (ctx, task) => _onSwipeComplete(ctx, task, cubit),
                      onEditFilters: () => _editFilters(context, cubit),
                      onClearFilters: () {
                        cubit.clearFilters();
                      },
                    );
                  }

                  if (state is TasksError) {
                    return ErrorView(
                      message: state.message,
                      onRetry: () => cubit.loadTasks(),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: BlocBuilder<TaskCubit, TaskState>(
        builder: (context, state) {
          final filterActive = cubit.hasActiveFilters;
          return _ActionsFab(
            initialVisibleFields: initialVisible,
            filterActive: filterActive,
            onView: () async {
              final currentState = cubit.state;
              final Map<String, bool>? initial =
                  currentState is TasksLoaded ? currentState.visibleFields : <String, bool>{};
              final String? initialViewType =
                  currentState is TasksLoaded ? currentState.viewType : 'list';

              final result = await showAppBottomSheet<Map<String, dynamic>?>(
                context,
                ViewFieldsBottomSheet(
                  entity: ViewEntityType.task,
                  initial: initial,
                  initialViewType: initialViewType,
                  isStandalone: true, // Hide milestone/goal fields for standalone tasks
                ),
              );
              if (result == null) return;
              
              // Extract fields, viewType, and saveView preference from result
              final fields = result['fields'] as Map<String, bool>;
              final saveView = result['saveView'] as bool;
              final viewType = result['viewType'] as String? ?? 'list';
              
              // Get the ViewPreferencesService from cubit
              final viewPrefsService = cubit.viewPreferencesService;
              
              // Save or clear preferences based on checkbox state
              if (saveView) {
                await viewPrefsService.saveViewPreferences(ViewEntityType.task, fields);
                await viewPrefsService.saveViewType(ViewEntityType.task, viewType);
              } else {
                await viewPrefsService.clearViewPreferences(ViewEntityType.task);
                await viewPrefsService.clearViewType(ViewEntityType.task);
              }
              
              // Apply the fields and view type to the cubit to update UI
              cubit.setVisibleFields(fields);
              cubit.setViewType(viewType);
            },
            onFilter: () async {
              await _editFilters(context, cubit);
            },
            onAdd: () => _onCreateTask(context, cubit),
            onMore: () => _showActionsSheet(context, cubit),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  /// Get tasks for dashboard - applies all filters except hideCompleted
  /// This ensures completed tasks are always shown in dashboard statistics
  List<Task> _getTasksForDashboard(List<Task> allTasks, TaskCubit cubit) {
    final now = DateTime.now();
    
    return allTasks.where((t) {
      // Apply milestone filter (if any)
      if (cubit.currentMilestoneIdFilter != null &&
          cubit.currentMilestoneIdFilter!.isNotEmpty) {
        if (t.milestoneId == null || t.milestoneId != cubit.currentMilestoneIdFilter) return false;
      }

      // Apply goal filter (if any)
      if (cubit.currentGoalIdFilter != null && cubit.currentGoalIdFilter!.isNotEmpty) {
        if (t.goalId == null || t.goalId != cubit.currentGoalIdFilter) return false;
      }

      // Apply status filter (if any)
      if (cubit.currentStatusFilter != null && cubit.currentStatusFilter!.isNotEmpty) {
        if (t.status != cubit.currentStatusFilter) return false;
      }

      // Apply target date filter (if any)
      if (cubit.currentTargetDateFilter != null) {
        final tf = cubit.currentTargetDateFilter!;
        final td = t.targetDate;
        if (td == null) return false;

        final today = DateTime(now.year, now.month, now.day);
        final targetDay = DateTime(td.year, td.month, td.day);

        switch (tf) {
          case 'Today':
            if (targetDay != today) return false;
            break;
          case 'Tomorrow':
            final tomorrow = today.add(const Duration(days: 1));
            if (targetDay != tomorrow) return false;
            break;
          case 'This Week':
            final startOfWeek = today.subtract(Duration(days: now.weekday - 1));
            final endOfWeek = startOfWeek.add(const Duration(days: 6));
            if (targetDay.isBefore(startOfWeek) || targetDay.isAfter(endOfWeek)) return false;
            break;
          case 'Next Week':
            final nextWeekStart = today.add(Duration(days: 8 - now.weekday));
            final nextWeekEnd = nextWeekStart.add(const Duration(days: 6));
            if (targetDay.isBefore(nextWeekStart) || targetDay.isAfter(nextWeekEnd)) return false;
            break;
          case 'This Month':
            if (!(td.year == now.year && td.month == now.month)) return false;
            break;
          case 'Next Month':
            final nextMonth = DateTime(now.year, now.month + 1);
            if (!(td.year == nextMonth.year && td.month == nextMonth.month)) return false;
            break;
          case 'This Year':
            if (td.year != now.year) return false;
            break;
          case 'Next Year':
            if (td.year != now.year + 1) return false;
            break;
        }
      }

      // NOTE: We intentionally do NOT apply hideCompleted filter here
      // so completed tasks are always shown in dashboard
      return true;
    }).toList();
  }

  Future<void> _editFilters(BuildContext context, TaskCubit cubit) async {
    // Check if there are existing saved filters
    final savedFilters = cubit.filterPreferencesService.loadFilterPreferences(FilterEntityType.task);
    final hasSavedFilters = savedFilters != null && 
        (savedFilters['status'] != null || savedFilters['targetDate'] != null);
    
    // Check if there are existing saved sort preferences
    final savedSort = cubit.sortPreferencesService.loadSortPreferences(SortEntityType.task);
    final hasSavedSort = savedSort != null;
    
    final result = await showAppBottomSheet<Map<String, dynamic>?>(
      context,
      FilterGroupBottomSheet(
        entity: FilterEntityType.task,
        initialContext: null, // No milestone filter for standalone tasks
        initialGoalId: null, // No goal filter for standalone tasks
        initialDateFilter: cubit.currentTargetDateFilter,
        initialStatus: cubit.currentStatusFilter,
        milestoneOptions: [], // No milestone options for standalone tasks
        goalOptions: [], // No goal options for standalone tasks
        milestoneToGoalMap: {}, // Empty map
        initialSaveFilter: hasSavedFilters,
        initialSaveSort: hasSavedSort,
        initialSortOrder: cubit.currentSortOrder,
        initialHideCompleted: cubit.hideCompleted,
        isStandalone: true, // Hide milestone/goal filters for standalone tasks
      ),
    );

    if (result == null) return;

    if (result.containsKey('status') || 
        result.containsKey('targetDate') ||
        result.containsKey('hideCompleted')) {
      final saveFilter = result['saveFilter'] as bool? ?? false;
      final hideCompleted = result['hideCompleted'] as bool? ?? true;
      
      // Save or clear filter preferences based on checkbox state
      if (saveFilter) {
        final filters = <String, String?>{
          'milestoneId': null, // No milestone filter for task tracker
          'goalId': null, // No goal filter for task tracker
          'status': result['status'] as String?,
          'targetDate': result['targetDate'] as String?,
        };
        await cubit.filterPreferencesService.saveFilterPreferences(FilterEntityType.task, filters);
      } else {
        await cubit.filterPreferencesService.clearFilterPreferences(FilterEntityType.task);
      }
      
      cubit.applyFilter(
        milestoneId: null, // No milestone filter for task tracker
        goalId: null, // No goal filter for task tracker
        status: result['status'] as String?,
        targetDateFilter: result['targetDate'] as String?,
        hideCompleted: hideCompleted,
      );
    }

    if (result.containsKey('sortOrder') || result.containsKey('hideCompleted')) {
      final sortOrder = result['sortOrder'] as String? ?? 'asc';
      final hideCompleted = result['hideCompleted'] as bool? ?? true;
      final saveSort = result['saveSort'] as bool? ?? false;
      
      // Save or clear sort preferences based on checkbox state
      if (saveSort) {
        final sortSettings = <String, dynamic>{
          'sortOrder': sortOrder,
          'hideCompleted': hideCompleted,
        };
        await cubit.sortPreferencesService.saveSortPreferences(SortEntityType.task, sortSettings);
      } else {
        await cubit.sortPreferencesService.clearSortPreferences(SortEntityType.task);
      }
      
      // Apply sorting
      cubit.applySorting(sortOrder: sortOrder, hideCompleted: hideCompleted);
    }
  }

  void _onCreateTask(BuildContext context, TaskCubit cubit) {
    StandaloneTaskFormBottomSheet.show(
      context,
      title: 'Create Task',
      milestoneOptions: [], // No milestone options needed for standalone tasks
      milestoneGoalMap: {}, // Empty map
      onSubmit: (name, targetDate, milestoneId, status) async {
        try {
          await cubit.addTask(
            name: name,
            targetDate: targetDate,
            milestoneId: milestoneId, // Can be null for standalone tasks
            status: status,
          );
          
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Task created successfully')),
          );
        } catch (e) {
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error creating task: ${e.toString()}')),
          );
        }
      },
    );
  }

  void _onEditTask(BuildContext context, Task task, TaskCubit cubit) {
    StandaloneTaskFormBottomSheet.show(
      context,
      title: 'Edit Task',
      initialName: task.name,
      initialTargetDate: task.targetDate,
      initialMilestoneId: task.milestoneId,
      initialStatus: task.status,
      milestoneOptions: [], // No milestone options needed for standalone tasks
      milestoneGoalMap: {}, // Empty map
      onSubmit: (name, targetDate, milestoneId, status) async {
        try {
          await cubit.editTask(
            id: task.id,
            name: name,
            targetDate: targetDate,
            milestoneId: milestoneId, // Can be null for standalone tasks
            status: status,
          );
          
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Task updated successfully')),
          );
        } catch (e) {
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating task: ${e.toString()}')),
          );
        }
      },
      onDelete: () async {
        await cubit.removeTask(task.id);
        
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task deleted')),
        );
      },
    );
  }

  void _onSwipeComplete(BuildContext context, Task task, TaskCubit cubit) async {
    // Only mark as complete if not already complete
    if (task.status == 'Complete') return;

    try {
      await cubit.editTask(
        id: task.id,
        name: task.name,
        targetDate: task.targetDate,
        milestoneId: task.milestoneId, // Preserve existing milestoneId (can be null)
        status: 'Complete',
      );
      
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task marked as complete')),
      );
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error marking task as complete: ${e.toString()}')),
      );
    }
  }

  void _showActionsSheet(BuildContext context, TaskCubit cubit) {
    final sheet = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 12),
        ListTile(
          leading: const Icon(Icons.add),
          title: const Text('Add Task'),
          onTap: () {
            Navigator.of(context).pop();
            _onCreateTask(context, cubit);
          },
        ),
        ListTile(
          leading: const Icon(Icons.file_download),
          title: const Text('Export'),
          onTap: () async {
            Navigator.of(context).pop();
            final state = cubit.state;
            final allTasks = state is TasksLoaded ? state.tasks : <Task>[];
            // Export all tasks (both standalone and from goal tracker)
            final path = await exportTasksToXlsx(context, allTasks);
            if (path != null) {
              // ignore: use_build_context_synchronously
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('File exported')),
              );
            }
          },
        ),
        ListTile(
          leading: const Icon(Icons.file_upload),
          title: const Text('Import'),
          onTap: () {
            Navigator.of(context).pop();
            importTasksFromXlsx(context);
          },
        ),
        ListTile(
          leading: const Icon(Icons.download),
          title: const Text('Download Template'),
          onTap: () async {
            Navigator.of(context).pop();
            final path = await downloadTasksTemplate(context);
            if (path != null) {
              // ignore: use_build_context_synchronously
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Template downloaded')),
              );
            }
          },
        ),
        const SizedBox(height: 8),
      ],
    );

    showAppBottomSheet<void>(context, sheet);
  }
}

class _ActionsFab extends StatelessWidget {
  const _ActionsFab({
    required this.onView,
    required this.onFilter,
    required this.onAdd,
    required this.onMore,
    this.initialVisibleFields = const <String, bool>{},
    this.filterActive = false,
  });

  final Future<void> Function() onView;
  final Future<void> Function() onFilter;
  final VoidCallback onAdd;
  final VoidCallback onMore;
  final Map<String, bool> initialVisibleFields;
  final bool filterActive;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton.small(
              heroTag: 'viewFab',
              tooltip: 'Change View',
              backgroundColor: cs.surface.withValues(alpha: 0.85),
              onPressed: () => onView(),
              child: const Icon(Icons.remove_red_eye),
            ),
            const SizedBox(width: 8),
            FloatingActionButton.small(
              heroTag: 'filterFab',
              tooltip: 'Filter',
              backgroundColor: cs.surface.withValues(alpha: 0.85),
              onPressed: () => onFilter(),
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
                          color: cs.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: cs.surface.withValues(alpha: 0.85),
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
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton.small(
              heroTag: 'addTaskFab',
              tooltip: 'Add Task',
              backgroundColor: cs.surface.withValues(alpha: 0.85),
              onPressed: onAdd,
              child: const Icon(Icons.add),
            ),
            const SizedBox(width: 12),
            FloatingActionButton.small(
              heroTag: 'moreFab',
              tooltip: 'More actions',
              backgroundColor: cs.surface.withValues(alpha: 0.85),
              onPressed: onMore,
              child: const Icon(Icons.more_vert),
            ),
          ],
        ),
      ],
    );
  }
}

class _EmptyTasks extends StatelessWidget {
  final bool filterActive;
  final VoidCallback onClear;

  const _EmptyTasks({
    required this.filterActive,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(AppIcons.task, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(
            filterActive ? 'No tasks match your filters' : 'No tasks yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            filterActive
                ? 'Try adjusting your filters'
                : 'Tap the + button to create your first task',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          if (filterActive) ...[
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: onClear,
              child: const Text('Clear Filters'),
            ),
          ],
        ],
      ),
    );
  }
}

class _TasksBody extends StatelessWidget {
  final List<Task> tasks;
  final Map<String, bool> visibleFields;
  final bool filterActive;
  final String filterSummary;
  final Function(BuildContext, Task) onEdit;
  final Function(BuildContext, Task) onSwipeComplete;
  final VoidCallback onEditFilters;
  final VoidCallback onClearFilters;

  const _TasksBody({
    required this.tasks,
    required this.visibleFields,
    required this.filterActive,
    required this.filterSummary,
    required this.onEdit,
    required this.onSwipeComplete,
    required this.onEditFilters,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return TaskListItem(
                id: task.id,
                title: task.name,
                targetDate: task.targetDate,
                status: task.status,
                milestoneName: null, // Hide milestone/goal references in task tracker
                goalName: null, // Hide milestone/goal references in task tracker
                onEdit: () => onEdit(context, task),
                onSwipeComplete: () => onSwipeComplete(context, task),
                visibleFields: visibleFields,
                filterActive: filterActive,
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Mini dashboard showing task statistics based on current filters
class TaskDashboard extends StatelessWidget {
  final List<Task> tasks;

  const TaskDashboard({
    super.key,
    required this.tasks,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    // Calculate statistics from filtered tasks
    final total = tasks.length;
    final completed = tasks.where((t) => t.status == 'Complete').length;
    final inProgress = tasks.where((t) => t.status == 'In Progress').length;
    final toDo = total - completed - inProgress;
    final progress = total > 0 ? completed / total : 0.0;

    return Card(
      elevation: AppElevations.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header row with total
            Row(
              children: [
                Icon(AppIcons.task, color: cs.tertiary, size: 24),
                const SizedBox(width: AppSpacing.s),
                Text(
                  'Tasks Overview',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
                const Spacer(),
                Text(
                  '$total Total',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: cs.tertiary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.m),
            // Status chips in a row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _MiniStatusChip(
                  label: 'To Do',
                  count: toDo,
                ),
                _MiniStatusChip(
                  label: 'In Progress',
                  count: inProgress,
                ),
                _MiniStatusChip(
                  label: 'Complete',
                  count: completed,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.m),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: cs.tertiaryContainer.withValues(alpha: 0.3),
                valueColor: AlwaysStoppedAnimation<Color>(cs.tertiary),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 4),
            // Progress percentage
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Progress',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                ),
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: cs.tertiary,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact status chip for mini dashboard
class _MiniStatusChip extends StatelessWidget {
  final String label;
  final int count;

  const _MiniStatusChip({
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Map status label to ColorScheme tokens
    Color background;
    Color foreground;
    switch (label) {
      case 'Complete':
        background = cs.tertiaryContainer;
        foreground = cs.onTertiaryContainer;
        break;
      case 'In Progress':
        background = cs.primaryContainer;
        foreground = cs.onPrimaryContainer;
        break;
      case 'To Do':
      default:
        background = cs.secondaryContainer;
        foreground = cs.onSecondaryContainer;
        break;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 10,
              ),
        ),
      ],
    );
  }
}
