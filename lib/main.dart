import 'package:all_tracker/core/hive_initializer.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/app_typography.dart';

import 'goal_tracker/presentation/pages/home_page.dart';
import 'core/theme_notifier.dart';

/// Box name constant for storing goals in Hive
// const String GOAL_BOX = 'goals_box';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // // Open the box for GoalModel objects
  HiveInitializer.initialize();

  // print('Printing all milestones in box:');
  // for (var key in box.keys) {
  //   var goal = box.get(key);
  //   print('Key: $key, name: ${goal?.name}, targetDate: ${goal?.targetDate}, context: ${goal?.context}, isCompleted: ${goal?.isCompleted}');
  // }

  // Provide ThemeNotifier above the app so MyApp can read the current theme
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Read theme from ThemeNotifier
    final themeProvider = Provider.of<ThemeNotifier>(context);

    // Merge AppTypography into the ThemeData returned by ThemeNotifier.
    // This ensures the app uses the typography defined in core/app_typography.dart
    final ThemeData mergedTheme = themeProvider.currentTheme.copyWith(
      textTheme: AppTypography.textTheme(themeProvider.currentTheme.colorScheme),
      primaryTextTheme: AppTypography.textTheme(themeProvider.currentTheme.colorScheme),
    );
    return MaterialApp(
      title: 'Goal Tracker',
      debugShowCheckedModeBanner: false,
      theme: mergedTheme,
      // If you support an explicit darkTheme in ThemeNotifier, you can also
      // merge typography into it. Here we reuse the same mergedTheme for both,
      // but you can customize as needed.
      darkTheme: themeProvider.currentTheme.copyWith(
        textTheme: AppTypography.textTheme(themeProvider.currentTheme.colorScheme),
        primaryTextTheme: AppTypography.textTheme(themeProvider.currentTheme.colorScheme),
      ),
      home: const HomePage(),
    );
  }
}