import 'package:all_tracker/widgets/shared_date.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../util/common_util.dart';
import '../../../widgets/shared_text_box.dart';
import '../../../widgets/shared_button.dart';
import '../../domain/entities/goal.dart';

// ❌ remove GoalBloc imports
// import '../bloc/goal/goal_bloc.dart';
// import '../bloc/goal/goal_event.dart';

// ✅ add these
import '../../di/service_locator.dart'; // exposes getIt
import '../../domain/usecases/goal_usecases.dart';
import '../bloc/goal/goal_list_cubit.dart';

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

    _titleController = TextEditingController(text: widget.initialGoal?.title ?? '');
    _descriptionController = TextEditingController(text: widget.initialGoal?.description ?? '');
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

/// Open "Add Goal" sheet and refresh GoalListCubit after save.
void openAddGoalPopup(BuildContext context, {required GoalListCubit goalListCubit}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => BlocProvider.value(
      value: goalListCubit, // pass the SAME cubit into the sheet (optional but safe)
      child: AddGoalBottomSheet(
        onSubmit: (title, description, targetDate) async {
          final goal = Goal(
            id: const Uuid().v4(),
            title: title,
            description: description,
            targetDate: targetDate,
          );
          await getIt<AddGoal>()(goal);
          goalListCubit.load();   // 🔁 refresh list
        },
      ),
    ),
  );
}

// helpers file
Future<void> openEditGoalPopup(
  BuildContext context,
  Goal goal, {
  required GoalListCubit goalListCubit,
}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => BlocProvider.value(
      value: goalListCubit,
      child: AddGoalBottomSheet(
        initialGoal: goal,
        onSubmit: (title, description, targetDate) async {
          final updatedGoal = goal.copyWith(
            title: title,
            description: description,
            targetDate: targetDate,
          );
          await getIt<UpdateGoal>()(updatedGoal);
          // refresh the goals list (for the Goals page)
          goalListCubit.load();
          // close the sheet
          //Navigator.of(context).pop();
        },
      ),
    ),
  );
}
