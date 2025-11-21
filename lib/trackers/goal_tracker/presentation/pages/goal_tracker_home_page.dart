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
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/design_tokens.dart';
import 'package:all_tracker/trackers/goal_tracker/core/app_icons.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../data/models/goal_model.dart';
import '../../data/models/milestone_model.dart';
import '../../data/models/task_model.dart';
import '../../data/models/habit_model.dart';
import '../../domain/entities/goal.dart';
import '../../domain/entities/milestone.dart';
import '../../core/constants.dart';
import '../../core/injection.dart';
import '../../../../features/backup/core/backup_scheduler_service.dart';
import '../../../../features/backup/core/injection.dart';
import '../bloc/goal_cubit.dart';
import '../bloc/goal_state.dart';
import '../bloc/milestone_cubit.dart';
import '../bloc/milestone_state.dart';
import '../bloc/task_cubit.dart';
import '../widgets/goal_form_bottom_sheet.dart';
import '../widgets/milestone_form_bottom_sheet.dart';
import '../widgets/task_form_bottom_sheet.dart';
import '../widgets/habit_form_bottom_sheet.dart';
import '../widgets/voice_note_recorder_bottom_sheet.dart';
import '../bloc/voice_note_cubit.dart';
import '../../domain/usecases/voice_note/voice_entity_type.dart';
import 'goal_list_page.dart';
import 'milestone_list_page.dart';
import 'task_list_page.dart';
import 'habit_list_page.dart';
import '../../../../pages/settings_page.dart';
import '../bloc/habit_cubit.dart';
import '../../../../widgets/bottom_sheet_helpers.dart';
import '../../../../pages/app_home_page.dart';
import '../../../../widgets/app_drawer.dart';

