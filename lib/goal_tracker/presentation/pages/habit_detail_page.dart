import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/injection.dart';
import 'package:all_tracker/goal_tracker/core/app_icons.dart';
import '../../data/models/milestone_model.dart';
import '../../data/models/goal_model.dart';
import '../../core/constants.dart';
import '../../domain/entities/habit.dart';
import '../bloc/habit_cubit.dart';
import '../bloc/habit_state.dart';
import '../bloc/habit_completion_cubit.dart';
import '../widgets/habit_calendar_view.dart';
import '../widgets/habit_form_bottom_sheet.dart';

/// Detail page for viewing and managing a specific habit.
///
/// This page shows habit details, statistics, and a calendar view
/// for tracking completions. It allows editing and deleting the habit.
class HabitDetailPage extends StatefulWidget {
  final String habitId;

  const HabitDetailPage({
    super.key,
    required this.habitId,
  });

  @override
  State<HabitDetailPage> createState() => _HabitDetailPageState();
}

class _HabitDetailPageState extends State<HabitDetailPage> {
  late HabitCubit _habitCubit;
  late HabitCompletionCubit _completionCubit;
  Habit? _habit;

  @override
  void initState() {
    super.initState();
    _habitCubit = createHabitCubit();
    _completionCubit = createHabitCompletionCubit();
    _loadHabit();
  }

  @override
  void dispose() {
    _habitCubit.close();
    _completionCubit.close();
    super.dispose();
  }

