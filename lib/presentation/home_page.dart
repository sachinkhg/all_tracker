import 'package:flutter/material.dart';
import '../core/hive_initializer.dart';
import '../core/service_locator.dart';
import '../goal_tracker/domain/usecases/goal_usecases.dart';
import '../goal_tracker/domain/usecases/milestone_usecases.dart';
import '../goal_tracker/presentation/bloc/bloc_service_provider.dart';
import '../goal_tracker/presentation/pages/goal_list_page.dart';
import '../widgets/shared_square_button.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final int _selectedIndex = 0; // 1 indicates current Milestone tab

  void _onNavBarTap(int index) {
  if (index == 1) {
      Navigator.pushReplacementNamed(context, '/settings');
    }
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('AllTracker Home')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2, // Two buttons per row
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: [
            SquareButton(
              label: "Goal Tracker",
              icon: Icons.swipe_up_alt,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Scaffold(
                      // appBar: AppBar(title: const Text("Goals")),
                      body: buildGoalsPage(),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(        
        selectedItemColor: theme.colorScheme.onSurface,
        unselectedItemColor: theme.colorScheme.primary,
        backgroundColor: theme.colorScheme.onPrimary,
        currentIndex: _selectedIndex,
        selectedLabelStyle: const TextStyle(fontSize: 9.0, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 8.0),
        onTap: _onNavBarTap,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),// Uncomment if you add bottom bar later
    );
  }
}

Widget buildGoalsPage() {
  return FutureBuilder(
    future: HiveInitializer.initialize(tracker: TrackerType.goalManagement),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return Center(child: Text('Error loading Goals: ${snapshot.error}'));
      }

      return BlocServiceProvider(
        // GoalBloc dependencies
        getGoals: sl<GetGoals>(),
        getGoalById: sl<GetGoalById>(),
        addGoal: sl<AddGoal>(),
        updateGoal: sl<UpdateGoal>(),
        deleteGoal: sl<DeleteGoal>(),
        clearAllGoals: sl<ClearAllGoals>(),

        // MilestoneBloc dependencies
        getMilestones: sl<GetMilestones>(),
        getMilestoneById: sl<GetMilestoneById>(),
        addMilestone: sl<AddMilestone>(),
        updateMilestone: sl<UpdateMilestone>(),
        deleteMilestone: sl<DeleteMilestone>(),
        clearAllMilestones: sl<ClearAllMilestones>(),

        child: const GoalListPage(),
      );
    },
  );
}
