/*
  purpose:
    - Presentation layer page that displays the list of Milestone entities and related actions.
    - Responsible for wiring the MilestoneCubit for this screen, rendering loading/error/empty states,
      and providing user actions (create, edit, filter, import/export).
    - Keeps UI concerns only — all business logic lives in MilestoneCubit / domain use cases.
*/

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../domain/entities/milestone.dart';
import '../../data/models/goal_model.dart';
import '../../core/injection.dart'; // factory that wires everything (createMilestoneCubit)
import '../../core/constants.dart'; // for goalBoxName
import '../../core/sort_preferences_service.dart'; // for SortEntityType
import '../bloc/milestone_cubit.dart';
import '../bloc/milestone_state.dart';

// Shared component imports - adjust paths to your project
import '../../../../widgets/primary_app_bar.dart';
import '../widgets/filter_group_bottom_sheet.dart';
import '../widgets/milestone_list_item.dart';
import '../../../../widgets/loading_view.dart';
import '../../../../widgets/error_view.dart';
import '../widgets/milestone_form_bottom_sheet.dart';
import '../widgets/view_field_bottom_sheet.dart';
import '../../../../widgets/bottom_sheet_helpers.dart'; // centralized helper
import '../../features/milestone_import_export.dart';

// Optional import placeholders for import/export functionality.
// import '../../features/milestone_import_export.dart';

class MilestoneListPage extends StatelessWidget {
  final String? goalId;
  final String? targetDateFilter;
  
  const MilestoneListPage({super.key, this.goalId, this.targetDateFilter});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = createMilestoneCubit();
        cubit.loadMilestones().then((_) {
          if (goalId != null || targetDateFilter != null) {
            cubit.applyFilter(goalId: goalId, targetDateFilter: targetDateFilter);
          }
        });
        return cubit;
      },
      child: MilestoneListPageView(goalId: goalId, targetDateFilter: targetDateFilter),
    );
  }
}

class MilestoneListPageView extends StatelessWidget {
  final String? goalId;
  final String? targetDateFilter;
  
  const MilestoneListPageView({super.key, this.goalId, this.targetDateFilter});

