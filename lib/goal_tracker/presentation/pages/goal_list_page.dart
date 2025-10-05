// ./lib/goal_tracker/presentation/pages/goal_list_page.dart
/*
  purpose:
    - Presentation layer page that displays the list of Goal entities and related actions.
    - Responsible for wiring the GoalCubit for this screen, rendering loading/error/empty states,
      and providing user actions (create, edit, filter, import/export).
    - Keeps UI concerns only — all business logic lives in GoalCubit / domain use cases.

  behavior & notes:
    - Uses createGoalCubit() from core/injection.dart to obtain a properly-wired cubit instance.
    - The page expects the cubit to expose:
        * loadGoals()
        * addGoal(...)
        * editGoal(...)
        * removeGoal(...)
        * hasActiveFilters, currentContextFilter, currentTargetDateFilter, currentGrouping
      If your cubit uses different names, update either the cubit or this page accordingly.
    - Import/Export features delegate to features/goal_import_export.dart helpers.
    - UI-level defensive coding is used around optional cubit members (casting to dynamic)
      to preserve compatibility with multiple cubit implementations.
*/

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/goal.dart';
import '../../features/goal_import_export.dart';
import '../bloc/goal_cubit.dart';
import '../bloc/goal_state.dart';
import '../../core/injection.dart'; // factory that wires everything

// Shared component imports - adjust paths to your project
import '../../../widgets/primary_app_bar.dart';
import '../widgets/filter_group_bottom_sheet.dart';
import '../widgets/goal_list_item.dart';
import '../../../widgets/loading_view.dart';
import '../../../widgets/error_view.dart';
import '../widgets/goal_form_bottom_sheet.dart';
import '../widgets/view_field_bottom_sheet.dart';

/// Page that provides a BlocProvider for [GoalCubit] and hosts [GoalListPageView].
///
/// Responsibility:
///  - Bootstraps the cubit for this screen and triggers initial load (loadGoals).
///  - Keeps wiring separate from the view to simplify testing.
class GoalListPage extends StatelessWidget {
  const GoalListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => createGoalCubit()..loadGoals(),
      child: const GoalListPageView(),
    );
  }
}

