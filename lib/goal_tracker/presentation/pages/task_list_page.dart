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
import '../bloc/task_cubit.dart';
import '../bloc/task_state.dart';
import '../../features/task_import_export.dart';
import 'goal_list_page.dart';
import 'milestone_list_page.dart';

// Shared component imports - adjust paths to your project
import '../../../widgets/primary_app_bar.dart';
import '../widgets/task_list_item.dart';
import '../../../widgets/loading_view.dart';
import '../../../widgets/error_view.dart';
import '../widgets/task_form_bottom_sheet.dart';
import '../widgets/view_field_bottom_sheet.dart';
import '../widgets/filter_group_bottom_sheet.dart';
import '../../../widgets/bottom_sheet_helpers.dart'; // centralized helper

class TaskListPage extends StatelessWidget {
  const TaskListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => createTaskCubit()..loadTasks(),
      child: const TaskListPageView(),
    );
  }
}

class TaskListPageView extends StatelessWidget {
  const TaskListPageView({super.key});

  @override
  Widget build(BuildContext context) {
    // Obtain cubit & state here once so nested closures don't call context.read
    final cubit = context.read<TaskCubit>();
    final state = cubit.state;
    final Map<String, bool> initialVisible =
        state is TasksLoaded ? state.visibleFields ?? <String, bool>{} : <String, bool>{};

    return Scaffold(
      appBar: const PrimaryAppBar(title: 'Tasks'),
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

                    return _TasksBody(
                      tasks: tasks,
                      visibleFields: visible,
                      filterActive: filterActive,
                      filterSummary: filterSummary,
                      milestoneNameById: milestoneNameById,
                      goalNameById: goalNameById,
                      onEdit: (ctx, task) => _onEditTask(ctx, task, cubit),
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
      floatingActionButton: _ActionsFab(
        initialVisibleFields: initialVisible,
        onView: () async {
          final currentState = cubit.state;
          final Map<String, bool>? initial =
              currentState is TasksLoaded ? currentState.visibleFields : <String, bool>{};

          final result = await showAppBottomSheet<Map<String, dynamic>?>(
            context,
            ViewFieldsBottomSheet(entity: ViewEntityType.task, initial: initial),
          );
          if (result == null) return;
          
          // Extract fields and saveView preference from result
          final fields = result['fields'] as Map<String, bool>;
          final saveView = result['saveView'] as bool;
          
          // Get the ViewPreferencesService from cubit
          final viewPrefsService = cubit.viewPreferencesService;
          
          // Save or clear preferences based on checkbox state
          if (saveView) {
            await viewPrefsService.saveViewPreferences(ViewEntityType.task, fields);
          } else {
            await viewPrefsService.clearViewPreferences(ViewEntityType.task);
          }
          
          // Apply the fields to the cubit to update UI
          cubit.setVisibleFields(fields);
        },
        onFilter: () async {
          final result = await showAppBottomSheet<Map<String, dynamic>?>(
            context,
            FilterGroupBottomSheet(
              entity: FilterEntityType.task,
              initialContext: cubit.currentMilestoneIdFilter,
              initialDateFilter: cubit.currentTargetDateFilter,
              initialStatus: cubit.currentStatusFilter,
              milestoneOptions: _getMilestoneOptions(),
              goalOptions: _getGoalOptions(),
            ),
          );

          if (result == null) return;

          if (result.containsKey('milestoneId') || 
              result.containsKey('goalId') || 
              result.containsKey('status') || 
              result.containsKey('targetDate')) {
            cubit.applyFilter(
              milestoneId: result['milestoneId'] as String?,
              goalId: result['goalId'] as String?,
              status: result['status'] as String?,
              targetDateFilter: result['targetDate'] as String?,
            );
          }
        },
        onAdd: () => _onCreateTask(context, cubit),
        onMore: () => _showActionsSheet(context, cubit),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  /// Helper method to fetch milestones from Hive and format them for the dropdown
  List<String> _getMilestoneOptions() {
    try {
      final box = Hive.box<MilestoneModel>(milestoneBoxName);
      final milestones = box.values.toList();
      
      // Format as "id::name" for the dropdown
      return milestones.map((m) => '${m.id}::${m.name}').toList();
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

  /// Helper to build milestone-to-goal mapping for the form
  Map<String, String> _getMilestoneGoalMap() {
    try {
      final milestoneBox = Hive.box<MilestoneModel>(milestoneBoxName);
      final goalBox = Hive.box<GoalModel>(goalBoxName);
      final milestones = milestoneBox.values.toList();
      final goalMap = <String, String>{};
      
      for (final m in milestones) {
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
    super.key,
  });

  final Future<void> Function() onView;
  final Future<void> Function() onFilter;
  final VoidCallback onAdd;
  final VoidCallback onMore;
  final Map<String, bool> initialVisibleFields;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Navigation row
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton.small(
              heroTag: 'navGoals',
              tooltip: 'Goals',
              backgroundColor: cs.surface.withOpacity(0.85),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const GoalListPage()),
                );
              },
              child: const Icon(Icons.track_changes),
            ),
            const SizedBox(width: 8),
            FloatingActionButton.small(
              heroTag: 'navMilestones',
              tooltip: 'Milestones',
              backgroundColor: cs.surface.withOpacity(0.85),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MilestoneListPage()),
                );
              },
              child: const Icon(Icons.flag),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton.small(
              heroTag: 'viewFab',
              tooltip: 'Change View',
              backgroundColor: cs.surface.withOpacity(0.85),
              onPressed: () => onView(),
              child: const Icon(Icons.remove_red_eye),
            ),
            const SizedBox(width: 8),
            FloatingActionButton.small(
              heroTag: 'filterFab',
              tooltip: 'Filter',
              backgroundColor: cs.surface.withOpacity(0.85),
              onPressed: () => onFilter(),
              child: const Icon(Icons.filter_alt),
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
              backgroundColor: cs.surface.withOpacity(0.85),
              onPressed: onAdd,
              child: const Icon(Icons.add),
            ),
            const SizedBox(width: 12),
            FloatingActionButton.small(
              heroTag: 'moreFab',
              tooltip: 'More actions',
              backgroundColor: cs.surface.withOpacity(0.85),
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
          Icon(Icons.task_alt, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant),
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
  final VoidCallback onClearFilters;

  const _TasksBody({
    required this.tasks,
    required this.visibleFields,
    required this.filterActive,
    required this.filterSummary,
    required this.milestoneNameById,
    required this.goalNameById,
    required this.onEdit,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (filterActive) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.filter_alt, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    filterSummary,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onClearFilters,
                  tooltip: 'Clear filters',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
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
                milestoneName: milestoneNameById[task.milestoneId],
                goalName: goalNameById[task.goalId],
                onEdit: () => onEdit(context, task),
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
