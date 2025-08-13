import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/hive_initializer.dart';
import '../core/service_locator.dart';
import '../goal_tracker/domain/usecases/goal_usecases.dart';
import '../goal_tracker/presentation/bloc/goal_bloc.dart';
import '../goal_tracker/presentation/bloc/goal_event.dart';
import '../goal_tracker/presentation/pages/goal_list_page.dart';
import '../presentation/settings_page.dart';
//import '../presentation/webapp_screen.dart';

/// A custom bottom navigation bar widget that displays a list of navigation items,
/// each associated with an icon, label, and page. The selected page is shown above
/// the navigation bar, and tapping an item switches to its corresponding page.
/// 
/// Usage:
/// - Provide a list of [BottomBarItem]s, each specifying an icon, label, and page.
/// - Optionally set [initialIndex] to specify the initially selected item.
/// 
/// Example:
/// ```dart
/// AppBottomBar(
///   items: [
///     BottomBarItem(icon: Icons.home, label: 'Home', page: HomePage()),
///     BottomBarItem(icon: Icons.settings, label: 'Settings', page: SettingsPage()),
///   ],
/// )
/// ```

AppBottomBar createAppBottomBar() {
  return AppBottomBar(
    items: [
      BottomBarItem(
        icon: Icons.home,
        label: 'Home',
        content: Center(child: Text('Welcome to AllTracker Home!')),
      ),
      BottomBarItem(
        icon: Icons.flag,
        label: 'Goals',
        content: FutureBuilder(
          future: HiveInitializer.initialize(tracker: TrackerType.goalManagement),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error loading Goals: ${snapshot.error}'));
            }

            return BlocProvider(
              create: (_) => GoalBloc(
                getGoals: sl<GetGoals>(),
                getGoalById: sl<GetGoalById>(),
                addGoal: sl<AddGoal>(),
                updateGoal: sl<UpdateGoal>(),
                deleteGoal: sl<DeleteGoal>(),
                clearAllGoals: sl<ClearAllGoals>(),
              )..add(LoadGoals()),
              child: const GoalListPage(),
            );
          },
        ),
      ),
      BottomBarItem(
        icon: Icons.settings,
        label: 'Settings',
        content: SettingsPage(),
      ),
    ],
  );
}

/// Represents an item in the bottom navigation bar, including its icon, label, and associated page.
class BottomBarItem {
  final IconData icon;
  final String label;
  final Widget content;

  const BottomBarItem({
    required this.icon,
    required this.label,
    required this.content,
  });
}

class AppBottomBar extends StatefulWidget {
  final List<BottomBarItem> items;
  final int initialIndex;

  const AppBottomBar({
    super.key,
    required this.items,
    this.initialIndex = 0,
  });

  @override
  State<AppBottomBar> createState() => _AppBottomBarState();
}

class _AppBottomBarState extends State<AppBottomBar> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTap(int index) {
      // Prevent unnecessary state updates if the tapped index is already selected.
      if (_currentIndex == index) return;
      setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: widget.items[_currentIndex].content,
        ),
        BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: theme.colorScheme.onPrimary,
          selectedItemColor: theme.colorScheme.primary,
          unselectedItemColor:theme.colorScheme.primary.withAlpha(150),
              currentIndex: _currentIndex,
              items: widget.items
              .map((item) => BottomNavigationBarItem(
                    icon: Icon(item.icon),
                    label: item.label,
                  ))
              .toList(),
          onTap: _onTap,
        ),
      ],
    );
  }
}