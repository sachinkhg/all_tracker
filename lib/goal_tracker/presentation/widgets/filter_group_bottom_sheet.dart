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

enum FilterEntityType { goal, milestone, task }

class FilterGroupBottomSheet extends StatefulWidget {
  /// Which entity this filter sheet applies to.
  final FilterEntityType entity;

  /// For goals: semantic context value. For milestones: selected goalId. For tasks: selected milestoneId.
  final String? initialContext;
  final String? initialDateFilter;
  final String? initialGrouping;
  final String? initialStatus; // For tasks: selected status filter

  /// For milestones: list of goal options to display. Each item can be
  /// "<id>::<title>" or a single string (used as both id and title).
  final List<String>? goalOptions;

  /// For tasks: list of milestone options to display. Each item can be
  /// "<id>::<title>" or a single string (used as both id and title).
  final List<String>? milestoneOptions;
  
  /// Whether the save filter checkbox should be initially checked
  final bool initialSaveFilter;
  
  /// Whether the save sort checkbox should be initially checked
  final bool initialSaveSort;
  
  /// Initial sort order ('asc' or 'desc')
  final String? initialSortOrder;
  
  /// Initial hide completed setting
  final bool initialHideCompleted;

  const FilterGroupBottomSheet({
    super.key,
    required this.entity,
    this.initialContext,
    this.initialDateFilter,
    this.initialGrouping,
    this.initialStatus,
    this.goalOptions,
    this.milestoneOptions,
    this.initialSaveFilter = false,
    this.initialSaveSort = false,
    this.initialSortOrder,
    this.initialHideCompleted = false,
  });

  @override
  State<FilterGroupBottomSheet> createState() => _FilterGroupBottomSheetState();
}

class _FilterGroupBottomSheetState extends State<FilterGroupBottomSheet> {
  String? _selectedContext;
  String? _selectedDateFilter;
  String? _selectedStatus;
  String? _selectedGoalId; // For tasks: selected goal filter
  bool _saveFilter = false; // Save filter preference
  late final List<MapEntry<String, String>> _goalPairs; // id -> title
  late final List<MapEntry<String, String>> _milestonePairs; // id -> title
  
  // Sort-related state
  String _sortOrder = 'asc';
  bool _hideCompleted = false;
  bool _saveSort = false;

