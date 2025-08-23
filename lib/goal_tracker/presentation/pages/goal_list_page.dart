import 'package:all_tracker/goal_tracker/presentation/bloc/milestone/milestone_list_cubit.dart';
import 'package:all_tracker/goal_tracker/presentation/bloc/task/task_list_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../util/common_util.dart';
import '../../../widgets/shared_timeline_list.dart';
import '../../domain/entities/goal.dart';
import '../../domain/entities/milestone.dart';

// Usecases + DI
import '../../domain/usecases/goal_usecases.dart';
import '../../domain/usecases/milestone_usecases.dart';
import '../../di/service_locator.dart'; // exposes `getIt`

// ✅ Use the Cubit version
import '../bloc/goal/goal_list_cubit.dart';

// UI widgets
import '../../../widgets/shared_card.dart';
import '../../../widgets/shared_button.dart';

// Milestone flow (still using MilestoneBloc in your project)
import '../bloc/milestone/milestone_bloc.dart';

import '../widgets/add_goal_bottom_sheet.dart';
import '../widgets/add_milestone_bottom_sheet.dart';
import 'milestone_list_page.dart';

class GoalListPage extends StatefulWidget {
  const GoalListPage({super.key});

  @override
  State<GoalListPage> createState() => _GoalListPageState();
}

class _GoalListPageState extends State<GoalListPage> {
  late final GoalListCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = GoalListCubit(
      getGoals: getIt<GetGoals>(),
      getMilestonesForGoal: getIt<GetMilestonesForGoal>(),
    )..load();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  void _onNavBarTap(int index) {
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/');
    } else if (index == 1) {
      Navigator.pushReplacementNamed(context, '/settings');
    }
  }

  // ===== Common helper for Option 2 (Milestone.associatedGoalID) =====
  List<Milestone> _milestonesForGoal(Map<String, Milestone> all, Goal goal) {
    return all.values.where((m) => m.associatedGoalID == goal.id).toList();
  }

  List<String> _milestoneIdsForGoal(Map<String, Milestone> all, Goal goal) {
    return _milestonesForGoal(all, goal).map((m) => m.id).toList();
  }
  // ==================================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        appBar: AppBar(title: const Text("Goals")),
        body: SafeArea(
          child: BlocBuilder<GoalListCubit, GoalListState>(
            builder: (context, s) {
              if (s.loading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (s.error != null) {
                return Center(child: Text('Error: ${s.error}'));
              }

              final goals = s.goals;
              final allMilestonesMap = s.allMilestonesMap;

              final sortedGoals =
                  sortListByDate(goals, (goal) => goal.targetDate);
              final byYear = groupByYear<Goal>(
                  sortedGoals, (goal) => goal.targetDate);
              final undated = filterItemsWithNullDate<Goal>(
                  sortedGoals, (goal) => goal.targetDate);

              // Sort years ascending
              final yearKeys = byYear.keys.toList()..sort();

              return ListView(
                padding:
                    const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
                children: [
                  YearTimelineList<Goal>(
                    yearKeys: yearKeys,
                    itemsByYear: byYear,
                    itemBuilder: (context, goal) =>
                        buildGoalCard(context, goal, allMilestonesMap),
                  ),
                  if (undated.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 32.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'No Target Date',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          for (final goal in undated)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: SharedCard(
                                // onCardTap: () {
                                //   Navigator.of(context).push(
                                //     MaterialPageRoute(
                                //       builder: (_) => MultiBlocProvider(
                                //         providers: [
                                //           BlocProvider.value(value: context.read<GoalListCubit>()),
                                //           // pass through MilestoneBloc if MilestoneListPage depends on it
                                //           BlocProvider.value(
                                //             value: context.read<MilestoneBloc>(),
                                //           ),
                                //         ],
                                //         child: MilestoneListPage(goalId: goal.id),
                                //       ),
                                //     ),
                                //   );
                                // },

                                icon: Icons.flag,
                                iconBackgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                title: goal.title,
                                actionButtonText: "ADD MILESTONE",
                              onActionPressed: () => openAddMilestonePopup(
                                context,
                                goal,
                                goalListCubit: context.read<GoalListCubit>(),
                              ),
                                actionListItems:
                                    _milestoneIdsForGoal(allMilestonesMap, goal)
                                            .isNotEmpty
                                        ? buildLimitedMilestonesList(
                                            _milestoneIdsForGoal(
                                                allMilestonesMap, goal),
                                            allMilestonesMap,
                                          )
                                        : null,
                              ),
                            ),
                        ],
                      ),
                    ),
                  if (yearKeys.isEmpty && undated.isEmpty)
                    const Center(child: Text('No goals found')),
                ],
              );
            },
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Add Goal button
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: SharedButton(
                    label: "Add Goal",
                    icon: Icons.add,
                    onPressed: () => openAddGoalPopup(context, goalListCubit: _cubit),
                  ),
                ),
              ),

              // Bottom Nav Bar
              BottomNavigationBar(
                selectedItemColor: theme.colorScheme.onSurface,
                unselectedItemColor: theme.colorScheme.primary,
                backgroundColor: theme.colorScheme.onPrimary,
                selectedLabelStyle: const TextStyle(
                    fontSize: 9.0, fontWeight: FontWeight.w600),
                unselectedLabelStyle: const TextStyle(fontSize: 8.0),
                onTap: _onNavBarTap,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.settings),
                    label: 'Settings',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

List<String> buildLimitedMilestonesList(
  List<String> milestoneIds,
  Map<String, Milestone> allMilestones,
) {
  final milestones = milestoneIds
      .map((id) => allMilestones[id])
      .whereType<Milestone>()
      .toList();

  final sortedMilestones =
      sortListByDate(milestones, (milestone) => milestone.targetDate);

  if (sortedMilestones.length <= 3) {
    return sortedMilestones.map((m) => m.title).toList();
  } else {
    return sortedMilestones.take(3).map((m) => m.title).toList()
      ..add('... and ${sortedMilestones.length - 3} more');
  }
}

Widget buildGoalCard(
  BuildContext context,
  Goal goal,
  Map<String, Milestone> allMilestonesMap,
) {
  // Get this goal's milestones via associatedGoalID (Option 2)
  final milestonesForGoal = allMilestonesMap.values
      .where((m) => m.associatedGoalID == goal.id)
      .toList();

  final milestoneIdsForGoal = milestonesForGoal.map((m) => m.id).toList();

  return SharedCard(
    icon: Icons.flag,
    title: goal.title,
    onCardTap: () {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MultiBlocProvider(
            providers: [
              BlocProvider.value(value: context.read<GoalListCubit>()),
              // pass through MilestoneBloc if MilestoneListPage depends on it
              BlocProvider.value(
                value: context.read<MilestoneBloc>(),
              ),
            ],
            child: MilestoneListPage(goalId: goal.id),
          ),
        ),
      );
    },
    subtitle2Icon: Icons.calendar_today,
    subtitle2: goal.targetDate != null
        ? DateFormat('dd/MM/yyyy').format(goal.targetDate!)
        : null,
    actionButtonText: "ADD MILESTONE",
    onActionPressed: () => openAddMilestonePopup(
      context,
      goal,
      goalListCubit: context.read<GoalListCubit>(), // refresh goals after save
    ),
    actionListItems: milestoneIdsForGoal.isNotEmpty
        ? buildLimitedMilestonesList(milestoneIdsForGoal, allMilestonesMap)
        : null,
  );
}
