import 'package:flutter/material.dart';

/// ----------------------------------------------------------------------------
/// File purpose:
/// This file contains a shared UI component that displays a context selection
/// dropdown as a bottom sheet. It is intended for use across the app wherever
/// the user needs to pick or clear a "context" string (for example: Home,
/// Work, Personal).
///
/// NOTE (serialization / Hive guidance):
/// * Although this file is purely UI, when choosing or persisting the selected
///   context elsewhere (Hive / DTOs), follow these rules:
///   - Explicitly document which fields are nullable and what default values
///     are used in the persisted model (e.g. `context: ''` means cleared).
///   - Do not reuse Hive field numbers when evolving models — always add new
///     field numbers and add migration logic. Update `migration_notes.md` when
///     changing any persisted model shape.
///   - If you convert legacy values (e.g. `null` -> `''`), centralize that
///     conversion in the DTO/fromEntity helpers so UI components remain simple.
/// ----------------------------------------------------------------------------

/// Shared context dropdown component which opens a bottom sheet with options.
/// By default it uses `kContextOptions` from constants.dart so everything
/// across the app can share the same list.
///
/// Returns:
///  - `null` if user cancelled (no change)
///  - `''` (empty string) if user explicitly cleared selection
///  - chosen String value otherwise
class ContextDropdownBottomSheet {
  /// Show a bottom sheet that allows selecting a context string.
  ///
  /// Parameters:
  ///  - [context] : Flutter build context for showing the bottom sheet.
  ///  - [initialContext] : the currently selected context (nullable). Keep this
  ///      nullable to represent "no selection".
  ///  - [title] : optional header title shown at top of sheet.
  ///  - [options] : list of available options. This overrides any app-level
  ///      constants (such as `kContextOptions`) and should be a non-null
  ///      list. The component does not mutate the provided list.
  ///
  /// Important behavior notes (developer-focused):
  ///  - The sheet returns `null` on cancel to indicate no change; callers that
  ///    persist selections should treat `null` as "do nothing".
  ///  - The sheet returns `''` (empty string) when user explicitly clears the
  ///    selection — callers should persist this as the cleared value.
  ///  - Keep conversion of legacy persisted values (for example, migrating
  ///    `null` -> `''` or mapping old enum values) out of this UI and inside
  ///    the model/DTO layer. This keeps the UI logic straightforward.
  static Future<String?> showContextPicker(
    BuildContext context, {
    String? initialContext,
    String title = 'Select context',
    required List<String> options, // optional override, defaults to kContextOptions
  }) {
    // Keep a local reference to the options. The UI will not mutate this list.
    final List<String> opts = options;

    return showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        // selected represents the currently chosen value inside the sheet.
        // It starts from initialContext (which may be null meaning "no selection").
        // Any conversion from legacy persisted values should be handled before
        // calling this method (e.g. convert `null` to '' if desired by app logic).
        String? selected = initialContext;
        final cs = Theme.of(ctx).colorScheme;
        final textTheme = Theme.of(ctx).textTheme;

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          builder: (ctx3, scrollController) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 20,
                // Include viewInsets.bottom so the sheet moves above the keyboard
                // when present — important for accessibility on smaller screens.
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: StatefulBuilder(
                // StatefulBuilder is used to manage selection state locally inside
                // the sheet without forcing a larger StatefulWidget. Keeps this
                // component simple and focused on UI concerns only.
                builder: (ctx2, setState) {
                  return ListView(
                    controller: scrollController,
                    shrinkWrap: true,
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
                      // Each option updates the local `selected` variable. Note that we
                      // only update UI state here; persisting is the caller's duty after
                      // the sheet returns a non-null / empty-string value.
                      ...opts.map((opt) {
                        // Compare using equality; if you later change option types
                        // (e.g. to an object), update comparison logic accordingly.
                        final isSelected = opt == selected;
                        return ListTile(
                          title: Text(opt),
                          trailing: isSelected ? Icon(Icons.check, color: cs.primary) : null,
                          onTap: () => setState(() => selected = opt),
                        );
                      }),

                      const Divider(),

                      // Clear, Cancel, Done buttons row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            // Explicit clear -> return empty string. Caller should treat
                            // empty string as a deliberate cleared-value (different from null).
                            onPressed: () => Navigator.pop(ctx2, ''), // explicit clear -> return empty string
                            child: const Text('Clear'),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            // Cancel -> null. This signals "no change" to the caller.
                            onPressed: () => Navigator.pop(ctx2, null), // cancel -> null
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            // Done -> return the currently selected value (may be null).
                            // Callers should validate and persist as needed.
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
      },
    );
  }
}