  @override
  void initState() {
    super.initState();
    // Initialize selections from incoming values to support edit/restore flows.
    _selectedContext = widget.initialContext;
    _selectedDateFilter = widget.initialDateFilter;
    _selectedStatus = widget.initialStatus;
    
    // Set initial save filter checkbox state
    _saveFilter = widget.initialSaveFilter;
    
    // Set initial save sort checkbox state
    _saveSort = widget.initialSaveSort;
    
    // Initialize sort settings
    _sortOrder = widget.initialSortOrder ?? 'asc';
    _hideCompleted = widget.initialHideCompleted;

    // Parse goalOptions if provided (used when entity == milestone or task)
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

    // Parse milestoneOptions if provided (used when entity == task)
    final milestoneRaws = (widget.milestoneOptions ?? [])
        .map((o) => o.trim())
        .where((o) => o.isNotEmpty)
        .toList(growable: false);
    _milestonePairs = milestoneRaws.map((raw) {
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
                  Tab(text: 'Sort'),
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
                                // Filter by Target Date (always shown first)
                                Text("Filter by Target Date", style: textTheme.bodySmall),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    for (final option in [
                                      "Today",
                                      "Tomorrow",
                                      "This Week",
                                      "Next Week",
                                      "This Month",
                                      "Next Month",
                                      "This Year",
                                      "Next Year",
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
                                const SizedBox(height: 16),
                                
                                // Second filter section (Context/Goal/Milestone)
                                if (widget.entity == FilterEntityType.goal) ...[
                                  Text("Filter by Context", style: textTheme.bodySmall),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
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
                                ] else if (widget.entity == FilterEntityType.milestone) ...[
                                  Text("Filter by Goal", style: textTheme.bodySmall),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      for (final entry in _goalPairs)
                                        Builder(builder: (ctx2) {
                                          final cs = Theme.of(ctx2).colorScheme;
                                          final bool selected = _selectedContext == entry.key;
                                          final double maxChipWidth = MediaQuery.of(ctx2).size.width - 48;
                                          return InkWell(
                                            borderRadius: BorderRadius.circular(16),
                                            onTap: () {
                                              setState(() {
                                                _selectedContext = selected ? null : entry.key;
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
                                  ),
                                ] else ...[
                                  // Task filters
                                  Text("Filter by Milestone", style: textTheme.bodySmall),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      for (final entry in _milestonePairs)
                                        Builder(builder: (ctx2) {
                                          final cs = Theme.of(ctx2).colorScheme;
                                          final bool selected = _selectedContext == entry.key;
                                          final double maxChipWidth = MediaQuery.of(ctx2).size.width - 48;
                                          return InkWell(
                                            borderRadius: BorderRadius.circular(16),
                                            onTap: () {
                                              setState(() {
                                                _selectedContext = selected ? null : entry.key;
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
                                  ),
                                  const SizedBox(height: 16),
                                  Text("Filter by Goal", style: textTheme.bodySmall),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      for (final entry in _goalPairs)
                                        Builder(builder: (ctx2) {
                                          final cs = Theme.of(ctx2).colorScheme;
                                          final bool selected = _selectedGoalId == entry.key;
                                          final double maxChipWidth = MediaQuery.of(ctx2).size.width - 48;
                                          return InkWell(
                                            borderRadius: BorderRadius.circular(16),
                                            onTap: () {
                                              setState(() {
                                                _selectedGoalId = selected ? null : entry.key;
                                              });
                                            },
                                            child: ConstrainedBox(
                                              constraints: BoxConstraints(maxWidth: maxChipWidth),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                decoration: BoxDecoration(
                                                  color: selected ? cs.secondary.withValues(alpha: 0.12) : null,
                                                  border: Border.all(color: selected ? cs.secondary : cs.outline.withValues(alpha: 0.30)),
                                                  borderRadius: BorderRadius.circular(16),
                                                ),
                                                child: Text(
                                                  entry.value,
                                                  softWrap: true,
                                                  style: TextStyle(
                                                    color: selected ? cs.secondary : cs.onSurface,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        }),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Text("Filter by Status", style: textTheme.bodySmall),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      for (final status in ['To Do', 'In Progress', 'Complete'])
                                        ChoiceChip(
                                          label: Text(status),
                                          selected: _selectedStatus == status,
                                          onSelected: (sel) {
                                            setState(() {
                                              _selectedStatus = sel ? status : null;
                                            });
                                          },
                                        ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),

                        // Save Filter checkbox
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                          child: Row(
                            children: [
                              Checkbox(
                                value: _saveFilter,
                                onChanged: (value) {
                                  setState(() {
                                    _saveFilter = value ?? false;
                                  });
                                },
                              ),
                              const SizedBox(width: 8),
                              const Text("Save Filter"),
                            ],
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
                                  if (widget.entity == FilterEntityType.task) {
                                    Navigator.of(context).pop({
                                      "milestoneId": _selectedContext,
                                      "goalId": _selectedGoalId,
                                      "status": _selectedStatus,
                                      "targetDate": _selectedDateFilter,
                                      "saveFilter": _saveFilter,
                                    });
                                  } else {
                                    Navigator.of(context).pop({
                                      "context": _selectedContext,
                                      "targetDate": _selectedDateFilter,
                                      "saveFilter": _saveFilter,
                                    });
                                  }
                                },
                                child: const Text("Apply Filter"),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // ===== SORT TAB =====
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
                                // Sort Order Section
                                Text("Sort Order", style: textTheme.bodySmall),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: RadioListTile<String>(
                                        title: const Text("Ascending"),
                                        subtitle: const Text("Earliest first"),
                                        value: 'asc',
                                        groupValue: _sortOrder,
                                        onChanged: (value) {
                                          setState(() {
                                            _sortOrder = value!;
                                          });
                                        },
                                        dense: true,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                    Expanded(
                                      child: RadioListTile<String>(
                                        title: const Text("Descending"),
                                        subtitle: const Text("Latest first"),
                                        value: 'desc',
                                        groupValue: _sortOrder,
                                        onChanged: (value) {
                                          setState(() {
                                            _sortOrder = value!;
                                          });
                                        },
                                        dense: true,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                
                                // Hide Completed Section
                                Text("Display Options", style: textTheme.bodySmall),
                                const SizedBox(height: 8),
                                CheckboxListTile(
                                  title: const Text("Hide Completed Items"),
                                  subtitle: const Text("Don't show completed goals/milestones/tasks"),
                                  value: _hideCompleted,
                                  onChanged: (value) {
                                    setState(() {
                                      _hideCompleted = value ?? false;
                                    });
                                  },
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Save Sort checkbox
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                          child: Row(
                            children: [
                              Checkbox(
                                value: _saveSort,
                                onChanged: (value) {
                                  setState(() {
                                    _saveSort = value ?? false;
                                  });
                                },
                              ),
                              const SizedBox(width: 8),
                              const Text("Save Sort"),
                            ],
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
                                  Navigator.of(context).pop({
                                    "sortOrder": _sortOrder,
                                    "hideCompleted": _hideCompleted,
                                    "saveSort": _saveSort,
                                  });
                                },
                                child: const Text("Apply Sort"),
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
