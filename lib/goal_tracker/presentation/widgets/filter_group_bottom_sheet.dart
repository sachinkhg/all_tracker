// lib/presentation/widgets/filter_group_bottom_sheet.dart
import 'package:flutter/material.dart';
import '../../core/constants.dart'; // path to kContextOptions

/// ---------------------------------------------------------------------------
/// FilterGroupBottomSheet
///
/// File purpose:
/// - Provides a modal bottom-sheet UI that allows users to filter and (later)
///   group goals. Contains two tabs: "Filter" and "Group".
/// - Filter tab supports: context selection (from kContextOptions) and a set
///   of predefined target-date filters (This Month, This Year, etc.).
/// - Group tab is a placeholder for future grouping features.
///
/// Interaction & UX rules:
/// - Uses a DefaultTabController so TabBar and TabBarView have a controller
///   without requiring an external TabController (prevents "No TabController"
///   errors when this widget is shown in isolation).
/// - Respects keyboard insets (viewInsets) so form UI doesn't get covered by
///   the on-screen keyboard. The padding is applied only while visible so the
///   sheet does not permanently reserve extra bottom space.
/// - Returns a map with the selected filters when "Apply Filter" is pressed:
///   { "context": String? , "targetDate": String? }
///
/// Compatibility & developer notes:
/// - kContextOptions is the single source of truth for available contexts.
///   When adding or renaming contexts, update core/constants.dart and any
///   persisted filters or migration notes accordingly.
/// - Keep the filter keys stable to avoid migration complexity in persisted
///   filter storage (if implemented later).
/// - The grouping tab is intentionally minimal; implement grouping behavior
///   in the feature layer and map selections to domain logic there.
/// ---------------------------------------------------------------------------

class FilterGroupBottomSheet extends StatefulWidget {
  final String? initialContext;
  final String? initialDateFilter;
  final String? initialGrouping;

  const FilterGroupBottomSheet({
    super.key,
    this.initialContext,
    this.initialDateFilter,
    this.initialGrouping,
  });

  @override
  State<FilterGroupBottomSheet> createState() => _FilterGroupBottomSheetState();
}

class _FilterGroupBottomSheetState extends State<FilterGroupBottomSheet> {
  String? _selectedContext;
  String? _selectedDateFilter;

  @override
  void initState() {
    super.initState();
    // Initialize selections from incoming values to support edit/restore flows.
    _selectedContext = widget.initialContext;
    _selectedDateFilter = widget.initialDateFilter;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // Limit sheet height so it doesn't cover the entire screen on large devices.
    final maxHeight = MediaQuery.of(context).size.height * 0.40;
    // Respect keyboard insets so interactive controls remain visible when the
    // keyboard appears (e.g., if later expanded to include text inputs).
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    // Provide a TabController for TabBar & TabBarView
    return DefaultTabController(
      length: 2,
      child: Padding(
        // respect keyboard insets but do NOT permanently add bottom safe padding
        padding: EdgeInsets.only(bottom: viewInsets),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // little top handle space
              const SizedBox(height: 12),
              const TabBar(
                tabs: [
                  Tab(text: 'Filter'),
                  Tab(text: 'Group'),
                ],
              ),
              // Tab content
              Flexible(
                child: TabBarView(
                  children: [
                    // ===== FILTER TAB =====
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Filter by Context", style: textTheme.bodySmall),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    // Build ChoiceChips from kContextOptions.
                                    // Using the constants list ensures consistency
                                    // across the app when contexts are modified.
                                    for (final ctx in kContextOptions)
                                      ChoiceChip(
                                        label: Text(ctx),
                                        selected: _selectedContext == ctx,
                                        onSelected: (sel) {
                                          setState(() {
                                            _selectedContext = sel ? ctx : null;
                                          });
                                        },
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text("Filter by Target Date", style: textTheme.bodySmall),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    for (final option in [
                                      "This Month",
                                      "This Year",
                                      "Next Month",
                                      "Next Year"
                                    ])
                                      ChoiceChip(
                                        label: Text(option),
                                        selected: _selectedDateFilter == option,
                                        onSelected: (sel) {
                                          setState(() {
                                            _selectedDateFilter = sel ? option : null;
                                          });
                                        },
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Buttons — tight padding so they're close to content, not floating
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text("Close"),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                onPressed: () {
                                  // Return a simple map of the chosen filters.
                                  Navigator.of(context).pop({
                                    "context": _selectedContext,
                                    "targetDate": _selectedDateFilter,
                                  });
                                },
                                child: const Text("Apply Filter"),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // ===== GROUP TAB =====
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Grouping (TODO)", style: textTheme.bodySmall),
                                const SizedBox(height: 8),
                                const Text("This section will let you group goals later."),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text("Close"),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                onPressed: () {
                                  // Currently mirrors the filter behavior; when grouping
                                  // is implemented, this should return grouping choices.
                                  Navigator.of(context).pop({
                                    "context": _selectedContext,
                                    "targetDate": _selectedDateFilter,
                                  });
                                },
                                child: const Text("Apply Filter"),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
