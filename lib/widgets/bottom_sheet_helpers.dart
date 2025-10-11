import 'package:flutter/material.dart';

/// Centralized bottom sheet helper to keep shape and scroll/keyboard behavior consistent.
///
/// Usage:
///   final result = await showAppBottomSheet<Map<String, dynamic>?>(
///     context,
///     MyBottomSheetWidget(...),
///   );
Future<T?> showAppBottomSheet<T>(BuildContext ctx, Widget child) {
  return showModalBottomSheet<T>(
    context: ctx,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(12.0)),
    ),
    builder: (c) {
      // Ensure the sheet responds to the keyboard inset and stays above it.
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(c).viewInsets.bottom,
        ),
        child: SafeArea(
          top: false,
          child: child,
        ),
      );
    },
  );
}
