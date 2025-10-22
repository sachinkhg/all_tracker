/*
  purpose:
    - Defines the app's landing screen (entry point UI) within the presentation layer.
    - Provides a dashboard showing insights on Goals, Milestones, and Tasks.
    - Provides navigation entry points to list pages and reorganize view.
    - Designed to be lightweight — minimal business logic, focuses on UI and navigation.

  app lifecycle role:
    - Serves as the first interactive page after app initialization and DI setup (see main.dart).
    - Displays real-time statistics from Hive boxes.

  navigation & compatibility guidance:
    - Uses [MaterialPageRoute] for navigation to keep navigation stack explicit and simple.
    - If deep-linking, modular routing, or shell navigation is later introduced,
      update this navigation logic and document in ARCHITECTURE.md.
*/

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../data/models/goal_model.dart';
import '../../data/models/milestone_model.dart';
import '../../data/models/task_model.dart';
import '../../data/models/habit_model.dart';
import '../../domain/entities/goal.dart';
import '../../domain/entities/milestone.dart';
import '../../core/constants.dart';
import '../../core/injection.dart';
import '../bloc/goal_cubit.dart';
import '../bloc/goal_state.dart';
import '../bloc/milestone_cubit.dart';
import '../bloc/milestone_state.dart';
import '../bloc/task_cubit.dart';
import '../widgets/goal_form_bottom_sheet.dart';
import '../widgets/milestone_form_bottom_sheet.dart';
import '../widgets/task_form_bottom_sheet.dart';
import '../widgets/habit_form_bottom_sheet.dart';
import 'goal_list_page.dart';
import 'milestone_list_page.dart';
import 'task_list_page.dart';
import 'habit_list_page.dart';
import 'settings_page.dart';
import '../bloc/habit_cubit.dart';

/// The app's landing page providing dashboard insights and navigation.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final GoalCubit _goalCubit;
  late final MilestoneCubit _milestoneCubit;
  late final TaskCubit _taskCubit;
  late final HabitCubit _habitCubit;

  @override
  void initState() {
    super.initState();
    _goalCubit = createGoalCubit();
    _milestoneCubit = createMilestoneCubit();
    _taskCubit = createTaskCubit();
    _habitCubit = createHabitCubit();
    
    // Load initial data
    _goalCubit.loadGoals();
    _milestoneCubit.loadMilestones();
    _taskCubit.loadTasks();
  }

  @override
  void dispose() {
    _goalCubit.close();
    _milestoneCubit.close();
    _taskCubit.close();
    _habitCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AllTracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
            },
          ),
        ],
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Dashboard Section
            Text(
              'Dashboard',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            const _DashboardSection(),
            const SizedBox(height: 32),

            // Quick Actions Section
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _QuickActionsSection(
              colorScheme: cs,
              onAddGoal: _addGoal,
              onAddMilestone: _addMilestone,
              onAddTask: _addTask,
              onAddHabit: _addHabit,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addGoal() async {
    await GoalFormBottomSheet.show(
      context,
      title: 'Add Goal',
      onSubmit: (name, description, targetDate, context, isCompleted) async {
        await _goalCubit.addGoal(name, description, targetDate, context, isCompleted);
      },
    );
  }

  Future<void> _addMilestone() async {
    // Get goals for the dropdown
    final goals = _goalCubit.state is GoalsLoaded 
        ? ((_goalCubit.state as GoalsLoaded).goals)
        : <Goal>[];
    
    final goalOptions = goals.map((goal) => '${goal.id}::${goal.name}').toList();
    
    if (goalOptions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please create a goal first before adding a milestone')),
      );
      return;
    }

    await MilestoneFormBottomSheet.show(
      context,
      title: 'Add Milestone',
      goalOptions: goalOptions,
      onSubmit: (name, description, plannedValue, actualValue, targetDate, goalId) async {
        await _milestoneCubit.addMilestone(
          name: name,
          description: description,
          plannedValue: plannedValue,
          actualValue: actualValue,
          targetDate: targetDate,
          goalId: goalId,
        );
      },
    );
  }

  Future<void> _addTask() async {
    // Get milestones for the dropdown
    final milestones = _milestoneCubit.state is MilestonesLoaded 
        ? ((_milestoneCubit.state as MilestonesLoaded).milestones)
        : <Milestone>[];
    
    final milestoneOptions = milestones.map((milestone) => '${milestone.id}::${milestone.name}').toList();
    
    if (milestoneOptions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please create a milestone first before adding a task')),
      );
      return;
    }

    // Create milestone to goal mapping for the task form
    final milestoneGoalMap = <String, String>{};
    for (final milestone in milestones) {
      // Find the goal name for this milestone
      final goals = _goalCubit.state is GoalsLoaded 
          ? ((_goalCubit.state as GoalsLoaded).goals)
          : <Goal>[];
      try {
        final goal = goals.firstWhere((g) => g.id == milestone.goalId);
        milestoneGoalMap[milestone.id] = goal.name;
      } catch (e) {
        // Goal not found, skip this milestone
      }
    }

    await TaskFormBottomSheet.show(
      context,
      title: 'Add Task',
      milestoneOptions: milestoneOptions,
      milestoneGoalMap: milestoneGoalMap,
      onSubmit: (name, targetDate, milestoneId, status) async {
        await _taskCubit.addTask(
          name: name,
          targetDate: targetDate,
          milestoneId: milestoneId,
          status: status,
        );
      },
    );
  }

  Future<void> _addHabit() async {
    // Build milestone options and milestone->goal map from Hive
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

    final milestoneOptions = milestones.map((m) => '${m.id}::${m.name}').toList();

    if (milestoneOptions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please create a milestone first before adding a habit')),
      );
      return;
    }

    await HabitFormBottomSheet.show(
      context,
      title: 'Add Habit',
      milestoneOptions: milestoneOptions,
      milestoneGoalMap: goalMap,
      onSubmit: (name, description, milestoneId, rrule, targetCompletions, isActive) async {
        await _habitCubit.addHabit(
          name: name,
          description: description,
          milestoneId: milestoneId,
          rrule: rrule,
          targetCompletions: targetCompletions,
          isActive: isActive,
        );
      },
    );
  }
}

