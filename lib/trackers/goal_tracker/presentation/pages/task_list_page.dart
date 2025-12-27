/*
  purpose:
    - Presentation layer page that displays the list of Task entities and related actions.
    - Responsible for wiring the TaskCubit for this screen, rendering loading/error/empty states,
      and providing user actions (create, edit, filter, delete).
    - Keeps UI concerns only — all business logic lives in TaskCubit / domain use cases.
*/

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../domain/entities/task.dart';
import '../../data/models/goal_model.dart';
import '../../data/models/milestone_model.dart';
import '../../core/injection.dart'; // factory that wires everything (createTaskCubit)
import '../../core/constants.dart'; // for goalBoxName, milestoneBoxName
import 'package:all_tracker/core/services/view_entity_type.dart'; // for SortEntityType
import '../bloc/task_cubit.dart';
import '../bloc/task_state.dart';
import '../../features/task_import_export.dart';

// Shared component imports - adjust paths to your project
import '../../../../widgets/primary_app_bar.dart';
import 'package:all_tracker/trackers/goal_tracker/core/app_icons.dart';
import '../widgets/task_list_item.dart';
import '../../../../widgets/loading_view.dart';
import '../../../../widgets/error_view.dart';
import '../widgets/task_form_bottom_sheet.dart';
import '../widgets/view_field_bottom_sheet.dart';
import '../widgets/filter_group_bottom_sheet.dart';
import '../widgets/task_calendar_view.dart';
import '../../../../widgets/bottom_sheet_helpers.dart'; // centralized helper

class TaskListPage extends StatelessWidget {
  final String? goalId;
  final String? milestoneId;
  final String? targetDateFilter;
  
  const TaskListPage({super.key, this.goalId, this.milestoneId, this.targetDateFilter});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = createTaskCubit();
        cubit.loadTasks().then((_) {
          if (milestoneId != null || goalId != null || targetDateFilter != null) {
            cubit.applyFilter(
              milestoneId: milestoneId,
              goalId: goalId,
              targetDateFilter: targetDateFilter,
            );
          }
        });
        return cubit;
      },
      child: TaskListPageView(goalId: goalId, milestoneId: milestoneId, targetDateFilter: targetDateFilter),
    );
  }
}

class TaskListPageView extends StatelessWidget {
  final String? goalId;
  final String? milestoneId;
  final String? targetDateFilter;
  
  const TaskListPageView({super.key, this.goalId, this.milestoneId, this.targetDateFilter});

