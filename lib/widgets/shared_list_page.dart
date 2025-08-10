import 'package:flutter/material.dart';
import 'shared_header.dart';

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
    final textColor = theme.colorScheme.onPrimary;

    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive vertical padding for ListView
    final verticalListPadding = screenWidth * 0.02; // ~2% of screen width
    // Responsive horizontal padding for overall layout
    final horizontalMargin = screenWidth * 0.04; // ~4% of screen width

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalMargin),
          child: Column(
            children: [
              SharedHeader(
                textColor: textColor,
                onAddPressed: onAddPressed,
              ),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(vertical: verticalListPadding),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    return itemBuilder(context, items[index]);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