/// The main view for displaying goals, filters, and floating action buttons.
///
/// This widget is presentation-only: it subscribes to [GoalCubit] state changes
/// via BlocConsumer and delegates actions back to the cubit. No data logic here.
class GoalListPageView extends StatelessWidget {
  const GoalListPageView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PrimaryAppBar(title: 'Goal Tracker'),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Expanded area for list / empty states
            Expanded(
              child: BlocConsumer<GoalCubit, GoalState>(
                listenWhen: (prev, curr) => true,
                listener: (context, state) {},
                buildWhen: (prev, curr) => true,
                builder: (context, state) {
                  if (state is GoalsLoading) {
                    return const LoadingView();
                  }

                  if (state is GoalsLoaded) {
                    final goals = state.goals;
                    final cubit = context.read<GoalCubit>();

                    final bool filterActive = cubit.hasActiveFilters ||
                        (cubit.currentContextFilter != null && cubit.currentContextFilter!.isNotEmpty) ||
                        (cubit.currentTargetDateFilter != null && cubit.currentTargetDateFilter!.isNotEmpty) ||
                        (cubit.currentGrouping != null && cubit.currentGrouping!.isNotEmpty);

                    if (goals.isEmpty) {
                      final message = filterActive ? 'No goals found' : 'No goals yet';

                      // Force a plain, unmistakable UI so we can detect it on screen
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(message, style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 8),
                            if (filterActive)
                              OutlinedButton(
                                onPressed: () {
                                  // quick debug: clear filters to show unfiltered data
                                  context.read<GoalCubit>().clearFilters();
                                },
                                child: const Text('No goals found. Clear filters?'),
                              ),
                          ],
                        ),
                      );
                    }

                    // When there are goals, show optional filter label above the list.
                    return Column(
                      children: [
                        if (filterActive) _buildFilterHeader(context, cubit),
                        // List needs to expand to fill the remaining space
                        Expanded(
                          child: ListView.builder(
                            itemCount: goals.length,
                            itemBuilder: (context, index) {
                              final g = goals[index];
                              return GoalListItem(
                                id: g.id,
                                title: g.name,
                                description: g.description ?? '',
                                onEdit: () => _onEditGoal(context, g),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  }

                  if (state is GoalsError) {
                    return ErrorView(
                      message: state.message,
                      onRetry: () => context.read<GoalCubit>().loadGoals(),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFabColumn(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  /// Builds a compact header that summarizes active filters and provides quick actions.
  ///
  /// Notes:
  ///  - Reads values from [GoalCubit] and shows canonical text (see _filterSummary).
  ///  - The 'Clear filters' action attempts to also clear grouping; a try/catch
  ///    is used to remain compatible with cubit implementations that might not expose applyGrouping.
  Widget _buildFilterHeader(BuildContext context, GoalCubit cubit) {
    final summary = _filterSummary(cubit);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8.0),
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.6),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_alt, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              summary,
              style: Theme.of(context).textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            tooltip: 'Edit filters',
            icon: const Icon(Icons.edit, size: 20),
            onPressed: () => _editFilters(context, cubit),
          ),
          IconButton(
            tooltip: 'Clear filters',
            icon: const Icon(Icons.clear, size: 20),
            onPressed: () {
              cubit.clearFilters();
              // attempt to clear grouping as well by passing empty group value
              // (keeps compatibility if applyGrouping expects a string)
              try {
                cubit.applyGrouping(groupBy: '');
              } catch (_) {
                // ignore if cubit doesn't support clearing grouping this way
              }
            },
          ),
        ],
      ),
    );
  }

  /// Constructs a human-readable summary of active filters from [cubit].
  ///
  /// Returns 'Filters applied' when hasActiveFilters is true but no specific fields are present.
  String _filterSummary(GoalCubit cubit) {
    final parts = <String>[];

    if (cubit.currentContextFilter != null && cubit.currentContextFilter!.isNotEmpty) {
      parts.add('Context: ${cubit.currentContextFilter}');
    }
    if (cubit.currentTargetDateFilter != null && cubit.currentTargetDateFilter!.isNotEmpty) {
      parts.add('Date: ${cubit.currentTargetDateFilter}');
    }
    if (cubit.currentGrouping != null && cubit.currentGrouping!.isNotEmpty) {
      parts.add('Group: ${cubit.currentGrouping}');
    }

    if (parts.isEmpty) {
      // Fallback if hasActiveFilters is true but specific fields are empty
      return 'Filters applied';
    }

    return parts.join(' • ');
  }

  /// Shows the filter/group bottom sheet and applies results to the cubit.
  ///
  /// Behavior:
  ///  - Opens [FilterGroupBottomSheet] with initial values from [cubit].
  ///  - Applies context/targetDate filter and grouping if provided in the result map.
  Future<void> _editFilters(BuildContext context, GoalCubit cubit) async {
    final result = await showModalBottomSheet<Map<String, dynamic>?>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12.0)),
      ),
      builder: (ctx) => FilterGroupBottomSheet(
        initialContext: cubit.currentContextFilter,
        initialDateFilter: cubit.currentTargetDateFilter,
        initialGrouping: cubit.currentGrouping,
      ),
    );

    if (result == null) return;

    if (result.containsKey('context') || result.containsKey('targetDate')) {
      final selectedContext = result['context'] as String?;
      final selectedTargetDate = result['targetDate'] as String?;
      context.read<GoalCubit>().applyFilter(
            contextFilter: selectedContext,
            targetDateFilter: selectedTargetDate,
          );
    }

