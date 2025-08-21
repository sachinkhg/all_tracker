import 'package:all_tracker/widgets/shared_date.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../util/common_util.dart';
import '../../../widgets/shared_text_box.dart';
import '../../../widgets/shared_button.dart';
import '../../domain/entities/goal.dart';
import '../bloc/goal/goal_bloc.dart';
import '../bloc/goal/goal_event.dart';

class AddGoalBottomSheet extends StatefulWidget {
  final void Function(String title, String description, DateTime targetDate) onSubmit;
  final Goal? initialGoal; // Null for Add, non-null for Edit

  const AddGoalBottomSheet({
    super.key,
    required this.onSubmit,
    this.initialGoal,
  });

  @override
  State<AddGoalBottomSheet> createState() => _AddGoalBottomSheetState();
}

class _AddGoalBottomSheetState extends State<AddGoalBottomSheet> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _dateController;
  late FocusNode _titleFocusNode;

  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _titleFocusNode = FocusNode();

    // Use initialGoal data if in edit mode, else defaults
    _titleController = TextEditingController(text: widget.initialGoal?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.initialGoal?.description ?? '');
    _selectedDate = widget.initialGoal?.targetDate ?? DateTime.now();
    _dateController = TextEditingController(text: formatDate(_selectedDate));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _titleFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    _titleFocusNode.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    if (title.isEmpty) return;

    widget.onSubmit(title, description, _selectedDate);
    Navigator.of(context).pop();
  }

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

    final isEditing = widget.initialGoal != null;

    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: Container(
        padding: EdgeInsets.all(screenWidth * 0.05),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
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
                isEditing ? "Edit Goal" : "Add Goal",
                style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimary,
                    ),
              ),
              SizedBox(height: screenWidth * 0.05),
              SharedTextBox(
                label: "Title",
                hintText: "Enter goal title",
                controller: _titleController,
                focusNode: _titleFocusNode,
              ),
              SizedBox(height: screenWidth * 0.04),
              SharedTextBox(
                label: "Description",
                hintText: "Enter goal description",
                controller: _descriptionController,
                maxLines: 4,
              ),
              SizedBox(height: screenWidth * 0.06),
              SharedDate(
                date: _selectedDate,
                label: "Target Date",
                onDateChanged: _handleDateSelected,
              ),
              SizedBox(height: screenWidth * 0.06),
              SharedButton(
                label: isEditing ? "Update Goal" : "Save Goal",
                icon: isEditing ? Icons.check : Icons.check,
                onPressed: _handleSubmit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// class AddGoalBottomSheet extends StatefulWidget {
//   final void Function(String title, String description, DateTime targetDate) onSubmit;

//   const AddGoalBottomSheet({super.key, required this.onSubmit});

//   @override
//   State<AddGoalBottomSheet> createState() => _AddGoalBottomSheetState();
// }

// class _AddGoalBottomSheetState extends State<AddGoalBottomSheet> {
//   final _titleController = TextEditingController();
//   final _descriptionController = TextEditingController();
//   final _dateController = TextEditingController();
//   final _titleFocusNode = FocusNode(); // ✅ focus node

//   DateTime _selectedDate = DateTime.now();

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _titleFocusNode.requestFocus(); // ✅ autofocus
//     });

//     // Initialize the date field text
//     _dateController.text = formatDate(_selectedDate);
//   }

//   @override
//   void dispose() {
//     _titleController.dispose();
//     _descriptionController.dispose();
//     _titleFocusNode.dispose();
//     _dateController.dispose();
//     super.dispose();
//   }

//   void _handleSubmit() {
//     final title = _titleController.text.trim();
//     final description = _descriptionController.text.trim();

//     if (title.isEmpty) return;

//     widget.onSubmit(title, description, _selectedDate);
//     Navigator.of(context).pop();
//   }

//   // Callback when SharedDate picks a date
//   void _handleDateSelected(DateTime date) {
//     setState(() {
//       _selectedDate = date;
//       _dateController.text = formatDate(date);
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final theme = Theme.of(context);

//     return Padding(
//       padding: MediaQuery.of(context).viewInsets, // adjusts for keyboard
//       child: Container(
//         padding: EdgeInsets.all(screenWidth * 0.05),
//         decoration: BoxDecoration(
//           color: Theme.of(context).colorScheme.primary,
//           borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
//         ),
//         child: SingleChildScrollView(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             mainAxisSize: MainAxisSize.min, // Shrinks to fit content
//             children: [
//               Center(
//                 child: Container(
//                   height: 4,
//                   width: 40,
//                   margin: const EdgeInsets.only(bottom: 16),
//                   decoration: BoxDecoration(
//                     color: Colors.grey[400],
//                     borderRadius: BorderRadius.circular(4),
//                   ),
//                 ),
//               ),
//               Text(
//                 "Add Goal",
//                 style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                       fontWeight: FontWeight.bold,  color: theme.colorScheme.onPrimary,
//                     ),
//               ),
//               SizedBox(height: screenWidth * 0.05),
//               SharedTextBox(
//                 label: "Title",
//                 hintText: "Enter goal title",
//                 controller: _titleController,
//                 focusNode: _titleFocusNode,
//               ),
//               SizedBox(height: screenWidth * 0.04),
//               SharedTextBox(
//                 label: "Description",
//                 hintText: "Enter goal description",
//                 controller: _descriptionController,
//                 maxLines: 4,
//               ),
//               SizedBox(height: screenWidth * 0.06),
//               SharedDate(
//                 date: _selectedDate,
//                 label: "Target Date",
//                 onDateChanged: _handleDateSelected,
//               ),
//               SizedBox(height: screenWidth * 0.06),
//               SharedButton(
//                 label: "Save Goal",
//                 icon: Icons.check,
//                 onPressed: _handleSubmit,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
  void openAddGoalPopup(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddGoalBottomSheet(
        onSubmit: (title, description, targetDate) {
          final goal = Goal(
            id: const Uuid().v4(),
            title: title,
            description: description,
            targetDate: targetDate,
          );
          context.read<GoalBloc>().add(AddGoalEvent(goal));
        },
      ),
    );
  }

  void openEditGoalPopup(BuildContext context, Goal goal) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => AddGoalBottomSheet(
      initialGoal: goal,
      onSubmit: (title, description, targetDate) {
        final updatedGoal = goal.copyWith(
          title: title,
          description: description,
          targetDate: targetDate,
        );
        context.read<GoalBloc>().add(UpdateGoalEvent(updatedGoal));
      },
    ),
  );
}
