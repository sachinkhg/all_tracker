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

// ./lib/goal_tracker/presentation/pages/goal_list_page.dart
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
import '../../../widgets/bottom_sheet_helpers.dart'; // <- centralized helper

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
            Expanded(
              child: BlocBuilder<GoalCubit, GoalState>(
                builder: (context, state) {
                  if (state is GoalsLoading) {
                    return const LoadingView();
                  }

                  if (state is GoalsLoaded) {
                    final goals = state.goals;
                    final visible = state.visibleFields;

                    // compute derived booleans ONCE here and reuse
                    final cubit = context.read<GoalCubit>();
                    // use cubit's hasActiveFilters getter
                    final bool filterActive = cubit.hasActiveFilters;

                    if (goals.isEmpty) {
                      final message = filterActive ? 'No goals found' : 'No goals yet';

                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(message, style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 8),
                            if (filterActive)
                              OutlinedButton(
                                onPressed: () {
                                  context.read<GoalCubit>().clearFilters();
                                },
                                child: const Text('No goals found. Clear filters?'),
                              ),
                          ],
                        ),
                      );
                    }

                    return Column(
                      children: [
                        if (filterActive) _buildFilterHeader(context, cubit),
                        Expanded(
                          child: ListView.builder(
                            itemCount: goals.length,
                            itemBuilder: (context, index) {
                              final g = goals[index];
                              return GoalListItem(
                                key: ValueKey(g.id),
                                id: g.id,
                                title: g.name,
                                description: g.description ?? '',
                                targetDate: g.targetDate,
                                contextValue: g.context,
                                visibleFields: visible,
                                filterActive: filterActive,
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

  Widget _buildFilterHeader(BuildContext context, GoalCubit cubit) {
    // NOW the UI reads the summary from the cubit
    final summary = cubit.filterSummary;

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
              try {
                cubit.applyGrouping(groupBy: '');
              } catch (_) {
                // ignore if not supported
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _editFilters(BuildContext context, GoalCubit cubit) async {
    final result = await showAppBottomSheet<Map<String, dynamic>?>(
      context,
      FilterGroupBottomSheet(
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

  Widget _buildFabColumn(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton.small(
              heroTag: 'viewFab',
              tooltip: 'Change View',
              onPressed: () async {
                final cubit = context.read<GoalCubit>();
                final Map<String, bool>? initial = cubit.visibleFields;

                final result = await showAppBottomSheet<Map<String, bool>?>(
                  context,
                  ViewFieldsBottomSheet(initial: initial),
                );

                if (result == null) return;

                cubit.setVisibleFields(result);
              },
              child: const Icon(Icons.remove_red_eye),
            ),

            const SizedBox(width: 8),
            FloatingActionButton.small(
              heroTag: 'filterGroupFab',
              tooltip: 'Filter & Group',
              onPressed: () async {
                final cubit = context.read<GoalCubit>();
                final result = await showAppBottomSheet<Map<String, dynamic>?>(
                  context,
                  FilterGroupBottomSheet(
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
              },
              child: const Icon(Icons.filter_alt),
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

  void _showActionsSheet(BuildContext context) {
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
            _onCreateGoal(context);
          },
        ),
        ListTile(
          leading: const Icon(Icons.file_download),
          title: const Text('Export'),
          onTap: () async {
            Navigator.of(context).pop();
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
