/*
  purpose:
    - Presentation layer page that displays the list of Habit entities and related actions.
    - Responsible for wiring the HabitCubit for this screen, rendering loading/error/empty states,
      and providing user actions (create, edit, filter, delete).
    - Keeps UI concerns only — all business logic lives in HabitCubit / domain use cases.
*/

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../domain/entities/habit.dart';
import '../../data/models/goal_model.dart';
import '../../data/models/milestone_model.dart';
import '../../core/injection.dart'; // factory that wires everything (createHabitCubit)
import '../../core/constants.dart'; // for goalBoxName, milestoneBoxName
import '../../core/sort_preferences_service.dart'; // for SortEntityType
import '../bloc/habit_cubit.dart';
import '../bloc/habit_state.dart';
import '../bloc/habit_completion_cubit.dart';
// import '../../features/habit_import_export.dart'; // TODO: Create habit import/export feature
import 'habit_detail_page.dart';

// Shared component imports - adjust paths to your project
import '../../../../widgets/primary_app_bar.dart';
import 'package:all_tracker/trackers/goal_tracker/core/app_icons.dart';
import '../widgets/habit_list_item.dart';
import '../../../../widgets/loading_view.dart';
import '../../../../widgets/error_view.dart';
import '../widgets/habit_form_bottom_sheet.dart';
import '../widgets/view_field_bottom_sheet.dart';
import '../widgets/filter_group_bottom_sheet.dart';
import '../../../../widgets/bottom_sheet_helpers.dart'; // centralized helper

class HabitListPage extends StatelessWidget {
  final String? goalId;
  final String? milestoneId;
  
  const HabitListPage({super.key, this.goalId, this.milestoneId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = createHabitCubit();
        cubit.loadHabits().then((_) {
          if (milestoneId != null) {
            cubit.applyFilter(milestoneId: milestoneId);
          } else if (goalId != null) {
            cubit.applyFilter(goalId: goalId);
          }
        });
        return cubit;
      },
      child: HabitListPageView(goalId: goalId, milestoneId: milestoneId),
    );
  }
}

class HabitListPageView extends StatelessWidget {
  final String? goalId;
  final String? milestoneId;
  
  const HabitListPageView({super.key, this.goalId, this.milestoneId});

