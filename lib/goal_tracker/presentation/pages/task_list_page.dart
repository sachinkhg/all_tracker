// task_list_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../widgets/shared_button.dart';
import '../../di/service_locator.dart';
import '../../domain/usecases/task_usecases.dart';
import '../../domain/entities/task.dart';
import '../bloc/task/task_list_cubit.dart';   // <-- your cubit
import '../../../widgets/shared_card.dart';
import '../../../widgets/shared_timeline_list.dart';
import '../../../util/common_util.dart';

class TaskListPage extends StatefulWidget {
  final String milestoneId;
  const TaskListPage({super.key, required this.milestoneId});

  @override
  State<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {
  late final TaskListCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = TaskListCubit(
      milestoneId: widget.milestoneId,
      getTasksForMilestone: getIt<GetTasksForMilestone>(),
      addTask: getIt<AddTask>(),
      updateTask: getIt<UpdateTask>(),
      deleteTask: getIt<DeleteTask>(),
    )..load(); // ✅ start loading here
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocProvider.value(     // ✅ provider is ABOVE everything (incl. SliverList)
      value: _cubit,
      child: Scaffold(
        appBar: AppBar(title: const Text('Tasks')),
        body: BlocBuilder<TaskListCubit, TaskListState>(
          builder: (context, state) {
            if (state.loading) return const Center(child: CircularProgressIndicator());
            if (state.error != null) return Center(child: Text('Error: ${state.error}'));

            final tasks = state.tasks;
            if (tasks.isEmpty) return const Center(child: Text('No tasks found'));

            final sorted = sortListByDate<Task>(tasks, (t) => t.dueDate);
            final byMonth = groupByMonthYear<Task>(sorted, (t) => t.dueDate);
            final monthKeys = byMonth.keys.toList()..sort();

            return ListView(
              children: monthKeys.map((month) {
                return MonthTimelineList<Task>(
                  monthKeys: [month],
                  itemsByMonth: {month: byMonth[month]!},
                  itemBuilder: (ctx, task) => SharedCard(
                    icon: Icons.check_circle_outline,
                    title: task.name,
                    subtitle2: task.dueDate != null
                        ? DateFormat('dd/MM/yyyy').format(task.dueDate!)
                        : 'No target date',
                  ),
                );
              }).toList(),
            );
          },
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
                        label: "Add Task",
                        icon: Icons.add,
                        onPressed: () {
                          // openAddMilestonePopup(
                          //   context,
                          //   goal,
                          //   milestoneListCubit: context.read<MilestoneListCubit>(), // refresh milestone list
                          //   goalListCubit: context.read<GoalListCubit>(),           // also refresh aggregated goals
                          // );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SharedButton(
                        label: "Edit Milestone",
                        icon: Icons.edit,
                        onPressed: () async {
                          // await openEditGoalPopup(
                          //   context,
                          //   goal,
                          //   goalListCubit: context.read<GoalListCubit>(),
                          // );
                          // // re-fetch the goal so the header reflects latest title/date/desc
                          // await _loadGoalTitle();
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
      ),
    );
  }
}
