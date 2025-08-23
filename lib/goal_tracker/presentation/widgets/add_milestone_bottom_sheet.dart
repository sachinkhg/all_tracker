import 'package:all_tracker/widgets/shared_date.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../util/common_util.dart';
import '../../../widgets/shared_text_box.dart';
import '../../../widgets/shared_button.dart';

import '../../domain/entities/goal.dart';
import '../../domain/entities/milestone.dart';

// ❌ remove bloc/event imports
// import '../bloc/goal/goal_bloc.dart';
// import '../bloc/goal/goal_event.dart';
// import '../bloc/milestone/milestone_bloc.dart';
// import '../bloc/milestone/milestone_event.dart';

// ✅ add DI + usecases + cubits
import '../../di/service_locator.dart'; // exposes getIt
import '../../domain/usecases/milestone_usecases.dart';
import '../bloc/milestone/milestone_list_cubit.dart';
import '../bloc/goal/goal_list_cubit.dart';

class AddMilestoneBottomSheet extends StatefulWidget {
  final void Function(String title, DateTime targetDate) onSubmit;

  const AddMilestoneBottomSheet({super.key, required this.onSubmit});

  @override
  State<AddMilestoneBottomSheet> createState() => _AddMilestoneBottomSheetState();
}

class _AddMilestoneBottomSheetState extends State<AddMilestoneBottomSheet> {
  final _titleController = TextEditingController();
  final _dateController = TextEditingController();
  final _titleFocusNode = FocusNode();

  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _titleFocusNode.requestFocus();
    });
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
      padding: MediaQuery.of(context).viewInsets,
      child: Container(
        padding: EdgeInsets.all(screenWidth * 0.05),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
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
                "Add Milestone",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimary,
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

///
/// Call this from MilestoneListPage:
///   openAddMilestonePopup(context, goal,
///     milestoneListCubit: context.read<MilestoneListCubit>(),
///     goalListCubit: context.read<GoalListCubit>(), // optional
///   );
///
void openAddMilestonePopup(
  BuildContext context,
  Goal goal, {
  MilestoneListCubit? milestoneListCubit,
  GoalListCubit? goalListCubit, // optional: refresh goals page if present
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => MultiBlocProvider(
      providers: [
        // pass the SAME page-scoped cubit instance down (safe/no re-creation)
        if (milestoneListCubit != null) BlocProvider.value(value: milestoneListCubit),
        if (goalListCubit != null) BlocProvider.value(value: goalListCubit),
      ],
      child: AddMilestoneBottomSheet(
        onSubmit: (milestoneTitle, targetDate) async {
          final milestoneId = const Uuid().v4();
          final milestone = Milestone(
            id: milestoneId,
            title: milestoneTitle,
            targetDate: targetDate,
            associatedGoalID: goal.id,
          );

          // Persist via usecase
          await getIt<AddMilestone>()(milestone);

          // Refresh lists
          milestoneListCubit?.load();   // refresh the milestones under this goal
          goalListCubit?.load();       // (optional) refresh aggregated goal list
        },
      ),
    ),
  );
}
