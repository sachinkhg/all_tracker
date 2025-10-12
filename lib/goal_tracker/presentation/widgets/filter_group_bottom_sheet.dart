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

enum FilterEntityType { goal, milestone }

class FilterGroupBottomSheet extends StatefulWidget {
  /// Which entity this filter sheet applies to.
  final FilterEntityType entity;

  /// For goals: semantic context value. For milestones: selected goalId.
  final String? initialContext;
  final String? initialDateFilter;
  final String? initialGrouping;

  /// For milestones: list of goal options to display. Each item can be
  /// "<id>::<title>" or a single string (used as both id and title).
  final List<String>? goalOptions;

  const FilterGroupBottomSheet({
    super.key,
    required this.entity,
    this.initialContext,
    this.initialDateFilter,
    this.initialGrouping,
    this.goalOptions,
  });

  @override
  State<FilterGroupBottomSheet> createState() => _FilterGroupBottomSheetState();
}

class _FilterGroupBottomSheetState extends State<FilterGroupBottomSheet> {
  String? _selectedContext;
  String? _selectedDateFilter;
  late final List<MapEntry<String, String>> _goalPairs; // id -> title

  @override
  void initState() {
    super.initState();
    // Initialize selections from incoming values to support edit/restore flows.
    _selectedContext = widget.initialContext;
    _selectedDateFilter = widget.initialDateFilter;

    // Parse goalOptions if provided (used when entity == milestone)
    final raws = (widget.goalOptions ?? [])
        .map((o) => o.trim())
        .where((o) => o.isNotEmpty)
        .toList(growable: false);
    _goalPairs = raws.map((raw) {
      if (raw.contains('::')) {
        final parts = raw.split('::');
        return MapEntry(parts.first.trim(), parts.sublist(1).join('::').trim());
      }
      return MapEntry(raw, raw);
    }).toList(growable: false);
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
                                Text(
                                  widget.entity == FilterEntityType.goal
                                      ? "Filter by Context"
                                      : "Filter by Goal",
                                  style: textTheme.bodySmall,
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    if (widget.entity == FilterEntityType.goal) ...[
                                      // Build ChoiceChips from kContextOptions.
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
                                    ] else ...[
                                      // Milestone: custom selectable tags that support multi-line wrapping
                                      for (final entry in _goalPairs)
                                        Builder(builder: (ctx2) {
                                          final cs = Theme.of(ctx2).colorScheme;
                                          final bool selected = _selectedContext == entry.key;
                                          final double maxChipWidth = MediaQuery.of(ctx2).size.width - 48; // padding + spacing
                                          return InkWell(
                                            borderRadius: BorderRadius.circular(16),
                                            onTap: () {
                                              setState(() {
                                                _selectedContext = selected ? null : entry.key; // store id
                                              });
                                            },
                                            child: ConstrainedBox(
                                              constraints: BoxConstraints(maxWidth: maxChipWidth),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                decoration: BoxDecoration(
                                                  color: selected ? cs.primary.withValues(alpha: 0.12) : null,
                                                  border: Border.all(color: selected ? cs.primary : cs.outline.withValues(alpha: 0.30)),
                                                  borderRadius: BorderRadius.circular(16),
                                                ),
                                                child: Text(
                                                  entry.value,
                                                  softWrap: true,
                                                  style: TextStyle(
                                                    color: selected ? cs.primary : cs.onSurface,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        }),
                                    ],
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