  @override
  Widget build(BuildContext context) {
    // Obtain cubit & state here once so nested closures don't call context.read
    final cubit = context.read<HabitCubit>();
    final state = cubit.state;
    final Map<String, bool> initialVisible =
        state is HabitsLoaded ? state.visibleFields : <String, bool>{};

    return BlocProvider(
      create: (_) => createHabitCompletionCubit(),
      child: Scaffold(
        appBar: PrimaryAppBar(
          title: 'Habits',
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
                child: BlocBuilder<HabitCubit, HabitState>(
                  builder: (context, state) {
                    if (state is HabitsLoading) {
                      return const LoadingView();
                    }

                    if (state is HabitsLoaded) {
                      final habits = state.habits;
                      final visible = state.visibleFields;

                      // use the cubit captured from outer scope; do NOT call context.read here
                      final bool filterActive = cubit.hasActiveFilters;
                      final String filterSummary = cubit.filterSummary;

                      // Build maps for milestone and goal names
                      final Map<String, String> milestoneNameById = _getMilestoneNameById();
                      final Map<String, String> goalNameById = _getGoalNameById();

                      if (habits.isEmpty) {
                        return _EmptyHabits(
                          filterActive: filterActive,
                          onClear: () {
                            cubit.clearFilters();
                          },
                        );
                      }

                      return _HabitsBody(
                        habits: habits,
                        visibleFields: visible,
                        filterActive: filterActive,
                        filterSummary: filterSummary,
                        milestoneNameById: milestoneNameById,
                        goalNameById: goalNameById,
                        onEdit: (ctx, habit) => _onEditHabit(ctx, habit, cubit),
                        onViewDetails: (ctx, habit) => _onViewHabitDetails(ctx, habit),
                        onEditFilters: () => _editFilters(context, cubit),
                        onClearFilters: () {
                          cubit.clearFilters();
                        },
                      );
                    }

                    if (state is HabitsError) {
                      return ErrorView(
                        message: state.message,
                        onRetry: () => cubit.loadHabits(),
                      );
                    }

                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: BlocBuilder<HabitCubit, HabitState>(
          builder: (context, state) {
            final filterActive = cubit.hasActiveFilters;
            return _ActionsFab(
              initialVisibleFields: initialVisible,
              filterActive: filterActive,
              onView: () async {
                final currentState = cubit.state;
                final Map<String, bool>? initial =
                    currentState is HabitsLoaded ? currentState.visibleFields : <String, bool>{};

                final result = await showAppBottomSheet<Map<String, dynamic>?>(
                  context,
                  ViewFieldsBottomSheet(entity: ViewEntityType.habit, initial: initial),
                );
                if (result == null) return;
                
                // Extract fields and saveView preference from result
                final fields = result['fields'] as Map<String, bool>;
                final saveView = result['saveView'] as bool;
                
                // Get the ViewPreferencesService from cubit
                final viewPrefsService = cubit.viewPreferencesService;
                
                // Save or clear preferences based on checkbox state
                if (saveView) {
                  await viewPrefsService.saveViewPreferences(ViewEntityType.habit, fields);
                } else {
                  await viewPrefsService.clearViewPreferences(ViewEntityType.habit);
                }
                
                // Apply the fields to the cubit to update UI
                cubit.setVisibleFields(fields);
              },
              onFilter: () async {
                await _editFilters(context, cubit);
              },
              onAdd: () => _onCreateHabit(context, cubit),
              onMore: () => _showActionsSheet(context, cubit),
            );
          },
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  void _onViewHabitDetails(BuildContext context, Habit habit) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HabitDetailPage(habitId: habit.id),
      ),
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

  /// Helper to build milestone-to-goal mapping for the form (milestoneId -> goalName)
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

  Future<void> _editFilters(BuildContext context, HabitCubit cubit) async {
    // Check if there are existing saved filters
    final savedFilters = cubit.filterPreferencesService.loadFilterPreferences(FilterEntityType.habit);
    final hasSavedFilters = savedFilters != null && 
        (savedFilters['milestoneId'] != null || savedFilters['goalId'] != null || 
         savedFilters['status'] != null);
    
    // Check if there are existing saved sort preferences
    final savedSort = cubit.sortPreferencesService.loadSortPreferences(SortEntityType.habit);
    final hasSavedSort = savedSort != null;
    
    // Get goalId from saved filters if available, or derive from milestoneId
    String? initialGoalId;
    if (savedFilters != null && savedFilters['goalId'] != null) {
      initialGoalId = savedFilters['goalId'];
    } else if (cubit.currentMilestoneIdFilter != null) {
      final milestoneToGoalMap = _getMilestoneToGoalIdMap();
      initialGoalId = milestoneToGoalMap[cubit.currentMilestoneIdFilter];
    }
    
    final result = await showAppBottomSheet<Map<String, dynamic>?>(
      context,
      FilterGroupBottomSheet(
        entity: FilterEntityType.habit,
        initialContext: cubit.currentMilestoneIdFilter,
        initialGoalId: initialGoalId,
        initialDateFilter: null, // Habits don't have target dates
        initialStatus: cubit.currentStatusFilter,
        milestoneOptions: _getMilestoneOptions(),
        goalOptions: _getGoalOptions(),
        milestoneToGoalMap: _getMilestoneToGoalIdMap(),
        initialSaveFilter: hasSavedFilters,
        initialSaveSort: hasSavedSort,
        initialSortOrder: cubit.currentSortOrder,
        initialHideCompleted: cubit.hideInactive,
      ),
    );

    if (result == null) return;

    if (result.containsKey('milestoneId') || 
        result.containsKey('goalId') || 
        result.containsKey('status') ||
        result.containsKey('hideCompleted')) {
      final saveFilter = result['saveFilter'] as bool? ?? false;
      final hideCompleted = result['hideCompleted'] as bool? ?? true;
      
      // Save or clear filter preferences based on checkbox state
      if (saveFilter) {
        final filters = <String, String?>{
          'milestoneId': result['milestoneId'] as String?,
          'goalId': result['goalId'] as String?,
          'status': result['status'] as String?,
        };
        await cubit.filterPreferencesService.saveFilterPreferences(FilterEntityType.habit, filters);
      } else {
        await cubit.filterPreferencesService.clearFilterPreferences(FilterEntityType.habit);
      }
      
      cubit.applyFilter(
        milestoneId: result['milestoneId'] as String?,
        goalId: result['goalId'] as String?,
        statusFilter: result['status'] as String?,
        hideCompleted: hideCompleted,
      );
    }

    if (result.containsKey('sortOrder') || result.containsKey('hideCompleted')) {
      final sortOrder = result['sortOrder'] as String? ?? 'asc';
      final hideInactive = result['hideCompleted'] as bool? ?? true;
      final saveSort = result['saveSort'] as bool? ?? false;
      
      // Save or clear sort preferences based on checkbox state
      if (saveSort) {
        final sortSettings = <String, dynamic>{
          'sortOrder': sortOrder,
          'hideCompleted': hideInactive,
        };
        await cubit.sortPreferencesService.saveSortPreferences(SortEntityType.habit, sortSettings);
      } else {
        await cubit.sortPreferencesService.clearSortPreferences(SortEntityType.habit);
      }
      
      // Apply sorting
      cubit.applySorting(sortOrder: sortOrder, hideInactive: hideInactive);
    }
  }

  void _onCreateHabit(BuildContext context, HabitCubit cubit) {
    HabitFormBottomSheet.show(
      context,
      title: 'Create Habit',
      milestoneOptions: _getMilestoneOptions(),
      milestoneGoalMap: _getMilestoneGoalMap(),
      onSubmit: (name, description, milestoneId, rrule, targetCompletions, isActive) async {
        try {
          await cubit.addHabit(
            name: name,
            description: description,
            milestoneId: milestoneId,
            rrule: rrule,
            targetCompletions: targetCompletions,
            isActive: isActive,
          );
          
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Habit created successfully')),
          );
        } catch (e) {
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error creating habit: ${e.toString()}')),
          );
        }
      },
    );
  }

  void _onEditHabit(BuildContext context, Habit habit, HabitCubit cubit) {
    HabitFormBottomSheet.show(
      context,
      title: 'Edit Habit',
      initialName: habit.name,
      initialDescription: habit.description,
      initialMilestoneId: habit.milestoneId,
      initialRrule: habit.rrule,
      initialTargetCompletions: habit.targetCompletions,
      initialIsActive: habit.isActive,
      milestoneOptions: _getMilestoneOptions(),
      milestoneGoalMap: _getMilestoneGoalMap(),
      onSubmit: (name, description, milestoneId, rrule, targetCompletions, isActive) async {
        try {
          await cubit.editHabit(
            id: habit.id,
            name: name,
            description: description,
            milestoneId: milestoneId,
            rrule: rrule,
            targetCompletions: targetCompletions,
            isActive: isActive,
          );
          
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Habit updated successfully')),
          );
        } catch (e) {
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating habit: ${e.toString()}')),
          );
        }
      },
      onDelete: () async {
        await cubit.removeHabit(habit.id);
        
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Habit deleted')),
        );
      },
    );
  }

  void _showActionsSheet(BuildContext context, HabitCubit cubit) {
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
          title: const Text('Add Habit'),
          onTap: () {
            Navigator.of(context).pop();
            _onCreateHabit(context, cubit);
          },
        ),
        // TODO: Implement habit import/export functionality
        // ListTile(
        //   leading: const Icon(Icons.file_download),
        //   title: const Text('Export'),
        //   onTap: () async {
        //     Navigator.of(context).pop();
        //     final state = cubit.state;
        //     final habits = state is HabitsLoaded ? state.habits : <Habit>[];
        //     final path = await exportHabitsToXlsx(context, habits);
        //     if (path != null) {
        //       // ignore: use_build_context_synchronously
        //       ScaffoldMessenger.of(context).showSnackBar(
        //         const SnackBar(content: Text('File exported')),
        //       );
        //     }
        //   },
        // ),
        // ListTile(
        //   leading: const Icon(Icons.file_upload),
        //   title: const Text('Import'),
        //   onTap: () {
        //     Navigator.of(context).pop();
        //     importHabitsFromXlsx(context);
        //   },
        // ),
        // ListTile(
        //   leading: const Icon(Icons.download),
        //   title: const Text('Download Template'),
        //   onTap: () async {
        //     Navigator.of(context).pop();
        //     final path = await downloadHabitsTemplate(context);
        //     if (path != null) {
        //       // ignore: use_build_context_synchronously
        //       ScaffoldMessenger.of(context).showSnackBar(
        //         const SnackBar(content: Text('Template downloaded')),
        //       );
        //     }
        //   },
        // ),
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
                            color: cs.surface.withOpacity(0.85),
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
              heroTag: 'addHabitFab',
              tooltip: 'Add Habit',
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

class _EmptyHabits extends StatelessWidget {
  final bool filterActive;
  final VoidCallback onClear;

  const _EmptyHabits({
    required this.filterActive,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(AppIcons.habit, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(
            filterActive ? 'No habits match your filters' : 'No habits yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            filterActive
                ? 'Try adjusting your filters'
                : 'Tap the + button to create your first habit',
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

class _HabitsBody extends StatelessWidget {
  final List<Habit> habits;
  final Map<String, bool> visibleFields;
  final bool filterActive;
  final String filterSummary;
  final Map<String, String> milestoneNameById;
  final Map<String, String> goalNameById;
  final Function(BuildContext, Habit) onEdit;
  final Function(BuildContext, Habit) onViewDetails;
  final VoidCallback onEditFilters;
  final VoidCallback onClearFilters;

  const _HabitsBody({
    required this.habits,
    required this.visibleFields,
    required this.filterActive,
    required this.filterSummary,
    required this.milestoneNameById,
    required this.goalNameById,
    required this.onEdit,
    required this.onViewDetails,
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
            itemCount: habits.length,
            itemBuilder: (context, index) {
              final habit = habits[index];
              return BlocBuilder<HabitCompletionCubit, dynamic>(
                builder: (context, completionState) {
                  final completionCubit = context.read<HabitCompletionCubit>();
                  final isCompletedToday = completionCubit.isCompletedOnDate(habit.id, DateTime.now());
                  final currentStreak = completionCubit.getCurrentStreak(habit.id);
                  
                  return HabitListItem(
                    id: habit.id,
                    title: habit.name,
                    description: habit.description,
                    rrule: habit.rrule,
                    targetCompletions: habit.targetCompletions,
                    milestoneName: milestoneNameById[habit.milestoneId],
                    goalName: goalNameById[habit.goalId],
                    currentStreak: currentStreak,
                    isActive: habit.isActive,
                    isCompletedToday: isCompletedToday,
                    onEdit: () => onEdit(context, habit),
                    onViewDetails: () => onViewDetails(context, habit),
                    onToggleCompletion: () => completionCubit.toggleCompletionForDate(habit.id, DateTime.now()),
                    visibleFields: visibleFields,
                    filterActive: filterActive,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
