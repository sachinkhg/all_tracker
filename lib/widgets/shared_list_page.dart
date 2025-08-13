import 'package:flutter/material.dart';

// Keeping typedef for itemBuilder
typedef SharedItemBuilder<T> = Widget Function(BuildContext context, T item);

class SharedListPage<T> extends StatelessWidget {
  final List<T> items;
  final SharedItemBuilder<T> itemBuilder;
  final String title;
  final VoidCallback? onAddPressed;

  const SharedListPage({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.title = 'Items',
    this.onAddPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = theme.colorScheme.primary;

    final screenHeight = MediaQuery.of(context).size.height;

    // Make top padding around 2% of screen height (tweak as needed)
    final topPadding = screenHeight * 0.05;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: ListView.builder(
          padding: EdgeInsets.only(
            top: topPadding, // ✅ Dynamic top padding based on screen size
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            return itemBuilder(context, items[index]);
          },
        ),
      ),
    );
  }
}
