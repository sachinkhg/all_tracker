import 'package:flutter/material.dart';
import '../presentation/goal_list.dart';
import '../presentation/settings_page.dart';

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
        icon: Icons.list,
        label: 'Goals',
        content: GoalsListPage(),
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
          backgroundColor: theme.colorScheme.primary,
          selectedItemColor: theme.colorScheme.onPrimary,
          unselectedItemColor:theme.colorScheme.onPrimary.withAlpha(150),
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