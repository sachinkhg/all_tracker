import 'package:flutter/material.dart';

class SharedTextBox extends StatelessWidget {
  final String? label;
  final String? hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final bool readOnly;
  final VoidCallback? onTap;
  final int maxLines;
  final FocusNode? focusNode; // ✅ New parameter

  const SharedTextBox({
    super.key,
    this.label,
    this.hintText,
    this.controller,
    this.onChanged,
    this.readOnly = false,
    this.onTap,
    this.maxLines = 1,
    this.focusNode, // ✅ Now part of constructor
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Responsive sizing
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final borderRadius = BorderRadius.circular(screenWidth * 0.03);
    final fontSize = screenWidth * 0.04;
    final verticalPadding = screenHeight * 0.015;
    final horizontalPadding = screenWidth * 0.04; // ✅ fixed padding

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: TextStyle(
              fontSize: fontSize * 0.85,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onPrimary.withOpacity(0.85),
            ),
          ),
          const SizedBox(height: 4),
        ],
        TextField(
          controller: controller,
          focusNode: focusNode, // ✅ Pass focus node to TextField
          onChanged: onChanged,
          readOnly: readOnly,
          onTap: onTap,
          maxLines: maxLines,
          style: TextStyle(
            fontSize: fontSize,
            color: theme.colorScheme.onPrimary,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: theme.colorScheme.onPrimary.withOpacity(0.6),
              fontSize: fontSize * 0.9,
            ),
            filled: true,
            fillColor: theme.colorScheme.primary,
            contentPadding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            border: OutlineInputBorder(
              borderRadius: borderRadius,
              borderSide: BorderSide(color: theme.colorScheme.onPrimary),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: borderRadius,
              borderSide: BorderSide(color: theme.colorScheme.onPrimary, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: borderRadius,
              borderSide: BorderSide(
                color: theme.colorScheme.onPrimary,
                width: 2.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
