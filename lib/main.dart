import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme_notifier.dart';
import 'presentation/home_page.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: const AllTrackerApp(),
    ),
  );
}

class AllTrackerApp extends StatelessWidget {
  const AllTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeNotifier>(context);
    return MaterialApp(
      title: 'AllTracker',
      debugShowCheckedModeBanner: false,
      theme: themeProvider.currentTheme,
      home: const HomePage(),
    );
  }
}
