import 'package:all_tracker/widgets/shared_date.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../util/common_util.dart';
import '../../../widgets/shared_text_box.dart';
import '../../../widgets/shared_button.dart';
import '../../domain/entities/goal.dart';
import '../../domain/entities/milestone.dart';
import '../bloc/goal/goal_bloc.dart';
import '../bloc/goal/goal_event.dart';
import '../bloc/milestone/milestone_bloc.dart';
import '../bloc/milestone/milestone_event.dart';

class AddMilestoneBottomSheet extends StatefulWidget {
  final void Function(String title, DateTime targetDate) onSubmit;

  const AddMilestoneBottomSheet({super.key, required this.onSubmit});

  @override
  State<AddMilestoneBottomSheet> createState() => _AddMilestoneBottomSheetState();
}

class _AddMilestoneBottomSheetState extends State<AddMilestoneBottomSheet> {
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
                "Add Milestone",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,  color: theme.colorScheme.onPrimary,
                    ),
              ),
              SizedBox(height: screenWidth * 0.05),
              SharedTextBox(
                label: "Title",
                hintText: "Enter milestone title",
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
                label: "Save Milestone",
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

// void openAddMilestonePopup(BuildContext context, Goal goal) {
//   showModalBottomSheet(
//     context: context,
//     isScrollControlled: true,
//     builder: (_) => BlocProvider.value(
//       value: context.read<MilestoneBloc>(), // Re-use the existing MilestoneBloc instance
//       child: AddMilestoneBottomSheet(
//         onSubmit: (milestoneTitle, targetDate) {
//           final milestoneId = const Uuid().v4();
//           final milestone = Milestone(
//             id: milestoneId,
//             title: milestoneTitle,
//             targetDate: targetDate,
//           );

//           // Dispatch event to add the milestone to the MilestoneBloc
//           context.read<MilestoneBloc>().add(AddMilestoneEvent(milestone));

//           // Dispatch event to update the goal's milestones
//           context.read<GoalBloc>().add(UpdateGoalEvent(goal.copyWith(
//             milestoneIds: List<String>.from(goal.milestoneIds)..add(milestoneId),
//           )));
//         },
//       ),    

//     ),
//   );
// }

void openAddMilestonePopup(BuildContext context, Goal goal) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => MultiBlocProvider(
      providers: [
        BlocProvider.value(
          value: context.read<MilestoneBloc>(),
        ),
        BlocProvider.value(
          value: context.read<GoalBloc>(),
        ),
      ],
      child: AddMilestoneBottomSheet(
        onSubmit: (milestoneTitle, targetDate) {
          final milestoneId = const Uuid().v4();
          final milestone = Milestone(
            id: milestoneId,
            title: milestoneTitle,
            targetDate: targetDate,
          );

          // Now these will find the correct Bloc providers!
          context.read<MilestoneBloc>().add(AddMilestoneEvent(milestone));
          context.read<GoalBloc>().add(UpdateGoalEvent(goal.copyWith(
            milestoneIds: List<String>.from(goal.milestoneIds)..add(milestoneId),
          )));
        },
      ),
    ),
  );
}