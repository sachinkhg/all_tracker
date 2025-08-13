import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/goal.dart';
import '../bloc/goal_bloc.dart';
import '../bloc/goal_event.dart';
import '../bloc/goal_state.dart';
import '../../../widgets/shared_card.dart';
import '../../../widgets/shared_list_page.dart';
import '../../../widgets/shared_button.dart';
import '../widgets/add_goal_popup'; // ✅ Import the button

class GoalListPage extends StatelessWidget {
  const GoalListPage({super.key});

  void _openAddGoalPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AddGoalPopup(
        onSubmit: (title, description) {
          final goal = Goal(
            id: const Uuid().v4(),
            title: title,
            description: description,
          );
          context.read<GoalBloc>().add(AddGoalEvent(goal)); // ✅ handled here
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ Bottom button always visible
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SharedButton(
          label: "Add Goal",
          icon: Icons.add,
          onPressed: () => _openAddGoalPopup(context),
        ),
      ),
      body: SafeArea(
        child: BlocBuilder<GoalBloc, GoalState>(
          builder: (context, state) {
            if (state is GoalLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is GoalLoaded) {
              return SharedListPage<Goal>(
                items: state.goals,
                itemBuilder: (context, goal) {
                  final theme = Theme.of(context);
                  return SharedCard(
                    icon: Icons.flag,
                    iconBackgroundColor: theme.colorScheme.primary,
                    title: goal.title,
                    subtitle: goal.description,
                    textColor: theme.colorScheme.onPrimary,
                    inactiveTextColor: theme.colorScheme.onPrimary,
                    backgroundColor:
                        theme.colorScheme.onPrimary.withAlpha(50),
                  );
                },
              );
            } else if (state is GoalError) {
              return Center(child: Text('Error: ${state.message}'));
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