    if (result['groupBy'] != null && (result['groupBy'] as String).isNotEmpty) {
      final groupBy = result['groupBy'] as String;
      context.read<GoalCubit>().applyGrouping(groupBy: groupBy);
    }
  }

   /// Builds the stacked floating action buttons used on the page.
   ///
   /// Layout:
   ///  - Row 1: View (visible fields) + Filter & Group
   ///  - Row 2: Add Goal + More actions (export/import)
   ///
   /// Notes:
   ///  - Defensive casting to `dynamic` is used when accessing optional cubit members
   ///    (visibleFields / setVisibleFields) so this UI remains compatible with different cubit shapes.
   Widget _buildFabColumn(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Row 1: View + Filter
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton.small(
              heroTag: 'viewFab',
              tooltip: 'Change View',
              onPressed: () async {
                final cubit = context.read<GoalCubit>();
                Map<String, bool>? initial;

                try {
                  initial = (cubit as dynamic).visibleFields as Map<String, bool>?;
                } catch (_) {
                  initial = null;
                }

                final result = await showModalBottomSheet<Map<String, bool>?>(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(12.0)),
                  ),
                  builder: (ctx) => ViewFieldsBottomSheet(initial: initial),
                );

                if (result == null) return;

                try {
                  (cubit as dynamic).setVisibleFields(result);
                } catch (e) {
                  final enabled = result.entries
                      .where((e) => e.value)
                      .map((e) => e.key)
                      .join(', ');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Visible fields: $enabled')),
                  );
                }
              },
              child: const Icon(Icons.remove_red_eye),
            ),

            const SizedBox(width: 8),
            FloatingActionButton.small(
              heroTag: 'filterGroupFab',
              tooltip: 'Filter & Group',
              onPressed: () async {
                final cubit = context.read<GoalCubit>();
                final result = await showModalBottomSheet<Map<String, dynamic>?>(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(12.0)),
                  ),
                  builder: (ctx) => FilterGroupBottomSheet(
                    initialContext: cubit.currentContextFilter,
                    initialDateFilter: cubit.currentTargetDateFilter,
                    initialGrouping: cubit.currentGrouping,
                  ),
                );

                if (result == null) return;

                if (result.containsKey('context') || result.containsKey('targetDate')) {
                  final selectedContext = result['context'] as String?;
                  final selectedTargetDate = result['targetDate'] as String?;
                  context.read<GoalCubit>().applyFilter(
                        contextFilter: selectedContext,
                        targetDateFilter: selectedTargetDate,
                      );
                }

                // if (result['groupBy'] != null && (result['groupBy'] as String).isNotEmpty) {
                //   final groupBy = result['groupBy'] as String;
                //   context.read<GoalCubit>().applyGrouping(groupBy: groupBy);
                // }
              },
              child: const Icon(Icons.filter_alt),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Row 2: Add + More
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton.small(
              heroTag: 'addGoalFab',
              tooltip: 'Add Goal',
              onPressed: () => _onCreateGoal(context),
              child: const Icon(Icons.add),
            ),
            const SizedBox(width: 12),
            FloatingActionButton.small(
              heroTag: 'moreFab',
              tooltip: 'More actions',
              onPressed: () => _showActionsSheet(context),
              child: const Icon(Icons.more_vert),
            ),
          ],
        ),
      ],
    );
  }

  /// Shows the bottom sheet with additional actions (Add, Export, Import).
  ///
  /// Export:
  ///  - Reads current state from cubit; if loaded, exports that list, otherwise exports empty list.
  /// Import:
  ///  - Calls importGoalsFromXlsx which opens file picker and performs import.
  void _showActionsSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12.0)),
      ),
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Column(
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
                  Navigator.of(ctx).pop();
                  _onCreateGoal(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.file_download),
                title: const Text('Export'),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final state = context.read<GoalCubit>().state;
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
                  Navigator.of(ctx).pop();
                  importGoalsFromXlsx(context);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  /// Opens the create-goal form bottom sheet and delegates creation to the cubit.
  ///
  /// Note: The onSubmit callback currently assumes targetDate and contxt are non-null;
  /// the form must enforce these or adapt the call signature accordingly.
  void _onCreateGoal(BuildContext context) {
    final cubit = context.read<GoalCubit>();
    GoalFormBottomSheet.show(
      context,
      title: 'Create Goal',
      onSubmit: (name, desc, targetDate, contxt, isCompleted) async {
        await cubit.addGoal(name, desc, targetDate, contxt, isCompleted);
      },
    );
  }

  /// Opens the edit form pre-filled with [goal] and delegates update/delete to the cubit.
  ///
  /// Notes:
  ///  - onSubmit passes isCompleted through — ensure cubit.editGoal signature matches.
  ///  - onDelete delegates to removeGoal on the cubit.
  void _onEditGoal(BuildContext context, Goal goal) {
    final cubit = context.read<GoalCubit>();
    GoalFormBottomSheet.show(
      context,
      title: 'Edit Goal',
      initialName: goal.name,
      initialDescription: goal.description,
      initialTargetDate: goal.targetDate,
      initialContext: goal.context,
      initialIsCompleted: goal.isCompleted,
      onSubmit: (name, desc, targetDate, contxt, isCompleted) async {
        await cubit.editGoal(goal.id, name, desc, targetDate, contxt, isCompleted);
      },
      onDelete: () async {
        context.read<GoalCubit>().removeGoal(goal.id);
      },
    );
  }
}