  Future<void> _loadHabit() async {
    await _habitCubit.loadHabitById(widget.habitId);
    if (_habit != null) {
      await _completionCubit.loadCompletionsByHabitId(_habit!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<HabitCubit>.value(value: _habitCubit),
        BlocProvider<HabitCompletionCubit>.value(value: _completionCubit),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Habit Details'),
          actions: [
            IconButton(
              onPressed: _editHabit,
              icon: const Icon(Icons.edit),
              tooltip: 'Edit Habit',
            ),
            PopupMenuButton<String>(
              onSelected: _handleMenuAction,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'toggle_active',
                  child: Row(
                    children: [
                      Icon(Icons.power_settings_new),
                      SizedBox(width: 8),
                      Text('Toggle Active'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: BlocListener<HabitCubit, HabitState>(
          bloc: _habitCubit,
          listener: (context, state) {
            if (state is HabitsLoaded && state.habits.isNotEmpty) {
              setState(() {
                _habit = state.habits.first;
              });
              if (_habit != null) {
                _completionCubit.loadCompletionsByHabitId(_habit!.id);
              }
            } else if (state is HabitsError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
          },
          child: BlocBuilder<HabitCubit, HabitState>(
            bloc: _habitCubit,
            builder: (context, state) {
              if (state is HabitsLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is HabitsError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading habit',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        state.message,
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadHabit,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              if (_habit == null) {
                return const Center(
                  child: Text('Habit not found'),
                );
              }

              return _buildHabitDetails();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHabitDetails() {
    final theme = Theme.of(context);
    final milestoneName = _getMilestoneName(_habit!.milestoneId);
    final goalName = _getGoalName(_habit!.goalId);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _habit!.name,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _habit!.isActive
                              ? theme.colorScheme.primaryContainer
                              : theme.colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _habit!.isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            color: _habit!.isActive
                                ? theme.colorScheme.onPrimaryContainer
                                : theme.colorScheme.onSurfaceVariant,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  if (_habit!.description != null && _habit!.description!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      _habit!.description!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 12),
                  
                  // Milestone and Goal info
                  Row(
                    children: [
                      Icon(
                        AppIcons.milestone,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Milestone: ',
                        style: theme.textTheme.bodySmall,
                      ),
                      Text(
                        milestoneName ?? 'Unknown',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  
                  if (goalName != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          AppIcons.goal,
                          size: 16,
                          color: theme.colorScheme.secondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Goal: ',
                          style: theme.textTheme.bodySmall,
                        ),
                        Text(
                          goalName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                  
                  const SizedBox(height: 12),
                  
                  // Recurrence info
                  Row(
                    children: [
                      Icon(
                        Icons.repeat,
                        size: 16,
                        color: theme.colorScheme.tertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Recurrence: ',
                        style: theme.textTheme.bodySmall,
                      ),
                      Text(
                        _formatRrule(_habit!.rrule),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  
                  if (_habit!.targetCompletions != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.trending_up,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Weight: ',
                          style: theme.textTheme.bodySmall,
                        ),
                        Text(
                          '${_habit!.targetCompletions}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Calendar view
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_month,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Completion Calendar',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  HabitCalendarView(
                    habit: _habit!,
                    completionCubit: _completionCubit,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _editHabit() {
    // Get milestone options and goal mapping
    final milestoneOptions = _getMilestoneOptions();
    final milestoneGoalMap = _getMilestoneGoalMap();
    
    HabitFormBottomSheet.show(
      context,
      title: 'Edit Habit',
      initialName: _habit!.name,
      initialDescription: _habit!.description,
      initialMilestoneId: _habit!.milestoneId,
      initialRrule: _habit!.rrule,
      initialTargetCompletions: _habit!.targetCompletions,
      initialIsActive: _habit!.isActive,
      milestoneOptions: milestoneOptions,
      milestoneGoalMap: milestoneGoalMap,
      onSubmit: (name, description, milestoneId, rrule, targetCompletions, isActive) async {
        try {
          await _habitCubit.editHabit(
            id: _habit!.id,
            name: name,
            description: description,
            milestoneId: milestoneId,
            rrule: rrule,
            targetCompletions: targetCompletions,
            isActive: isActive,
          );
          
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Habit updated successfully')),
          );
        } catch (e) {
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating habit: ${e.toString()}')),
          );
        }
      },
      onDelete: () async {
        await _habitCubit.removeHabit(_habit!.id);
        
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Habit deleted')),
        );
        
        // Go back to list
        // ignore: use_build_context_synchronously
        Navigator.of(context).pop();
      },
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'toggle_active':
        _habitCubit.toggleActive(_habit!.id);
        break;
      case 'delete':
        _showDeleteConfirmation();
        break;
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Habit'),
        content: Text(
          'Are you sure you want to delete "${_habit!.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _habitCubit.removeHabit(_habit!.id);
              Navigator.of(context).pop(); // Go back to list
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String? _getMilestoneName(String milestoneId) {
    try {
      final milestoneBox = Hive.box<MilestoneModel>(milestoneBoxName);
      final milestone = milestoneBox.get(milestoneId);
      return milestone?.name;
    } catch (e) {
      return null;
    }
  }

  String? _getGoalName(String goalId) {
    try {
      final goalBox = Hive.box<GoalModel>(goalBoxName);
      final goal = goalBox.get(goalId);
      return goal?.name;
    } catch (e) {
      return null;
    }
  }

  String _formatRrule(String rrule) {
    // Simple formatting for common RRULE patterns
    if (rrule == 'FREQ=DAILY') return 'Daily';
    if (rrule == 'FREQ=WEEKLY') return 'Weekly';
    if (rrule == 'FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR') return 'Weekdays';
    if (rrule == 'FREQ=WEEKLY;BYDAY=SA,SU') return 'Weekends';
    if (rrule.startsWith('FREQ=DAILY;INTERVAL=')) {
      final interval = rrule.split('INTERVAL=')[1];
      return 'Every $interval days';
    }
    return rrule; // Return as-is for custom rules
  }

  /// Helper method to fetch milestones from Hive and format them for the dropdown
  List<String> _getMilestoneOptions() {
    try {
      final box = Hive.box<MilestoneModel>(milestoneBoxName);
      final milestones = box.values.toList();
      
      // Format as "id::name" for the dropdown
      return milestones.map((m) => '${m.id}::${m.name}').toList();
    } catch (e) {
      return [];
    }
  }

  /// Helper to build milestone-to-goal mapping for the form
  Map<String, String> _getMilestoneGoalMap() {
    try {
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
      return goalMap;
    } catch (e) {
      return {};
    }
  }
}
