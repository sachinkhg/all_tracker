import 'package:all_tracker/goal_tracker/presentation/bloc/task/task_list_cubit.dart';
import 'package:all_tracker/goal_tracker/presentation/pages/task_list_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../util/common_util.dart';

import '../../../widgets/shared_button.dart';
import '../../../widgets/shared_timeline_list.dart';
import '../../../widgets/shared_card.dart';

import '../../domain/entities/goal.dart';
import '../../domain/entities/milestone.dart';

// Use cases + DI
import '../../domain/usecases/goal_usecases.dart';
import '../../domain/usecases/milestone_usecases.dart';
import '../../di/service_locator.dart'; // exposes `getIt`

// Page-scoped Cubit for milestones
// Create this file if you don't have it yet, or adjust the import path:
import '../bloc/goal/goal_bloc.dart';
import '../bloc/goal/goal_list_cubit.dart';
import '../bloc/milestone/milestone_bloc.dart';
import '../bloc/milestone/milestone_list_cubit.dart';

import '../bloc/task/task_bloc.dart';
import '../widgets/add_goal_bottom_sheet.dart';
import '../widgets/add_milestone_bottom_sheet.dart';

class MilestoneListPage extends StatefulWidget {
  final String goalId;

  const MilestoneListPage({super.key, required this.goalId});

  @override
  State createState() => _MilestoneListPageState();
}

class _MilestoneListPageState extends State<MilestoneListPage> {
  late final MilestoneListCubit _cubit;

  Goal? _goal;
  bool _loadingGoal = true;

  @override
  void initState() {
    super.initState();

    // Page-scoped cubit (no events, simple methods)
    _cubit = MilestoneListCubit(
      goalId: widget.goalId,
      getMilestonesForGoal: getIt<GetMilestonesForGoal>(),
      addMilestone: getIt<AddMilestone>(),
      updateMilestone: getIt<UpdateMilestone>(),
      deleteMilestone: getIt<DeleteMilestone>(),
    )..load();

    // Load the goal for header/title
    _loadGoalTitle();
  }

  Future<void> _loadGoalTitle() async {
    try {
      final g = await getIt<GetGoalById>()(widget.goalId);
      if (!mounted) return;
      setState(() {
        _goal = g;
        _loadingGoal = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingGoal = false);
    }
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<void> _deleteGoalAndMilestones(BuildContext context) async {
    final theme = Theme.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Goal',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onError,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this goal and all its milestones?',
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.onPrimary,
          ),
        ),
        actions: [
          SharedButton(
            label: 'No',
            onPressed: () => Navigator.of(context).pop(false),
            backgroundColor: theme.colorScheme.onPrimary,
            textColor: theme.colorScheme.onError,
          ),
          SharedButton(
            label: 'Yes',
            onPressed: () => Navigator.of(context).pop(true),
            backgroundColor: theme.colorScheme.onError,
            textColor: theme.colorScheme.onPrimary,
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      // Option-2 model: milestones link to goal via associatedGoalID
      final milestones = await getIt<GetMilestonesForGoal>()(widget.goalId);
      for (final m in milestones) {
        await getIt<DeleteMilestone>()(m.id);
      }
      await getIt<DeleteGoal>()(widget.goalId);

      if (mounted) {
        Navigator.of(context).pop(); // go back to goal list
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<MilestoneListCubit, MilestoneListState>(
        builder: (context, s) {
          if (s.loading || _loadingGoal) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (s.error != null) {
            return Scaffold(body: Center(child: Text('Error: ${s.error}')));
          }

          final goal = _goal;
          if (goal == null) {
            // Goal was deleted or not found
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/goal-list');
              }
            });
            return const SizedBox.shrink();
          }

          final milestones = s.milestones;

          // Sort/group milestones for timeline
          final sortedMilestones = sortListByDate(milestones, (m) => m.targetDate);
          final byMonth = groupByMonthYear(sortedMilestones, (m) => m.targetDate);
          final monthKeys = byMonth.keys.toList()..sort();

          return Scaffold(
            appBar: AppBar(title: const Text("Milestones")),
            body: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width * 0.06,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Goal header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Goal: ${goal.title}',
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(color: theme.colorScheme.onPrimary),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: theme.colorScheme.onError),
                        tooltip: "Delete Goal",
                        onPressed: () => _deleteGoalAndMilestones(context),
                      ),
                    ],
                  ),
                  if (goal.description.isNotEmpty)
                    Text(
                      goal.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                    ),
                  if (goal.targetDate != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Target Date: ${DateFormat('dd/MM/yyyy').format(goal.targetDate!)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Milestone list
                  Expanded(
                    child: milestones.isEmpty
                        ? const Center(child: Text('No milestones found'))
                        : ListView(
                            children: monthKeys
                                .map((month) => MonthTimelineList<Milestone>(
                                      monthKeys: [month],
                                      itemsByMonth: {month: byMonth[month]!},
                                      itemBuilder: milestoneItemBuilder,
                                    ))
                                .toList(),
                          ),
                  ),
                ],
              ),
            ),
            bottomNavigationBar: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: SharedButton(
                            label: "Add Milestone",
                            icon: Icons.add,
                            onPressed: () {
                              openAddMilestonePopup(
                                context,
                                goal,
                                milestoneListCubit: context.read<MilestoneListCubit>(), // refresh milestone list
                                goalListCubit: context.read<GoalListCubit>(),           // also refresh aggregated goals
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SharedButton(
                            label: "Edit Goal",
                            icon: Icons.edit,
                            onPressed: () async {
                              await openEditGoalPopup(
                                context,
                                goal,
                                goalListCubit: context.read<GoalListCubit>(),
                              );
                              // re-fetch the goal so the header reflects latest title/date/desc
                              await _loadGoalTitle();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  BottomNavigationBar(
                    selectedItemColor: theme.colorScheme.onSurface,
                    unselectedItemColor: theme.colorScheme.primary,
                    backgroundColor: theme.colorScheme.onPrimary,
                    currentIndex: 0,
                    selectedLabelStyle:
                        const TextStyle(fontSize: 9.0, fontWeight: FontWeight.w600),
                    unselectedLabelStyle: const TextStyle(fontSize: 8.0),
                    onTap: (index) {
                      if (index == 0) {
                        Navigator.pushReplacementNamed(context, '/home');
                      } else if (index == 1) {
                        Navigator.of(context).pop();
                      }
                    },
                    items: const [
                      BottomNavigationBarItem(
                        icon: Icon(Icons.home),
                        label: 'Home',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.swipe_up_alt),
                        label: 'Goals',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

Widget milestoneItemBuilder(BuildContext context, Milestone milestone) {
  return SharedCard(
    icon: Icons.check_circle_outline,
    title: milestone.title,
    subtitle2: milestone.targetDate != null
        ? DateFormat('dd/MM/yyyy').format(milestone.targetDate!)
        : 'No target date',
    onCardTap: () {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TaskListPage(milestoneId: milestone.id),
        ),
      );
    },
  );
}