/// The app's landing page providing dashboard insights and navigation.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  late final GoalCubit _goalCubit;
  late final MilestoneCubit _milestoneCubit;
  late final TaskCubit _taskCubit;
  late final HabitCubit _habitCubit;
  late final BackupSchedulerService _backupScheduler;
  late final VoiceNoteCubit _voiceNoteCubit;
  
  // Filter state for home page
  String? _targetDateFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    _goalCubit = createGoalCubit();
    _milestoneCubit = createMilestoneCubit();
    _taskCubit = createTaskCubit();
    _habitCubit = createHabitCubit();
    _backupScheduler = createBackupSchedulerService();
    _voiceNoteCubit = createVoiceNoteCubit();
    
    // Load initial data
    _goalCubit.loadGoals();
    _milestoneCubit.loadMilestones();
    _taskCubit.loadTasks();
    
    // Check for automatic backup on app startup
    _checkAutomaticBackup();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _goalCubit.close();
    _milestoneCubit.close();
    _taskCubit.close();
    _habitCubit.close();
    _voiceNoteCubit.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Check for automatic backup when app comes to foreground
    if (state == AppLifecycleState.resumed) {
      _checkAutomaticBackup();
    }
  }

  Future<void> _checkAutomaticBackup() async {
    // Run in background without blocking UI
    _backupScheduler.checkAndRunBackup();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Goal Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            tooltip: 'Home',
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const AppHomePage()),
                (route) => false,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
            },
          ),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: AppGradients.appBar(cs),
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: cs.onPrimary,
        iconTheme: IconThemeData(
          color: cs.brightness == Brightness.dark
              ? Colors.white.withOpacity(0.95)
              : Colors.black87,
          opacity: 1.0,
        ),
        actionsIconTheme: IconThemeData(
          color: cs.brightness == Brightness.dark
              ? Colors.white.withOpacity(0.95)
              : Colors.black87,
          opacity: 1.0,
        ),
        elevation: 0,
      ),
      drawer: const AppDrawer(currentPage: AppPage.goalTracker),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.s),
            _DashboardSection(targetDateFilter: _targetDateFilter).animate().fade(duration: AppAnimations.short, curve: AppAnimations.ease),
            const SizedBox(height: AppSpacing.l),

            // Quick Actions Section
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.s),
            _QuickActionsSection(
              onAddGoal: _addGoal,
              onAddMilestone: _addMilestone,
              onAddTask: _addTask,
              onAddHabit: _addHabit,
              onAddVoiceNote: _addVoiceNote,
            ).animate().fade(duration: AppAnimations.short, curve: AppAnimations.ease),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'homeFilterFab',
        tooltip: 'Filter by Target Date',
        backgroundColor: _targetDateFilter != null 
            ? Theme.of(context).colorScheme.primary 
            : Theme.of(context).colorScheme.surface.withOpacity(0.85),
        onPressed: () => _showFilterBottomSheet(context),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.filter_alt),
            if (_targetDateFilter != null)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onPrimary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Future<void> _showFilterBottomSheet(BuildContext context) async {
    final result = await showAppBottomSheet<Map<String, dynamic>?>(
      context,
      _HomeFilterBottomSheet(
        initialDateFilter: _targetDateFilter,
      ),
    );

    if (result != null && result.containsKey('targetDate')) {
      setState(() {
        _targetDateFilter = result['targetDate'] as String?;
      });
    }
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

  Future<void> _addVoiceNote() async {
    // Reset cubit state
    _voiceNoteCubit.reset();

    // Capture context before showing bottom sheet
    final homeContext = context;

    // Show voice note recorder
    await VoiceNoteRecorderBottomSheet.show(
      context,
      cubit: _voiceNoteCubit,
      onProcessed: (name, description) async {
        // Wait a moment for the bottom sheet to fully close
        await Future.delayed(const Duration(milliseconds: 200));
        
        // Ensure we have a valid context
        if (!homeContext.mounted) {
          print('Home context not mounted, cannot open form');
          return;
        }
        
        // Get entity type from current state
        final entityType = _voiceNoteCubit.state.selectedEntityType;
        if (entityType == null) {
          print('No entity type selected');
          return;
        }

        print('Opening form for entity type: $entityType with name: $name');

        switch (entityType) {
          case VoiceEntityType.goal:
            await _openGoalFormWithVoiceNote(name, description);
            break;
          case VoiceEntityType.milestone:
            await _openMilestoneFormWithVoiceNote(name, description);
            break;
          case VoiceEntityType.task:
            await _openTaskFormWithVoiceNote(name, description);
            break;
          case VoiceEntityType.habit:
            await _openHabitFormWithVoiceNote(name, description);
            break;
        }
      },
    );
  }

  Future<void> _openGoalFormWithVoiceNote(String name, String description) async {
    if (!mounted) return;
    
    // Ensure name is not empty - use description if name is empty
    final finalName = name.trim().isNotEmpty ? name.trim() : (description.trim().isNotEmpty ? description.trim() : 'New Goal');
    final finalDescription = description.trim().isNotEmpty ? description.trim() : null;
    
    print('Opening goal form with name: "$finalName", description: "$finalDescription"');
    
    if (!context.mounted) return;
    
    await GoalFormBottomSheet.show(
      context,
      title: 'Create Goal',
      initialName: finalName,
      initialDescription: finalDescription,
      onSubmit: (name, description, targetDate, context, isCompleted) async {
        print('Goal form submitted with name: "$name"');
        if (!mounted) return;
        await _goalCubit.addGoal(name, description, targetDate, context, isCompleted);
        print('Goal added successfully');
        // loadGoals() is already called in addGoal
      },
    );
  }

  Future<void> _openMilestoneFormWithVoiceNote(String name, String description) async {
    final goals = _goalCubit.state is GoalsLoaded
        ? ((_goalCubit.state as GoalsLoaded).goals)
        : <Goal>[];

    final goalOptions = goals.map((goal) => '${goal.id}::${goal.name}').toList();

    if (goalOptions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please create a goal first before adding a milestone'),
        ),
      );
      return;
    }

    await MilestoneFormBottomSheet.show(
      context,
      title: 'Create Milestone',
      initialName: name,
      initialDescription: description.isEmpty ? null : description,
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

  Future<void> _openTaskFormWithVoiceNote(String name, String description) async {
    final milestones = _milestoneCubit.state is MilestonesLoaded
        ? ((_milestoneCubit.state as MilestonesLoaded).milestones)
        : <Milestone>[];

    final milestoneOptions =
        milestones.map((milestone) => '${milestone.id}::${milestone.name}').toList();

    if (milestoneOptions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please create a milestone first before adding a task'),
        ),
      );
      return;
    }

    final milestoneGoalMap = <String, String>{};
    for (final milestone in milestones) {
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
      title: 'Create Task',
      initialName: name,
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

  Future<void> _openHabitFormWithVoiceNote(String name, String description) async {
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
        const SnackBar(
          content: Text('Please create a milestone first before adding a habit'),
        ),
      );
      return;
    }

    await HabitFormBottomSheet.show(
      context,
      title: 'Create Habit',
      initialName: name,
      initialDescription: description.isEmpty ? null : description,
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
  const _DashboardSection({this.targetDateFilter});
  
  final String? targetDateFilter;

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
                var goals = goalBox.values.toList();
                var milestones = milestoneBox.values.toList();
                var tasks = taskBox.values.toList();

                // Apply target date filter if set
                if (targetDateFilter != null) {
                  goals = _filterByTargetDate(goals, targetDateFilter!);
                  milestones = _filterMilestonesByTargetDate(milestones, targetDateFilter!);
                  tasks = _filterTasksByTargetDate(tasks, targetDateFilter!);
                }

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
                            icon: AppIcons.goal,
                            color: Theme.of(context).colorScheme.primary,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => GoalListPage(targetDateFilter: targetDateFilter),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: AppSpacing.m),
                        Expanded(
                          child: _InsightCard(
                            title: 'Milestones',
                            total: totalMilestones,
                            completed: completedMilestones,
                            icon: AppIcons.milestone,
                            color: Theme.of(context).colorScheme.secondary,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => MilestoneListPage(targetDateFilter: targetDateFilter),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.m),
                    _TaskInsightCard(
                      total: totalTasks,
                      completed: completedTasks,
                      inProgress: inProgressTasks,
                      color: Theme.of(context).colorScheme.tertiary,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => TaskListPage(targetDateFilter: targetDateFilter),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.m),
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

  // Helper methods to filter by target date (reusing logic from GoalCubit)
  static List<GoalModel> _filterByTargetDate(List<GoalModel> goals, String filter) {
    final now = DateTime.now();
    return goals.where((g) {
      final td = g.targetDate;
      if (td == null) return false;

      final today = DateTime(now.year, now.month, now.day);
      final targetDay = DateTime(td.year, td.month, td.day);

      switch (filter) {
        case 'Today':
          return targetDay == today;
        case 'Tomorrow':
          final tomorrow = today.add(const Duration(days: 1));
          return targetDay == tomorrow;
        case 'This Week':
          final startOfWeek = today.subtract(Duration(days: now.weekday - 1));
          final endOfWeek = startOfWeek.add(const Duration(days: 6));
          return !targetDay.isBefore(startOfWeek) && !targetDay.isAfter(endOfWeek);
        case 'Next Week':
          final nextWeekStart = today.add(Duration(days: 8 - now.weekday));
          final nextWeekEnd = nextWeekStart.add(const Duration(days: 6));
          return !targetDay.isBefore(nextWeekStart) && !targetDay.isAfter(nextWeekEnd);
        case 'This Month':
          return td.year == now.year && td.month == now.month;
        case 'Next Month':
          return td.year == now.year && td.month == now.month + 1;
        case 'This Year':
          return td.year == now.year;
        case 'Next Year':
          return td.year == now.year + 1;
        default:
          return false;
      }
    }).toList();
  }

  static List<MilestoneModel> _filterMilestonesByTargetDate(List<MilestoneModel> milestones, String filter) {
    final now = DateTime.now();
    return milestones.where((m) {
      final td = m.targetDate;
      if (td == null) return false;

      final today = DateTime(now.year, now.month, now.day);
      final targetDay = DateTime(td.year, td.month, td.day);

      switch (filter) {
        case 'Today':
          return targetDay == today;
        case 'Tomorrow':
          final tomorrow = today.add(const Duration(days: 1));
          return targetDay == tomorrow;
        case 'This Week':
          final startOfWeek = today.subtract(Duration(days: now.weekday - 1));
          final endOfWeek = startOfWeek.add(const Duration(days: 6));
          return !targetDay.isBefore(startOfWeek) && !targetDay.isAfter(endOfWeek);
        case 'Next Week':
          final nextWeekStart = today.add(Duration(days: 8 - now.weekday));
          final nextWeekEnd = nextWeekStart.add(const Duration(days: 6));
          return !targetDay.isBefore(nextWeekStart) && !targetDay.isAfter(nextWeekEnd);
        case 'This Month':
          return td.year == now.year && td.month == now.month;
        case 'Next Month':
          return td.year == now.year && td.month == now.month + 1;
        case 'This Year':
          return td.year == now.year;
        case 'Next Year':
          return td.year == now.year + 1;
        default:
          return false;
      }
    }).toList();
  }

  static List<TaskModel> _filterTasksByTargetDate(List<TaskModel> tasks, String filter) {
    final now = DateTime.now();
    return tasks.where((t) {
      final td = t.targetDate;
      if (td == null) return false;

      final today = DateTime(now.year, now.month, now.day);
      final targetDay = DateTime(td.year, td.month, td.day);

      switch (filter) {
        case 'Today':
          return targetDay == today;
        case 'Tomorrow':
          final tomorrow = today.add(const Duration(days: 1));
          return targetDay == tomorrow;
        case 'This Week':
          final startOfWeek = today.subtract(Duration(days: now.weekday - 1));
          final endOfWeek = startOfWeek.add(const Duration(days: 6));
          return !targetDay.isBefore(startOfWeek) && !targetDay.isAfter(endOfWeek);
        case 'Next Week':
          final nextWeekStart = today.add(Duration(days: 8 - now.weekday));
          final nextWeekEnd = nextWeekStart.add(const Duration(days: 6));
          return !targetDay.isBefore(nextWeekStart) && !targetDay.isAfter(nextWeekEnd);
        case 'This Month':
          return td.year == now.year && td.month == now.month;
        case 'Next Month':
          return td.year == now.year && td.month == now.month + 1;
        case 'This Year':
          return td.year == now.year;
        case 'Next Year':
          return td.year == now.year + 1;
        default:
          return false;
      }
    }).toList();
  }
}