/// Dashboard section showing insights and statistics
class _DashboardSection extends StatelessWidget {
  const _DashboardSection();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<GoalModel>(goalBoxName).listenable(),
      builder: (context, Box<GoalModel> goalBox, _) {
        return ValueListenableBuilder(
          valueListenable: Hive.box<MilestoneModel>(milestoneBoxName).listenable(),
          builder: (context, Box<MilestoneModel> milestoneBox, _) {
            return ValueListenableBuilder(
              valueListenable: Hive.box<TaskModel>(taskBoxName).listenable(),
              builder: (context, Box<TaskModel> taskBox, _) {
                // Calculate statistics
                final goals = goalBox.values.toList();
                final milestones = milestoneBox.values.toList();
                final tasks = taskBox.values.toList();

                final totalGoals = goals.length;
                final completedGoals = goals.where((g) => g.isCompleted).length;
                
                final totalMilestones = milestones.length;
                final completedMilestones = milestones.where((m) {
                  if (m.plannedValue != null && m.actualValue != null) {
                    return m.actualValue! >= m.plannedValue!;
                  }
                  return false;
                }).length;
                
                final totalTasks = tasks.length;
                final completedTasks = tasks.where((t) => t.status == 'Complete').length;
                final inProgressTasks = tasks.where((t) => t.status == 'In Progress').length;

                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _InsightCard(
                            title: 'Goals',
                            total: totalGoals,
                            completed: completedGoals,
                            icon: Icons.track_changes,
                            color: Theme.of(context).colorScheme.primary,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const GoalListPage()),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _InsightCard(
                            title: 'Milestones',
                            total: totalMilestones,
                            completed: completedMilestones,
                            icon: Icons.flag,
                            color: Theme.of(context).colorScheme.secondary,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const MilestoneListPage()),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _TaskInsightCard(
                      total: totalTasks,
                      completed: completedTasks,
                      inProgress: inProgressTasks,
                      color: Theme.of(context).colorScheme.tertiary,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const TaskListPage()),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _HabitInsightCard(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const HabitListPage()),
                        );
                      },
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

/// Individual insight card for Goals and Milestones
class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.title,
    required this.total,
    required this.completed,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final int total;
  final int completed;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? completed / total : 0.0;
    
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 28),
                  const Spacer(),
                  Text(
                    '$completed/$total',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: color.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${(progress * 100).toStringAsFixed(0)}% Complete',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Insight card specifically for Tasks with status breakdown
class _TaskInsightCard extends StatelessWidget {
  const _TaskInsightCard({
    required this.total,
    required this.completed,
    required this.inProgress,
    required this.color,
    required this.onTap,
  });

  final int total;
  final int completed;
  final int inProgress;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final toDo = total - completed - inProgress;
    final progress = total > 0 ? completed / total : 0.0;
    
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.task_alt, color: color, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    'Tasks',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  Text(
                    '$total Total',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _StatusChip(
                    label: 'To Do',
                    count: toDo,
                  ),
                  _StatusChip(
                    label: 'In Progress',
                    count: inProgress,
                  ),
                  _StatusChip(
                    label: 'Complete',
                    count: completed,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: color.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${(progress * 100).toStringAsFixed(0)}% Complete',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Status chip for task status display
class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.count,
  });

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Map status label to ColorScheme tokens for background/foreground
    Color background;
    Color foreground;
    switch (label) {
      case 'Complete':
        background = cs.tertiaryContainer;
        foreground = cs.onTertiaryContainer;
        break;
      case 'In Progress':
        background = cs.primaryContainer;
        foreground = cs.onPrimaryContainer;
        break;
      case 'To Do':
      default:
        background = cs.secondaryContainer;
        foreground = cs.onSecondaryContainer;
        break;
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            '$count',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// Quick actions for adding new items
class _QuickActionsSection extends StatelessWidget {
  const _QuickActionsSection({
    required this.colorScheme,
    required this.onAddGoal,
    required this.onAddMilestone,
    required this.onAddTask,
    required this.onAddHabit,
  });

  final ColorScheme colorScheme;
  final VoidCallback onAddGoal;
  final VoidCallback onAddMilestone;
  final VoidCallback onAddTask;
  final VoidCallback onAddHabit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                label: 'Add Goal',
                icon: Icons.add,
                color: colorScheme.primary,
                onPressed: onAddGoal,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                label: 'Add Milestone',
                icon: Icons.add,
                color: colorScheme.primary,
                onPressed: onAddMilestone,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                label: 'Add Task',
                icon: Icons.add,
                color: colorScheme.primary,
                onPressed: onAddTask,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                label: 'Add Habit',
                icon: Icons.add,
                color: colorScheme.primary,
                onPressed: onAddHabit,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Action button widget
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Determine foreground color based on which scheme color is used for background
    Color fg;
    if (color == cs.primary) {
      fg = cs.onPrimary;
    } else if (color == cs.secondary) {
      fg = cs.onSecondary;
    } else if (color == cs.tertiary) {
      fg = cs.onTertiary;
    } else {
      fg = cs.onPrimary;
    }

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: fg,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        elevation: 2,
      ),
      onPressed: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 32),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Insight card for Habits
class _HabitInsightCard extends StatelessWidget {
  const _HabitInsightCard({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box<HabitModel>>(
      valueListenable: Hive.box<HabitModel>(habitBoxName).listenable(),
      builder: (context, box, _) {
        final habits = box.values.toList();
        final totalHabits = habits.length;
        final activeHabits = habits.where((h) => h.isActive).length;
        final inactiveHabits = habits.where((h) => !h.isActive).length;

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.checklist,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Habits',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$totalHabits',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildStatChip(
                        'Active',
                        '$activeHabits',
                        Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      _buildStatChip(
                        'Inactive',
                        '$inactiveHabits',
                        Theme.of(context).colorScheme.outline,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

