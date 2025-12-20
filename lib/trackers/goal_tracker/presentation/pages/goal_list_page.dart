// ./lib/goal_tracker/presentation/pages/goal_list_page.dart
/*
  purpose:
    - Presentation layer page that displays the list of Goal entities and related actions.
    - Responsible for wiring the GoalCubit for this screen, rendering loading/error/empty states,
      and providing user actions (create, edit, filter, import/export).
    - Keeps UI concerns only — all business logic lives in GoalCubit / domain use cases.
*/

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/goal.dart';
import '../../features/goal_import_export.dart';
import '../bloc/goal_cubit.dart';
import '../bloc/goal_state.dart';
import '../../core/injection.dart'; // factory that wires everything
import 'package:all_tracker/core/services/view_entity_type.dart'; // for SortEntityType

// Shared component imports - adjust paths to your project
import '../../../../widgets/primary_app_bar.dart';
import '../widgets/filter_group_bottom_sheet.dart';
import '../widgets/goal_list_item.dart';
import '../../../../widgets/loading_view.dart';
import '../../../../widgets/error_view.dart';
import '../widgets/goal_form_bottom_sheet.dart';
import '../widgets/view_field_bottom_sheet.dart';
import '../../../../widgets/bottom_sheet_helpers.dart'; // <- centralized helper

class GoalListPage extends StatelessWidget {
  final String? targetDateFilter;
  
  const GoalListPage({super.key, this.targetDateFilter});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = createGoalCubit();
        cubit.loadGoals().then((_) {
          if (targetDateFilter != null) {
            cubit.applyFilter(targetDateFilter: targetDateFilter);
          }
        });
        return cubit;
      },
      child: GoalListPageView(targetDateFilter: targetDateFilter),
    );
  }
}

class GoalListPageView extends StatelessWidget {
  final String? targetDateFilter;
  
  const GoalListPageView({super.key, this.targetDateFilter});