/// Filter bottom sheet for home page - only shows Target Date filter
class _HomeFilterBottomSheet extends StatefulWidget {
  const _HomeFilterBottomSheet({this.initialDateFilter});

  final String? initialDateFilter;

  @override
  State<_HomeFilterBottomSheet> createState() => _HomeFilterBottomSheetState();
}

class _HomeFilterBottomSheetState extends State<_HomeFilterBottomSheet> {
  String? _selectedDateFilter;

  @override
  void initState() {
    super.initState();
    _selectedDateFilter = widget.initialDateFilter;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final maxHeight = MediaQuery.of(context).size.height * 0.5;
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Filter by Target Date',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final option in [
                          "Today",
                          "Tomorrow",
                          "This Week",
                          "Next Week",
                          "This Month",
                          "Next Month",
                          "This Year",
                          "Next Year",
                        ])
                          ChoiceChip(
                            label: Text(option),
                            selected: _selectedDateFilter == option,
                            onSelected: (sel) {
                              setState(() {
                                _selectedDateFilter = sel ? option : null;
                              });
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text("Close"),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop({
                        "targetDate": _selectedDateFilter,
                      });
                    },
                    child: const Text("Apply Filter"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
    final card = Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
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
                  const SizedBox(width: AppSpacing.xs),
                  Icon(
                    Icons.visibility_outlined,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 18,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s),
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.m),
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

    return card
        .animate()
        .fade(duration: AppAnimations.micro, curve: AppAnimations.ease)
        .moveY(begin: 8, end: 0, duration: AppAnimations.micro, curve: AppAnimations.ease);
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
    final card = Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(AppIcons.task, color: color, size: 28),
                  const SizedBox(width: AppSpacing.m),
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
                  const SizedBox(width: AppSpacing.xs),
                  Icon(
                    Icons.visibility_outlined,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 18,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.m),
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
              const SizedBox(height: AppSpacing.m),
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

    return card
        .animate()
        .fade(duration: AppAnimations.micro, curve: AppAnimations.ease)
        .moveY(begin: 8, end: 0, duration: AppAnimations.micro, curve: AppAnimations.ease);
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
    required this.onAddGoal,
    required this.onAddMilestone,
    required this.onAddTask,
    required this.onAddHabit,
    required this.onAddVoiceNote,
  });

  final VoidCallback onAddGoal;
  final VoidCallback onAddMilestone;
  final VoidCallback onAddTask;
  final VoidCallback onAddHabit;
  final VoidCallback onAddVoiceNote;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _GradientActionTile(
                icon: AppIcons.goal,
                gradientType: _GradientType.primary,
                onTap: onAddGoal,
              ),
            ),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: _GradientActionTile(
                icon: AppIcons.milestone,
                gradientType: _GradientType.secondary,
                onTap: onAddMilestone,
              ),
            ),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: _GradientActionTile(
                icon: AppIcons.task,
                gradientType: _GradientType.tertiary,
                onTap: onAddTask,
              ),
            ),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: _GradientActionTile(
                icon: AppIcons.habit,
                gradientType: _GradientType.primary,
                onTap: onAddHabit,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.m),
        // Row(
        //   children: [
        //     Expanded(
        //       child: _GradientActionTile(
        //         icon: Icons.mic,
        //         gradient: AppGradients.secondary(cs),
        //         accentColor: cs.secondary,
        //         onTap: onAddVoiceNote,
        //       ),
        //     ),
        //   ],
        // ),
      ],
    );
  }
}

