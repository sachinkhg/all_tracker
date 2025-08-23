import 'package:all_tracker/widgets/shared_date.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../util/common_util.dart';
import '../../../widgets/shared_text_box.dart';
import '../../../widgets/shared_button.dart';
import '../../domain/entities/milestone.dart';
import '../../domain/entities/task.dart';
import '../bloc/milestone/milestone_bloc.dart';
import '../bloc/milestone/milestone_event.dart';
import '../bloc/task/task_bloc.dart';
import '../bloc/task/task_event.dart';

class AddTaskBottomSheet extends StatefulWidget {
  final void Function(String title, DateTime targetDate) onSubmit;

  const AddTaskBottomSheet({super.key, required this.onSubmit});

  @override
  State<AddTaskBottomSheet> createState() => _AddTaskBottomSheetState();
}

class _AddTaskBottomSheetState extends State<AddTaskBottomSheet> {
  final _titleController = TextEditingController();
  final _dateController = TextEditingController();
  final _titleFocusNode = FocusNode(); // ✅ focus node

  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _titleFocusNode.requestFocus(); // ✅ autofocus
    });

    // Initialize the date field text
    _dateController.text = formatDate(_selectedDate);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _titleFocusNode.dispose();
    _dateController.dispose();
    super.dispose();
  }

void _handleSubmit() {
  final title = _titleController.text.trim();

  if (title.isEmpty) return;
  widget.onSubmit(title, _selectedDate);
  Navigator.of(context).pop();
}


  // Callback when SharedDate picks a date
  void _handleDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
      _dateController.text = formatDate(date);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final theme = Theme.of(context);

    return Padding(
      padding: MediaQuery.of(context).viewInsets, // adjusts for keyboard
      child: Container(
        padding: EdgeInsets.all(screenWidth * 0.05),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // Shrinks to fit content
            children: [
              Center(
                child: Container(
                  height: 4,
                  width: 40,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Text(
                "Add Task",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,  color: theme.colorScheme.onPrimary,
                    ),
              ),
              SizedBox(height: screenWidth * 0.05),
              SharedTextBox(
                label: "Title",
                hintText: "Enter task title",
                controller: _titleController,
                focusNode: _titleFocusNode,
              ),
              SizedBox(height: screenWidth * 0.06),
              SharedDate(
                date: _selectedDate,
                label: "Target Date",
                onDateChanged: _handleDateSelected,
              ),
              SizedBox(height: screenWidth * 0.06),
              SharedButton(
                label: "Save Task",
                icon: Icons.check,
                onPressed: _handleSubmit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// void openAddTaskPopup(BuildContext context, Milestone milestone) {
//   showModalBottomSheet(
//     context: context,
//     isScrollControlled: true,
//     builder: (_) => BlocProvider.value(
//       value: context.read<TaskBloc>(), // Re-use the existing TaskBloc instance
//       child: AddTaskBottomSheet(
//         onSubmit: (taskTitle, targetDate) {
//           final taskId = const Uuid().v4();
//           final task = Task(
//             id: taskId,
//             title: taskTitle,
//             targetDate: targetDate,
//           );

//           // Dispatch event to add the task to the TaskBloc
//           context.read<TaskBloc>().add(AddTaskEvent(task));

//           // Dispatch event to update the milestone's tasks
//           context.read<MilestoneBloc>().add(UpdateMilestoneEvent(milestone.copyWith(
//             taskIds: List<String>.from(milestone.taskIds)..add(taskId),
//           )));
//         },
//       ),    

//     ),
//   );
// }

void openAddTaskPopup(BuildContext context, Milestone milestone) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => MultiBlocProvider(
      providers: [
        BlocProvider.value(
          value: context.read<TaskBloc>(),
        ),
        BlocProvider.value(
          value: context.read<MilestoneBloc>(),
        ),
      ],
      child: AddTaskBottomSheet(
        onSubmit: (taskTitle, targetDate) {
          final taskId = const Uuid().v4();
          final task = Task(
            id: taskId,
            associatedMilestoneId: milestone.id,
            name: taskTitle,
            dueDate: targetDate,
          );

          // Now these will find the correct Bloc providers!
          context.read<TaskBloc>().add(AddTaskEvent(task));

          // Immediately request a refresh of milestones (updates allTasksMap)
          context.read<MilestoneBloc>().add(LoadMilestones());
        },
      ),
    ),
  );
}