  @override
  Widget build(BuildContext context) {
    // Obtain cubit & state here once so nested closures don't call context.read
    final cubit = context.read<TaskCubit>();
    final state = cubit.state;
    final Map<String, bool> initialVisible =
        state is TasksLoaded ? state.visibleFields ?? <String, bool>{} : <String, bool>{};

    return Scaffold(
      appBar: PrimaryAppBar(
        title: 'Tasks',
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
            Expanded(
              child: BlocBuilder<TaskCubit, TaskState>(
                builder: (context, state) {
                  if (state is TasksLoading) {
                    return const LoadingView();
                  }

                  if (state is TasksLoaded) {
                    final tasks = state.tasks;
                    final visible = state.visibleFields ?? <String, bool>{};

                    // use the cubit captured from outer scope; do NOT call context.read here
                    final bool filterActive = cubit.hasActiveFilters;
                    final String filterSummary = cubit.filterSummary;

                    // Build maps for milestone and goal names
                    final Map<String, String> milestoneNameById = _getMilestoneNameById();
                    final Map<String, String> goalNameById = _getGoalNameById();

                    if (tasks.isEmpty) {
                      return _EmptyTasks(
                        filterActive: filterActive,
                        onClear: () {
                          cubit.clearFilters();
                        },
                      );
                    }

                    // Check view type - default to 'list' if not specified
                    final viewType = state.viewType;

                    if (viewType == 'calendar') {
                      return TaskCalendarView(
                        tasks: tasks,
                        onEdit: (ctx, task) => _onEditTask(ctx, task, cubit),
                        onSwipeComplete: (ctx, task) => _onSwipeComplete(ctx, task, cubit),
                        milestoneNameById: milestoneNameById,
                        goalNameById: goalNameById,
                        visibleFields: visible,
                        filterActive: filterActive,
                      );
                    } else {
                      return _TasksBody(
                        tasks: tasks,
                        visibleFields: visible,
                        filterActive: filterActive,
                        filterSummary: filterSummary,
                        milestoneNameById: milestoneNameById,
                        goalNameById: goalNameById,
                        onEdit: (ctx, task) => _onEditTask(ctx, task, cubit),
                        onSwipeComplete: (ctx, task) => _onSwipeComplete(ctx, task, cubit),
                        onEditFilters: () => _editFilters(context, cubit),
                        onClearFilters: () {
                          cubit.clearFilters();
                        },
                      );
                    }
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
              final String initialViewType =
                  currentState is TasksLoaded ? currentState.viewType : 'list';

              final result = await showAppBottomSheet<Map<String, dynamic>?>(
                context,
                ViewFieldsBottomSheet(
                  entity: ViewEntityType.task,
                  initial: initial,
                  initialViewType: initialViewType,
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

  /// Helper method to fetch milestones from Hive and format them for the dropdown
  /// Only returns non-completed milestones (actualValue < plannedValue)
  List<String> _getMilestoneOptions() {
    try {
      final box = Hive.box<MilestoneModel>(milestoneBoxName);
      final milestones = box.values.toList();
      
      // Filter out completed milestones (actualValue >= plannedValue)
      final nonCompletedMilestones = milestones.where((m) {
        if (m.plannedValue != null && m.actualValue != null) {
          return m.actualValue! < m.plannedValue!;
        }
        return true; // Include milestones without planned/actual values
      }).toList();
      
      // Format as "id::name" for the dropdown
      return nonCompletedMilestones.map((m) => '${m.id}::${m.name}').toList();
    } catch (e) {
      return [];
    }
  }

  /// Helper method to fetch goals from Hive and format them for the filter
  List<String> _getGoalOptions() {
    try {
      final box = Hive.box<GoalModel>(goalBoxName);
      final goals = box.values.toList();
      
      // Format as "id::name" for the filter
      return goals.map((g) => '${g.id}::${g.name}').toList();
    } catch (e) {
      return [];
    }
  }

  /// Helper to build a map from milestoneId to milestoneName for display purposes
  Map<String, String> _getMilestoneNameById() {
    try {
      final box = Hive.box<MilestoneModel>(milestoneBoxName);
      final milestones = box.values.toList();
      final map = <String, String>{};
      for (final m in milestones) {
        map[m.id] = m.name;
      }
      return map;
    } catch (e) {
      return {};
    }
  }

  /// Helper to build a map from goalId to goalName for display purposes
  Map<String, String> _getGoalNameById() {
    try {
      final box = Hive.box<GoalModel>(goalBoxName);
      final goals = box.values.toList();
      final map = <String, String>{};
      for (final g in goals) {
        map[g.id] = g.name;
      }
      return map;
    } catch (e) {
      return {};
    }
  }

  /// Helper to build milestone-to-goal mapping for the form (milestoneId -> goalName)
  /// Only includes non-completed milestones (actualValue < plannedValue)
  Map<String, String> _getMilestoneGoalMap() {
    try {
      final milestoneBox = Hive.box<MilestoneModel>(milestoneBoxName);
      final goalBox = Hive.box<GoalModel>(goalBoxName);
      final milestones = milestoneBox.values.toList();
      final goalMap = <String, String>{};
      
      // Filter out completed milestones (actualValue >= plannedValue)
      final nonCompletedMilestones = milestones.where((m) {
        if (m.plannedValue != null && m.actualValue != null) {
          return m.actualValue! < m.plannedValue!;
        }
        return true; // Include milestones without planned/actual values
      }).toList();
      
      for (final m in nonCompletedMilestones) {
        final goal = goalBox.get(m.goalId);
        if (goal != null) {
          goalMap[m.id] = goal.name;
        }
      }
      return goalMap;
    } catch (e) {
      return {};
    }
  }

  /// Helper to build milestone-to-goalId mapping for filtering (milestoneId -> goalId)
  Map<String, String> _getMilestoneToGoalIdMap() {
    try {
      final milestoneBox = Hive.box<MilestoneModel>(milestoneBoxName);
      final milestones = milestoneBox.values.toList();
      final map = <String, String>{};
      
      for (final m in milestones) {
        map[m.id] = m.goalId;
      }
      return map;
    } catch (e) {
      return {};
    }
  }

  Future<void> _editFilters(BuildContext context, TaskCubit cubit) async {
    // Check if there are existing saved filters
    final savedFilters = cubit.filterPreferencesService.loadFilterPreferences(FilterEntityType.task);
    final hasSavedFilters = savedFilters != null && 
        (savedFilters['milestoneId'] != null || savedFilters['goalId'] != null || 
         savedFilters['status'] != null || savedFilters['targetDate'] != null);
    
    // Check if there are existing saved sort preferences
    final savedSort = cubit.sortPreferencesService.loadSortPreferences(SortEntityType.task);
    final hasSavedSort = savedSort != null;
    
    final result = await showAppBottomSheet<Map<String, dynamic>?>(
      context,
      FilterGroupBottomSheet(
        entity: FilterEntityType.task,
        initialContext: cubit.currentMilestoneIdFilter,
        initialGoalId: cubit.currentGoalIdFilter,
        initialDateFilter: cubit.currentTargetDateFilter,
        initialStatus: cubit.currentStatusFilter,
        milestoneOptions: _getMilestoneOptions(),
        goalOptions: _getGoalOptions(),
        milestoneToGoalMap: _getMilestoneToGoalIdMap(),
        initialSaveFilter: hasSavedFilters,
        initialSaveSort: hasSavedSort,
        initialSortOrder: cubit.currentSortOrder,
        initialHideCompleted: cubit.hideCompleted,
      ),
    );

    if (result == null) return;

    if (result.containsKey('milestoneId') || 
        result.containsKey('goalId') || 
        result.containsKey('status') || 
        result.containsKey('targetDate') ||
        result.containsKey('hideCompleted')) {
      final saveFilter = result['saveFilter'] as bool? ?? false;
      final hideCompleted = result['hideCompleted'] as bool? ?? true;
      
      // Save or clear filter preferences based on checkbox state
      if (saveFilter) {
        final filters = <String, String?>{
          'milestoneId': result['milestoneId'] as String?,
          'goalId': result['goalId'] as String?,
          'status': result['status'] as String?,
          'targetDate': result['targetDate'] as String?,
        };
        await cubit.filterPreferencesService.saveFilterPreferences(FilterEntityType.task, filters);
      } else {
        await cubit.filterPreferencesService.clearFilterPreferences(FilterEntityType.task);
      }
      
      cubit.applyFilter(
        milestoneId: result['milestoneId'] as String?,
        goalId: result['goalId'] as String?,
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
    TaskFormBottomSheet.show(
      context,
      title: 'Create Task',
      milestoneOptions: _getMilestoneOptions(),
      milestoneGoalMap: _getMilestoneGoalMap(),
      onSubmit: (name, targetDate, milestoneId, status) async {
        try {
          await cubit.addTask(
            name: name,
            targetDate: targetDate,
            milestoneId: milestoneId,
            status: status,
          );
          
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Task created successfully')),
          );
        } on MilestoneNotFoundException catch (e) {
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        } on InvalidMilestoneException catch (e) {
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
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
    TaskFormBottomSheet.show(
      context,
      title: 'Edit Task',
      initialName: task.name,
      initialTargetDate: task.targetDate,
      initialMilestoneId: task.milestoneId,
      initialStatus: task.status,
      milestoneOptions: _getMilestoneOptions(),
      milestoneGoalMap: _getMilestoneGoalMap(),
      onSubmit: (name, targetDate, milestoneId, status) async {
        try {
          await cubit.editTask(
            id: task.id,
            name: name,
            targetDate: targetDate,
            milestoneId: milestoneId,
            status: status,
          );
          
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Task updated successfully')),
          );
        } on MilestoneNotFoundException catch (e) {
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        } on InvalidMilestoneException catch (e) {
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
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
        milestoneId: task.milestoneId,
        status: 'Complete',
      );
      
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task marked as complete')),
      );
    } on MilestoneNotFoundException catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } on InvalidMilestoneException catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
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
            final tasks = state is TasksLoaded ? state.tasks : <Task>[];
            final path = await exportTasksToXlsx(context, tasks);
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
  final Map<String, String> milestoneNameById;
  final Map<String, String> goalNameById;
  final Function(BuildContext, Task) onEdit;
  final Function(BuildContext, Task) onSwipeComplete;
  final VoidCallback onEditFilters;
  final VoidCallback onClearFilters;

  const _TasksBody({
    required this.tasks,
    required this.visibleFields,
    required this.filterActive,
    required this.filterSummary,
    required this.milestoneNameById,
    required this.goalNameById,
    required this.onEdit,
    required this.onSwipeComplete,
    required this.onEditFilters,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter header removed - filter icon dot indicator shows filter is active
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
                milestoneName: task.milestoneId != null ? milestoneNameById[task.milestoneId] : null,
                goalName: task.goalId != null ? goalNameById[task.goalId] : null,
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