/// Gradient type enum for action tiles
enum _GradientType {
  primary,
  secondary,
  tertiary,
}

/// Action button widget
class _GradientActionTile extends StatelessWidget {
  const _GradientActionTile({
    required this.icon,
    required this.gradientType,
    required this.onTap,
  });

  final IconData icon;
  final _GradientType gradientType;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    // Create gradient based on type, ensuring theme is fully available
    final Gradient gradient;
    final Color accentColor;
    switch (gradientType) {
      case _GradientType.primary:
        gradient = AppGradients.primary(cs);
        accentColor = cs.primary;
        break;
      case _GradientType.secondary:
        gradient = AppGradients.secondary(cs);
        accentColor = cs.secondary;
        break;
      case _GradientType.tertiary:
        gradient = AppGradients.tertiary(cs);
        accentColor = cs.tertiary;
        break;
    }
    
    final fg = cs.onPrimary;
    final tile = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Center(
            child: _AddOverlayIcon(
              icon: icon,
              foregroundColor: fg,
              accentColor: accentColor,
            ),
          ),
        ),
      ),
    );

    return tile
        .animate()
        .fade(duration: AppAnimations.micro, curve: AppAnimations.ease)
        .scale(begin: const Offset(0.98, 0.98), end: const Offset(1, 1), duration: AppAnimations.micro, curve: AppAnimations.ease);
  }
}

class _AddOverlayIcon extends StatelessWidget {
  const _AddOverlayIcon({
    required this.icon,
    required this.foregroundColor,
    required this.accentColor,
  });

  final IconData icon;
  final Color foregroundColor;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      width: 36,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Align(
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 26,
              color: foregroundColor,
            ),
          ),
          Positioned(
            bottom: -2,
            right: -2,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: foregroundColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Icon(
                Icons.add,
                size: 12,
                color: accentColor,
              ),
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

        final card = Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadii.card),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.m),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        AppIcons.habit,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: AppSpacing.s),
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
                  const SizedBox(width: AppSpacing.xs),
                  Icon(
                    Icons.visibility_outlined,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 18,
                  ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s),
                  Row(
                    children: [
                      _buildStatChip(
                        'Active',
                        '$activeHabits',
                        Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: AppSpacing.s),
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
        return card
            .animate()
            .fade(duration: AppAnimations.micro, curve: AppAnimations.ease)
            .moveY(begin: 8, end: 0, duration: AppAnimations.micro, curve: AppAnimations.ease);
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


