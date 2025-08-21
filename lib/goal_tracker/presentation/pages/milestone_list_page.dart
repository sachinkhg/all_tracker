import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../util/common_util.dart';

import '../../../widgets/shared_button.dart';
import '../../../widgets/shared_timeline_list.dart';
import '../../../widgets/shared_card.dart';

import '../../domain/entities/goal.dart';
import '../../domain/entities/milestone.dart';

import '../bloc/goal/goal_bloc.dart';
import '../bloc/goal/goal_event.dart';
import '../bloc/goal/goal_state.dart';

import '../widgets/add_goal_bottom_sheet.dart';
import '../widgets/add_milestone_bottom_sheet.dart';

class MilestoneListPage extends StatefulWidget {
  final String goalId;

  const MilestoneListPage({super.key, required this.goalId});

  @override
  State createState() => _MilestoneListPageState();
}

class _MilestoneListPageState extends State<MilestoneListPage> {
  @override
  Widget build(BuildContext context) {
    
      return BlocBuilder<GoalBloc, GoalState>(
        builder: (context, state) {
          if (state is GoalLoaded) {
            final goal = state.goals.where((g) => g.id == widget.goalId).cast<Goal?>().firstWhere((g) => g != null, orElse: () => null);
            if (goal == null) {
              // Goal was deleted or not found, navigate back or show a fallback
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  Navigator.of(context).pushReplacementNamed('/goal-list');
                }
              });
              return const SizedBox.shrink();
            }
            final allMilestonesMap = state.allMilestonesMap;

            final milestones = goal.milestoneIds
                .map((id) => allMilestonesMap[id])
                .whereType<Milestone>()
                .toList();

            final sortedMilestones =
                sortListByDate(milestones, (m) => m.targetDate);

            final byMonth = groupByMonthYear(sortedMilestones, (m) => m.targetDate);
            final monthKeys = byMonth.keys.toList()..sort();

            final theme = Theme.of(context);

            return Scaffold(
              appBar: AppBar(title: const Text("Milestones")),
              body: Padding(
                padding: EdgeInsets.only(
                  // top: MediaQuery.of(context).size.height * 0.02,
                  left: MediaQuery.of(context).size.width * 0.06,
                  right: MediaQuery.of(context).size.width * 0.06,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Always show Goal details here
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
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text(
                                  'Delete Goal',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(color: theme.colorScheme.onError),
                                ),
                                content: Text(
                                  'Are you sure you want to delete this goal and all its milestones?',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(color: theme.colorScheme.onPrimary),
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
                              // Dispatch deletion event, navigation handled by BlocListener
                              this.context.read<GoalBloc>().add(
                                  DeleteGoalAndMilestonesEvent(goal.id, goal.milestoneIds));
                            }
                          },
                        ),
                      ],
                    ),
                    // const SizedBox(height: 4),
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

                    // Then milestone list or "No milestones found"
                    Expanded(
                      child: milestones.isEmpty
                          ? const Center(child: Text('No milestones found'))
                          : ListView(
                              children: monthKeys
                                  .map((month) => MonthTimelineList(
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
                                openAddMilestonePopup(context, goal);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SharedButton(
                              label: "Edit Goal",
                              icon: Icons.edit,
                              onPressed: () {
                                openEditGoalPopup(context, goal);
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
          }

          if (state is GoalLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is GoalError) {
            return Center(child: Text('Error: ${state.message}'));
          }

          return const SizedBox.shrink();
        },
      
    );
  }

  Widget milestoneItemBuilder(BuildContext context, Milestone milestone) {
    return SharedCard(
      icon: Icons.check_circle_outline,
      title: milestone.title,
      subtitle2: milestone.targetDate != null
          ? DateFormat('dd/MM/yyyy').format(milestone.targetDate!)
          : 'No target date',
    );
  }
}
