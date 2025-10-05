import 'package:flutter/material.dart';

/// Shared context dropdown component which opens a bottom sheet with options.
/// By default it uses `kContextOptions` from constants.dart so everything
/// across the app can share the same list.
///
/// Returns:
///  - `null` if user cancelled (no change)
///  - `''` (empty string) if user explicitly cleared selection
///  - chosen String value otherwise
class ContextDropdownBottomSheet {
  static Future<String?> showContextPicker(
    BuildContext context, {
    String? initialContext,
    String title = 'Select context',
    required List<String> options, // optional override, defaults to kContextOptions
  }) {
    final List<String> opts = options;

    return showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        String? selected = initialContext;
        final cs = Theme.of(ctx).colorScheme;
        final textTheme = Theme.of(ctx).textTheme;

        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: StatefulBuilder(
            builder: (ctx2, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(title, style: textTheme.titleLarge),
                      IconButton(
                        icon: Icon(Icons.close, color: cs.onSurfaceVariant),
                        onPressed: () => Navigator.pop(ctx2, null), // cancel => null
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Options from constants (or override)
                  ...opts.map((opt) {
                    final isSelected = opt == selected;
                    return ListTile(
                      title: Text(opt),
                      trailing: isSelected ? Icon(Icons.check, color: cs.primary) : null,
                      onTap: () => setState(() => selected = opt),
                    );
                  }).toList(),

                  const Divider(),

                  // Clear, Cancel, Done buttons row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx2, ''), // explicit clear -> return empty string
                        child: const Text('Clear'),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx2, null), // cancel -> null
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx2, selected),
                        child: const Text('Done'),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
