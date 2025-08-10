import 'package:flutter/material.dart';

class SharedDropdown<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final ValueChanged<T?> onChanged;
  final String Function(T) itemLabel;

  const SharedDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.itemLabel,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Define font size and padding relative to screen width
    final fontSize = screenWidth * 0.04; // ~16px at 400px width
    final verticalPadding = screenWidth * 0.015; // vertical padding inside menu items

    return DropdownButton<T>(
      value: value,
      onChanged: onChanged,
      isExpanded: true, // Make dropdown take full width
      underline: Container(
        height: 1,
        color: Theme.of(context).dividerColor,
      ),
      items: items.map((item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: verticalPadding),
            child: Text(
              itemLabel(item),
              style: TextStyle(fontSize: fontSize),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      }).toList(),
      style: TextStyle(
        fontSize: fontSize,
        color: Theme.of(context).textTheme.bodyLarge?.color,
      ),
      iconSize: fontSize * 1.25, // icon size proportional to font size
    );
  }
}