  @override
  Widget build(BuildContext context) {
    // Obtain cubit & state here once so nested closures don't call context.read
    final cubit = context.read<MilestoneCubit>();
    final state = cubit.state;
    final Map<String, bool> initialVisible =
        state is MilestonesLoaded ? state.visibleFields ?? <String, bool>{} : <String, bool>{};

    return Scaffold(
      appBar: PrimaryAppBar(
        title: 'Milestones',
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
              child: BlocBuilder<MilestoneCubit, MilestoneState>(
                builder: (context, state) {
                  if (state is MilestonesLoading) {
                    return const LoadingView();
                  }

                  if (state is MilestonesLoaded) {
                    final milestones = state.milestones;
                    final visible = state.visibleFields ?? <String, bool>{};

                    // use the cubit captured from outer scope; do NOT call context.read here
                    final bool filterActive = cubit.hasActiveFilters;
                    final String filterSummary = cubit.filterSummary;

                    // Build a map of goalId -> goalName to display human-readable goal names
                    final Map<String, String> goalNameById = _getGoalNameById();

                    if (milestones.isEmpty) {
                      return _EmptyMilestones(
                        filterActive: filterActive,
                        onClear: () {
                          // delegate clearing to cubit per acceptance criteria
                          cubit.clearFilters();
                        },
                      );
                    }

                    return _MilestonesBody(
                      milestones: milestones,
                      visibleFields: visible,
                      filterActive: filterActive,
                      filterSummary: filterSummary,
                      goalNameById: goalNameById,
                      // pass the cubit into the edit handler so nested closures don't call context.read
                      onEdit: (ctx, milestone) => _onEditMilestone(ctx, milestone, cubit),
                      onEditFilters: () => _editFilters(context, cubit),
                      onClearFilters: () {
                        cubit.clearFilters();
                      },
                    );
                  }

                  if (state is MilestonesError) {
                    return ErrorView(
                      message: state.message,
                      // use captured cubit instead of context.read
                      onRetry: () => cubit.loadMilestones(),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: BlocBuilder<MilestoneCubit, MilestoneState>(
        builder: (context, state) {
          final filterActive = cubit.hasActiveFilters;
          return _ActionsFab(
            // initialVisibleFields provided for widget that might want to render based on it.
            initialVisibleFields: initialVisible,
            filterActive: filterActive,
            // onView opens the ViewFieldsBottomSheet and applies selected fields to cubit.
            onView: () async {
              final currentState = cubit.state;
              final Map<String, bool>? initial =
                  currentState is MilestonesLoaded ? currentState.visibleFields : <String, bool>{};

              final result = await showAppBottomSheet<Map<String, dynamic>?>(
                context,
                ViewFieldsBottomSheet(entity: ViewEntityType.milestone, initial: initial),
              );
              if (result == null) return;
              
              // Extract fields and saveView preference from result
              final fields = result['fields'] as Map<String, bool>;
              final saveView = result['saveView'] as bool;
              
              // Get the ViewPreferencesService from cubit
              final viewPrefsService = cubit.viewPreferencesService;
              
              // Save or clear preferences based on checkbox state
              if (saveView) {
                await viewPrefsService.saveViewPreferences(ViewEntityType.milestone, fields);
              } else {
                await viewPrefsService.clearViewPreferences(ViewEntityType.milestone);
              }
              
              // Apply the fields to the cubit to update UI
              cubit.setVisibleFields(fields);
            },
            // onFilter opens the FilterGroupBottomSheet and applies filters/grouping via cubit.
            onFilter: () async {
              await _editFilters(context, cubit);
            },
            // onAdd shows the create milestone sheet — pass cubit explicitly
            onAdd: () => _onCreateMilestone(context, cubit),
            // onMore shows the actions sheet — pass cubit explicitly
            onMore: () => _showActionsSheet(context, cubit),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Future<void> _editFilters(BuildContext context, MilestoneCubit cubit) async {
    // Check if there are existing saved filters
    final savedFilters = cubit.filterPreferencesService.loadFilterPreferences(FilterEntityType.milestone);
    final hasSavedFilters = savedFilters != null && 
        (savedFilters['context'] != null || savedFilters['targetDate'] != null);
    
    // Check if there are existing saved sort preferences
    final savedSort = cubit.sortPreferencesService.loadSortPreferences(SortEntityType.milestone);
    final hasSavedSort = savedSort != null;
    
    final result = await showAppBottomSheet<Map<String, dynamic>?>(
      context,
      FilterGroupBottomSheet(
        entity: FilterEntityType.milestone,
        initialContext: cubit.currentGoalIdFilter, // re-using context param to represent goal filter
        initialDateFilter: cubit.currentTargetDateFilter,
        initialGrouping: null,
        goalOptions: _getGoalOptions(),
        initialSaveFilter: hasSavedFilters,
        initialSaveSort: hasSavedSort,
        initialSortOrder: cubit.currentSortOrder,
        initialHideCompleted: cubit.hideCompleted,
      ),
    );

    if (result == null) return;

    if (result.containsKey('context') || result.containsKey('targetDate') || result.containsKey('hideCompleted')) {
      final selectedGoal = result['context'] as String?;
      final selectedTargetDate = result['targetDate'] as String?;
      final hideCompleted = result['hideCompleted'] as bool? ?? true;
      final saveFilter = result['saveFilter'] as bool? ?? false;
      
      // Save or clear filter preferences based on checkbox state
      if (saveFilter) {
        final filters = <String, String?>{
          'context': selectedGoal,
          'targetDate': selectedTargetDate,
        };
        await cubit.filterPreferencesService.saveFilterPreferences(FilterEntityType.milestone, filters);
      } else {
        await cubit.filterPreferencesService.clearFilterPreferences(FilterEntityType.milestone);
      }
      
      // use passed cubit instead of context.read
      cubit.applyFilter(
        goalId: selectedGoal,
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
        await cubit.sortPreferencesService.saveSortPreferences(SortEntityType.milestone, sortSettings);
      } else {
        await cubit.sortPreferencesService.clearSortPreferences(SortEntityType.milestone);
      }
      
      // Apply sorting
      cubit.applySorting(sortOrder: sortOrder, hideCompleted: hideCompleted);
    }
  }

  void _showActionsSheet(BuildContext context, MilestoneCubit cubit) {
    final sheet = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        Container(width: 40, height: 4, decoration: BoxDecoration(borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 12),
        ListTile(
          leading: const Icon(Icons.add),
          title: const Text('Add Milestone'),
          onTap: () {
            Navigator.of(context).pop();
            _onCreateMilestone(context, cubit);
          },
        ),
        ListTile(
          leading: const Icon(Icons.file_download),
          title: const Text('Export'),
          onTap: () async {
            Navigator.of(context).pop();
            final state = cubit.state;
            final milestones = state is MilestonesLoaded ? state.milestones : <Milestone>[];
            final path = await exportMilestonesToXlsx(context, milestones);
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
            importMilestonesFromXlsx(context);
          },
        ),
        const SizedBox(height: 8),
      ],
    );

    showAppBottomSheet<void>(context, sheet);
  }

  /// Helper method to fetch goals from Hive and format them for the dropdown
  List<String> _getGoalOptions() {
    try {
      final box = Hive.box<GoalModel>(goalBoxName);
      final goals = box.values.toList();
      
      // Format as "id::name" for the dropdown
      return goals.map((g) => '${g.id}::${g.name}').toList();
    } catch (e) {
      // If box is not open or any error occurs, return empty list
      return [];
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
    } catch (_) {
      return const <String, String>{};
    }
  }

  void _onCreateMilestone(BuildContext context, MilestoneCubit cubit) {
    MilestoneFormBottomSheet.show(
      context,
      title: 'Create Milestone',
      goalOptions: _getGoalOptions(),
      onSubmit: (name, desc, planned, actual, targetDate, goalId) async {
        await cubit.addMilestone(
          name: name,
          description: desc,
          plannedValue: planned,
          actualValue: actual,
          targetDate: targetDate,
          goalId: goalId,
        );
      },
    );
  }

  void _onEditMilestone(BuildContext context, Milestone milestone, MilestoneCubit cubit) {
    MilestoneFormBottomSheet.show(
      context,
      title: 'Edit Milestone',
      initialName: milestone.name,
      initialDescription: milestone.description,
      initialPlannedValue: milestone.plannedValue,
      initialActualValue: milestone.actualValue,
      initialTargetDate: milestone.targetDate,
      initialGoalId: milestone.goalId,
      milestoneId: milestone.id, // Pass milestoneId for review buttons
      goalOptions: _getGoalOptions(),
      onSubmit: (name, desc, planned, actual, targetDate, goalId) async {
        await cubit.editMilestone(
          id: milestone.id,
          name: name,
          description: desc,
          plannedValue: planned,
          actualValue: actual,
          targetDate: targetDate,
          goalId: goalId,
        );
      },
      onDelete: () async {
        await cubit.removeMilestone(milestone.id);
      },
    );
  }
}

/// ---------------------------------------------------------------------------
/// _ActionsFab
///
/// Extracted widget for the FAB column. It does NOT read from context or call
/// any cubit methods — all interactions are done via the callbacks passed in.
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
              heroTag: 'filterGroupFab',
              tooltip: 'Filter & Group',
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
              heroTag: 'addMilestoneFab',
              tooltip: 'Add Milestone',
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

/// ---------------------------------------------------------------------------
/// _MilestonesBody
///
/// Extracted widget that contains the filter header + list of milestones.
/// It does NOT read from context; all state and callbacks are passed in.
/// ---------------------------------------------------------------------------
class _MilestonesBody extends StatelessWidget {
  const _MilestonesBody({
    required this.milestones,
    required this.visibleFields,
    required this.filterActive,
    required this.filterSummary,
    required this.goalNameById,
    required this.onEdit,
    required this.onEditFilters,
    required this.onClearFilters,
  });

  final List<Milestone> milestones;
  final Map<String, bool> visibleFields;
  final bool filterActive;
  final String filterSummary;
  final Map<String, String> goalNameById;

  /// Called when user taps the edit action for a milestone.
  final void Function(BuildContext context, Milestone milestone) onEdit;

  final VoidCallback onEditFilters;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter header removed - filter icon dot indicator shows filter is active
        Expanded(
          child: _MilestonesList(
            milestones: milestones,
            visibleFields: visibleFields,
            filterActive: filterActive,
            goalNameById: goalNameById,
            onEdit: onEdit,
          ),
        ),
      ],
    );
  }
}

/// ---------------------------------------------------------------------------
/// _MilestonesList
///
/// Responsibility:
///  - Render the scrollable list of milestones (separated)
///  - Wire each MilestoneListItem with required props and callbacks
///  - MUST NOT access cubit/context.read inside its itemBuilder
/// ---------------------------------------------------------------------------
class _MilestonesList extends StatelessWidget {
  const _MilestonesList({
    required this.milestones,
    required this.visibleFields,
    required this.filterActive,
    required this.goalNameById,
    required this.onEdit,
  });

  final List<Milestone> milestones;
  final Map<String, bool> visibleFields;
  final bool filterActive;
  final Map<String, String> goalNameById;

  /// Caller provides how to open edit sheet, etc.
  final void Function(BuildContext context, Milestone milestone) onEdit;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: milestones.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final m = milestones[index];

        return MilestoneListItem(
          key: ValueKey(m.id),
          id: m.id,
          title: m.name,
          description: m.description,
          plannedValue: m.plannedValue,
          actualValue: m.actualValue,
          targetDate: m.targetDate,
          goalName: goalNameById[m.goalId] ?? m.goalId,
          visibleFields: visibleFields,
          filterActive: filterActive,
          onEdit: () => onEdit(context, m),
        );
      },
    );
  }
}

/// ---------------------------------------------------------------------------
/// _EmptyMilestones
///
/// Extracted widget shown when there are no milestones.
/// Accepts filterActive and onClear callback.
/// ---------------------------------------------------------------------------
class _EmptyMilestones extends StatelessWidget {
  const _EmptyMilestones({
    required this.filterActive,
    required this.onClear,
  });

  final bool filterActive;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final message = filterActive ? 'No milestones found' : 'No milestones yet';

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (filterActive)
            OutlinedButton(
              onPressed: onClear,
              child: const Text('No milestones found. Clear filters?'),
            ),
        ],
      ),
    );
  }
}