  @override
  Widget build(BuildContext context) {
    // Obtain cubit & state here once so nested closures don't call context.read
    final cubit = context.read<GoalCubit>();
    final state = cubit.state;
    final Map<String, bool> initialVisible =
        state is GoalsLoaded ? state.visibleFields : <String, bool>{};

    return Scaffold(
      appBar: PrimaryAppBar(
        title: 'Goal Tracker',
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
              child: BlocBuilder<GoalCubit, GoalState>(
                builder: (context, state) {
                  if (state is GoalsLoading) {
                    return const LoadingView();
                  }

                  if (state is GoalsLoaded) {
                    final goals = state.goals;
                    final visible = state.visibleFields;
                    final milestoneSummaries = state.milestoneSummaries;

                    // use the cubit captured from outer scope; do NOT call context.read here
                    final bool filterActive = cubit.hasActiveFilters;
                    final String filterSummary = cubit.filterSummary;

                    if (goals.isEmpty) {
                      return _EmptyGoals(
                        filterActive: filterActive,
                        onClear: () {
                          // delegate clearing to cubit per acceptance criteria
                          cubit.clearFilters();
                        },
                      );
                    }

                    return _GoalsBody(
                      goals: goals,
                      visibleFields: visible,
                      milestoneSummaries: milestoneSummaries,
                      filterActive: filterActive,
                      filterSummary: filterSummary,
                      // pass the cubit into the edit handler so nested closures don't call context.read
                      onEdit: (ctx, goal) => _onEditGoal(ctx, goal, cubit),
                      onEditFilters: () => _editFilters(context, cubit),
                      onClearFilters: () {
                        cubit.clearFilters();
                      },
                    );
                  }

                  if (state is GoalsError) {
                    return ErrorView(
                      message: state.message,
                      // use captured cubit instead of context.read
                      onRetry: () => cubit.loadGoals(),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: BlocBuilder<GoalCubit, GoalState>(
        builder: (context, state) {
          final filterActive = cubit.hasActiveFilters;
          return _ActionsFab(
            // initialVisibleFields provided for widget that might want to render based on it.
            initialVisibleFields: initialVisible,
            filterActive: filterActive,
            // onView opens the ViewFieldsBottomSheet and applies selected fields to cubit.
            onView: () async {
              // read the up-to-date visible fields directly from cubit.state
              final currentState = cubit.state;
              final Map<String, bool>? initial =
                  currentState is GoalsLoaded ? currentState.visibleFields : <String, bool>{};

              final result = await showAppBottomSheet<Map<String, dynamic>?>(
                context,
                ViewFieldsBottomSheet(entity: ViewEntityType.goal, initial: initial),
              );
              if (result == null) return;
              
              // Extract fields and saveView preference from result
              final fields = result['fields'] as Map<String, bool>;
              final saveView = result['saveView'] as bool;
              
              // Get the ViewPreferencesService from cubit
              final viewPrefsService = cubit.viewPreferencesService;
              
              // Save or clear preferences based on checkbox state
              if (saveView) {
                await viewPrefsService.saveViewPreferences(ViewEntityType.goal, fields);
              } else {
                await viewPrefsService.clearViewPreferences(ViewEntityType.goal);
              }
              
              // Apply the fields to the cubit to update UI
              cubit.setVisibleFields(fields);
            },
            // onFilter opens the FilterGroupBottomSheet and applies filters/grouping via cubit.
            onFilter: () async {
              await _editFilters(context, cubit);
            },
            // onAdd shows the create goal sheet — pass cubit explicitly
            onAdd: () => _onCreateGoal(context, cubit),
            // onMore shows the actions sheet — pass cubit explicitly
            onMore: () => _showActionsSheet(context, cubit),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // Edited to accept cubit and avoid reading from context inside the method.
  Future<void> _editFilters(BuildContext context, GoalCubit cubit) async {
    // Check if there are existing saved filters
    final savedFilters = cubit.filterPreferencesService.loadFilterPreferences(FilterEntityType.goal);
    final hasSavedFilters = savedFilters != null && 
        (savedFilters['context'] != null || savedFilters['targetDate'] != null);
    
    // Check if there are existing saved sort preferences
    final savedSort = cubit.sortPreferencesService.loadSortPreferences(SortEntityType.goal);
    final hasSavedSort = savedSort != null;
    
    final result = await showAppBottomSheet<Map<String, dynamic>?>(
      context,
      FilterGroupBottomSheet(
        entity: FilterEntityType.goal,
        initialContext: cubit.currentContextFilter,
        initialDateFilter: cubit.currentTargetDateFilter,
        initialGrouping: cubit.currentGrouping,
        initialSaveFilter: hasSavedFilters,
        initialSaveSort: hasSavedSort,
        initialSortOrder: cubit.currentSortOrder,
        initialHideCompleted: cubit.hideCompleted,
      ),
    );

    if (result == null) return;

    if (result.containsKey('context') || result.containsKey('targetDate') || result.containsKey('hideCompleted')) {
      final selectedContext = result['context'] as String?;
      final selectedTargetDate = result['targetDate'] as String?;
      final hideCompleted = result['hideCompleted'] as bool? ?? true;
      final saveFilter = result['saveFilter'] as bool? ?? false;
      
      // Save or clear filter preferences based on checkbox state
      if (saveFilter) {
        final filters = <String, String?>{
          'context': selectedContext,
          'targetDate': selectedTargetDate,
        };
        await cubit.filterPreferencesService.saveFilterPreferences(FilterEntityType.goal, filters);
      } else {
        await cubit.filterPreferencesService.clearFilterPreferences(FilterEntityType.goal);
      }
      
      // use passed cubit instead of context.read
      cubit.applyFilter(
        contextFilter: selectedContext,
        targetDateFilter: selectedTargetDate,
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
        await cubit.sortPreferencesService.saveSortPreferences(SortEntityType.goal, sortSettings);
      } else {
        await cubit.sortPreferencesService.clearSortPreferences(SortEntityType.goal);
      }
      
      // Apply sorting
      cubit.applySorting(sortOrder: sortOrder, hideCompleted: hideCompleted);
    }

    if (result['groupBy'] != null && (result['groupBy'] as String).isNotEmpty) {
      final groupBy = result['groupBy'] as String;
      cubit.applyGrouping(groupBy: groupBy);
    }
  }

  // Accept cubit so we avoid nested context.read calls.
  void _showActionsSheet(BuildContext context, GoalCubit cubit) {
    // Build the sheet content and pass to helper to preserve consistent look/behavior.
    final sheet = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 12),
        ListTile(
          leading: const Icon(Icons.add),
          title: const Text('Add Goal'),
          onTap: () {
            Navigator.of(context).pop();
            // pass cubit explicitly
            _onCreateGoal(context, cubit);
          },
        ),
        ListTile(
          leading: const Icon(Icons.file_download),
          title: const Text('Export'),
          onTap: () async {
            Navigator.of(context).pop();
            // use passed cubit
            final state = cubit.state;
            final goals = state is GoalsLoaded ? state.goals : <Goal>[];
            final path = await exportGoalsToXlsx(context, goals);
            if (path != null) {
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
            importGoalsFromXlsx(context);
          },
        ),
        const SizedBox(height: 8),
      ],
    );

    // Use helper which internally wraps with SafeArea and handles keyboard insets.
    showAppBottomSheet<void>(context, sheet);
  }

  // Now accepts both context and explicit cubit parameter
  void _onCreateGoal(BuildContext context, GoalCubit cubit) {
    GoalFormBottomSheet.show(
      context,
      title: 'Create Goal',
      onSubmit: (name, desc, targetDate, contxt, isCompleted) async {
        await cubit.addGoal(name, desc, targetDate, contxt, isCompleted);
      },
    );
  }

  // Now explicitly typed and accepts cubit so nested closures don't call context.read.
  void _onEditGoal(BuildContext context, Goal goal, GoalCubit cubit) {
    GoalFormBottomSheet.show(
      context,
      title: 'Edit Goal',
      initialName: goal.name,
      initialDescription: goal.description,
      initialTargetDate: goal.targetDate,
      initialContext: goal.context,
      initialIsCompleted: goal.isCompleted,
      goalId: goal.id, // Pass goalId for review buttons
      onSubmit: (name, desc, targetDate, contxt, isCompleted) async {
        await cubit.editGoal(goal.id, name, desc, targetDate, contxt, isCompleted);
      },
      onDelete: () async {
        cubit.removeGoal(goal.id);
      },
    );
  }
}

/// ---------------------------------------------------------------------------
/// _ActionsFab
///
/// New extracted widget for the FAB column. It does NOT read from context or call
/// any cubit methods — all interactions are done via the callbacks passed in.
/// Accepts an initialVisibleFields map (optional) to allow rendering differences
/// if needed in future, but currently it only uses callbacks.
/// ---------------------------------------------------------------------------
class _ActionsFab extends StatelessWidget {
  const _ActionsFab({
    required this.onView,
    required this.onFilter,
    required this.onAdd,
    required this.onMore,
    this.initialVisibleFields = const <String, bool>{},
    this.filterActive = false,
  });

  /// Callback invoked when the 'view' FAB is tapped.
  /// Parent should handle showing the view fields sheet and applying fields.
  final Future<void> Function() onView;

  /// Callback invoked when the 'filter' FAB is tapped.
  /// Parent should handle showing the filter/group sheet and applying filters.
  final Future<void> Function() onFilter;

  /// Callback invoked when 'add' FAB is tapped.
  final VoidCallback onAdd;

  /// Callback invoked when 'more' FAB is tapped.
  final VoidCallback onMore;

  /// Optional map of visible fields initially — provided for potential rendering.
  final Map<String, bool> initialVisibleFields;

  /// Whether filters are currently active - shows dot indicator on filter icon
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
              heroTag: 'filterGroupFab',
              tooltip: 'Filter & Group',
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
              heroTag: 'addGoalFab',
              tooltip: 'Add Goal',
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

/// ---------------------------------------------------------------------------
/// _GoalsBody
///
/// Extracted widget that contains the filter header + list of goals.
/// It does NOT read from context; all state and callbacks are passed in.
/// ---------------------------------------------------------------------------
class _GoalsBody extends StatelessWidget {
  const _GoalsBody({
    required this.goals,
    required this.visibleFields,
    required this.milestoneSummaries,
    required this.filterActive,
    required this.filterSummary,
    required this.onEdit,
    required this.onEditFilters,
    required this.onClearFilters,
  });

  final List<Goal> goals;
  final Map<String, bool> visibleFields;
  final Map<String, GoalMilestoneStats> milestoneSummaries;
  final bool filterActive;
  final String filterSummary;

  /// Called when user taps the edit action for a goal.
  /// Provided a BuildContext so caller can show modals / sheets as needed.
  final void Function(BuildContext context, Goal goal) onEdit;

  /// Called when user taps the 'Edit filters' button in header.
  final VoidCallback onEditFilters;

  /// Called when user taps 'Clear filters' in header.
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter header removed - filter icon dot indicator shows filter is active
        Expanded(
          child: _GoalsList(
            goals: goals,
            visibleFields: visibleFields,
            milestoneSummaries: milestoneSummaries,
            filterActive: filterActive,
            onEdit: onEdit,
          ),
        ),
      ],
    );
  }
}

/// ---------------------------------------------------------------------------
/// _GoalsList
///
/// Responsibility:
///  - Render the scrollable list of goals (separated)
///  - Wire each GoalListItem with required props and callbacks
///  - MUST NOT access cubit/context.read inside its itemBuilder
/// ---------------------------------------------------------------------------
class _GoalsList extends StatelessWidget {
  const _GoalsList({
    required this.goals,
    required this.visibleFields,
    required this.milestoneSummaries,
    required this.filterActive,
    required this.onEdit,
  });

  final List<Goal> goals;
  final Map<String, bool> visibleFields;
  final Map<String, GoalMilestoneStats> milestoneSummaries;
  final bool filterActive;

  /// Same signature as before: caller provides how to open edit sheet, etc.
  final void Function(BuildContext context, Goal goal) onEdit;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: goals.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final g = goals[index];
        final stats = milestoneSummaries[g.id];

        // IMPORTANT: Do not call context.read(...) or access cubit here.
        // onEdit is provided by parent and will handle cubit interactions.
        return GoalListItem(
          key: ValueKey(g.id),
          id: g.id,
          title: g.name,
          description: g.description ?? '',
          targetDate: g.targetDate,
          contextValue: g.context,
          visibleFields: visibleFields,
          filterActive: filterActive,
          openMilestoneCount: stats?.openCount,
          totalMilestoneCount: stats?.totalCount,
          milestoneCompletionPercent: stats?.completionPercent,
          isCompleted: g.isCompleted,
          onEdit: () => onEdit(context, g),
        );
      },
    );
  }
}

/// ---------------------------------------------------------------------------
/// _EmptyGoals
///
/// Extracted widget shown when there are no goals.
/// Accepts filterActive and onClear callback. The caller should pass a callback
/// that calls the cubit's `clearFilters()` (see acceptance criteria).
/// ---------------------------------------------------------------------------
class _EmptyGoals extends StatelessWidget {
  const _EmptyGoals({
    required this.filterActive,
    required this.onClear,
  });

  final bool filterActive;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final message = filterActive ? 'No goals found' : 'No goals yet';

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (filterActive)
            OutlinedButton(
              onPressed: onClear,
              child: const Text('No goals found. Clear filters?'),
            ),
        ],
      ),
    );
  }
}

