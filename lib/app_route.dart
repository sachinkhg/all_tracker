import 'package:all_tracker/presentation/settings_page.dart';
import 'package:flutter/material.dart';

import 'core/service_locator.dart';
import 'goal_tracker/domain/usecases/goal_usecases.dart';
import 'goal_tracker/domain/usecases/milestone_usecases.dart';
import 'goal_tracker/presentation/bloc/bloc_service_provider.dart';
import 'goal_tracker/presentation/pages/goal_list_page.dart';
import 'presentation/home_page.dart';

class AppRoutes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/goal-list':
        return MaterialPageRoute(
          builder: (_) => BlocServiceProvider(
            getGoals: sl(),
            getGoalById: sl(),
            addGoal: sl(),
            updateGoal: sl(),
            deleteGoal: sl(),
            clearAllGoals: sl(),
            getMilestones: sl(),
            getMilestoneById: sl(),
            addMilestone: sl(),
            updateMilestone: sl(),
            deleteMilestone: sl(),
            clearAllMilestones: sl(),
            child: const GoalListPage(),
          ),
        );  
      case '/home':
        return MaterialPageRoute(builder: (_) => const HomePage());
      case '/settings':
        return MaterialPageRoute(builder: (_) => const SettingsPage()); 
      case '/': 
        return MaterialPageRoute(builder: (_) => const HomePage());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}

class RootScaffold extends StatefulWidget{

  const RootScaffold({super.key});
  

  @override
  State<RootScaffold> createState() => _RootScaffoldState();

}

//final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
class _RootScaffoldState extends State<RootScaffold> {
  int _selectedIndex = 0;
static final List<Widget> _pages = [
  HomePage(),
  BlocServiceProvider(
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
  ),
  SettingsPage(),
];

void _onNavTap(int index) {
  setState(() {
    _selectedIndex = index;
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //key: _scaffoldKey,
      body: _pages[_selectedIndex], 
      bottomNavigationBar: 
      // createAppBottomBar()
      AppBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onNavTap,
      ),
    );
  }
}

class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      selectedItemColor: theme.colorScheme.onSurface,
      unselectedItemColor: theme.colorScheme.primary,
      backgroundColor: theme.colorScheme.onPrimary,
      selectedLabelStyle: const TextStyle(fontSize: 9.0, fontWeight: FontWeight.w600),
      unselectedLabelStyle: const TextStyle(fontSize: 8.0),
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.swipe_up_alt),
          label: 'Goal',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: 'Settings',
        ),
      ],
    );
  }
}