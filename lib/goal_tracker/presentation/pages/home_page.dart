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
import '../../core/constants.dart';
import 'goal_list_page.dart';
import 'milestone_list_page.dart';
import 'task_list_page.dart';

/// The app's landing page providing dashboard insights and navigation.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AllTracker'),
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
            _QuickActionsSection(colorScheme: cs),
          ],
        ),
      ),
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
                    color: Colors.grey,
                  ),
                  _StatusChip(
                    label: 'In Progress',
                    count: inProgress,
                    color: Colors.blue,
                  ),
                  _StatusChip(
                    label: 'Complete',
                    count: completed,
                    color: Colors.green,
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
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            '$count',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color,
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

/// Quick actions for direct navigation
class _QuickActionsSection extends StatelessWidget {
  const _QuickActionsSection({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            label: 'Goals',
            icon: Icons.track_changes,
            color: colorScheme.primary,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const GoalListPage()),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            label: 'Milestones',
            icon: Icons.flag,
            color: colorScheme.secondary,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MilestoneListPage()),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            label: 'Tasks',
            icon: Icons.task_alt,
            color: colorScheme.tertiary,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TaskListPage()),
              );
            },
          ),
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
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
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

