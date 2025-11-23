// lib/presentation/widgets/filter_group_bottom_sheet.dart
import 'package:flutter/material.dart';
import '../../core/constants.dart'; // path to kContextOptions
import '../../../travel_tracker/core/constants.dart' as travel_constants; // for ItineraryItemType

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

enum FilterEntityType { goal, milestone, task, habit, itinerary, trip }

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
  
  /// For tasks: map of milestoneId -> goalId for filtering milestones by goal
  final Map<String, String>? milestoneToGoalMap;
  
  /// For tasks: initial goalId filter (used when goal is selected without milestone)
  final String? initialGoalId;
  
  /// Whether the save filter checkbox should be initially checked
  final bool initialSaveFilter;
  
  /// Whether the save sort checkbox should be initially checked
  final bool initialSaveSort;
  
  /// Initial sort order ('asc' or 'desc')
  final String? initialSortOrder;
  
  /// Initial hide completed setting
  final bool initialHideCompleted;
  
  /// For itinerary: initial item type filter
  final String? initialItemType;

  const FilterGroupBottomSheet({
    super.key,
    required this.entity,
    this.initialContext,
    this.initialDateFilter,
    this.initialGrouping,
    this.initialStatus,
    this.goalOptions,
    this.milestoneOptions,
    this.milestoneToGoalMap,
    this.initialGoalId,
    this.initialSaveFilter = false,
    this.initialSaveSort = false,
    this.initialSortOrder,
    this.initialHideCompleted = true,
    this.initialItemType,
  });

  @override
  State<FilterGroupBottomSheet> createState() => _FilterGroupBottomSheetState();
}

class _FilterGroupBottomSheetState extends State<FilterGroupBottomSheet> {
  String? _selectedContext;
  String? _selectedDateFilter;
  String? _selectedStatus;
  String? _selectedGoalId; // For tasks: selected goal filter
  String? _selectedItemType; // For itinerary: selected item type filter
  bool _saveFilter = false; // Save filter preference
  late final List<MapEntry<String, String>> _goalPairs; // id -> title
  late final List<MapEntry<String, String>> _milestonePairs; // id -> title
  late final Map<String, String> _milestoneToGoalMap; // milestoneId -> goalId
  
  // Sort-related state
  String _sortOrder = 'asc';
  bool _hideCompleted = true; // Default to true (hide completed items by default)
  bool _saveSort = false;

  @override
  void initState() {
    super.initState();
    // Initialize selections from incoming values to support edit/restore flows.
    _selectedContext = widget.initialContext;
    _selectedDateFilter = widget.initialDateFilter;
    _selectedStatus = widget.initialStatus;
    _selectedItemType = widget.initialItemType;
    
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
    
    // Initialize milestone-to-goal mapping for tasks and habits
    _milestoneToGoalMap = widget.milestoneToGoalMap ?? {};
    
    // Initialize goal filter for tasks and habits
    if (widget.entity == FilterEntityType.task || widget.entity == FilterEntityType.habit) {
      // First, check if there's an explicit initial goalId
      if (widget.initialGoalId != null) {
        _selectedGoalId = widget.initialGoalId;
      }
      // If there's an initial milestone selected, find its goal (unless goalId already set)
      else if (widget.initialContext != null) {
        final milestoneId = widget.initialContext;
        if (_milestoneToGoalMap.containsKey(milestoneId)) {
          _selectedGoalId = _milestoneToGoalMap[milestoneId];
        }
      }
    }
  }
  
  /// Get filtered milestone pairs based on selected goal
  List<MapEntry<String, String>> get _filteredMilestonePairs {
    if (_selectedGoalId == null) {
      // Show all milestones when "All Goals" is selected
      return _milestonePairs;
    }
    // Filter milestones to show only those belonging to the selected goal
    return _milestonePairs.where((entry) {
      return _milestoneToGoalMap[entry.key] == _selectedGoalId;
    }).toList();
  }


  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    // Limit sheet height so it doesn't cover the entire screen on large devices.
    final maxHeight = MediaQuery.of(context).size.height * 0.65;
    // Respect keyboard insets so interactive controls remain visible when the
    // keyboard appears (e.g., if later expanded to include text inputs).
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    // Provide a TabController for TabBar & TabBarView
    final bool isHabit = widget.entity == FilterEntityType.habit;
    final bool isTrip = widget.entity == FilterEntityType.trip;
    final bool isItinerary = widget.entity == FilterEntityType.itinerary;
    return DefaultTabController(
      length: (isHabit || isTrip || isItinerary) ? 1 : 2,
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
              TabBar(
                tabs: [
                  const Tab(text: 'Filter'),
                  if (!isHabit && !isTrip && !isItinerary) const Tab(text: 'Sort'),
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
                                // Filter by Target Date (hidden for habits)
                                if (widget.entity != FilterEntityType.habit) ...[
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
                                ],
                                
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
                                  DropdownButtonFormField<String>(
                                    value: _selectedContext,
                                    isExpanded: true,
                                    style: TextStyle(color: colorScheme.onSurface),
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                    ),
                                    hint: Text(
                                      "All Goals",
                                      style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6)),
                                    ),
                                    items: [
                                      DropdownMenuItem<String>(
                                        value: null,
                                        child: Text(
                                          "All Goals",
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(color: colorScheme.onSurface),
                                        ),
                                      ),
                                      ..._goalPairs.map((entry) => DropdownMenuItem<String>(
                                        value: entry.key,
                                        child: Text(
                                          entry.value,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(color: colorScheme.onSurface),
                                        ),
                                      )),
                                    ],
                                    selectedItemBuilder: (context) {
                                      return [
                                        Text(
                                          "All Goals",
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(color: colorScheme.onSurface),
                                        ),
                                        ..._goalPairs.map((entry) => Text(
                                          entry.value,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(color: colorScheme.onSurface),
                                        )),
                                      ];
                                    },
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedContext = value;
                                      });
                                    },
                                  ),
                                ] else if (widget.entity == FilterEntityType.task) ...[
                                  // Task filters - Cascading dropdowns: Goal first, then Milestone
                                  Text("Filter by Goal", style: textTheme.bodySmall),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    value: _selectedGoalId,
                                    isExpanded: true,
                                    style: TextStyle(color: colorScheme.onSurface),
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                    ),
                                    hint: Text(
                                      "All Goals",
                                      style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6)),
                                    ),
                                    items: [
                                      DropdownMenuItem<String>(
                                        value: null,
                                        child: Text(
                                          "All Goals",
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(color: colorScheme.onSurface),
                                        ),
                                      ),
                                      ..._goalPairs.map((entry) => DropdownMenuItem<String>(
                                        value: entry.key,
                                        child: Text(
                                          entry.value,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(color: colorScheme.onSurface),
                                        ),
                                      )),
                                    ],
                                    selectedItemBuilder: (context) {
                                      return [
                                        Text(
                                          "All Goals",
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(color: colorScheme.onSurface),
                                        ),
                                        ..._goalPairs.map((entry) => Text(
                                          entry.value,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(color: colorScheme.onSurface),
                                        )),
                                      ];
                                    },
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedGoalId = value;
                                        // Clear milestone selection when goal changes
                                        // unless the selected milestone belongs to the new goal
                                        if (_selectedContext != null) {
                                          final milestoneGoalId = _milestoneToGoalMap[_selectedContext];
                                          if (milestoneGoalId != value) {
                                            _selectedContext = null;
                                          }
                                        }
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  Text("Filter by Milestone", style: textTheme.bodySmall),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    value: _selectedContext,
                                    isExpanded: true,
                                    style: TextStyle(color: colorScheme.onSurface),
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                    ),
                                    hint: Text(
                                      "All Milestones",
                                      style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6)),
                                    ),
                                    items: [
                                      DropdownMenuItem<String>(
                                        value: null,
                                        child: Text(
                                          "All Milestones",
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(color: colorScheme.onSurface),
                                        ),
                                      ),
                                      ..._filteredMilestonePairs.map((entry) => DropdownMenuItem<String>(
                                        value: entry.key,
                                        child: Text(
                                          entry.value,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(color: colorScheme.onSurface),
                                        ),
                                      )),
                                    ],
                                    selectedItemBuilder: (context) {
                                      return [
                                        Text(
                                          "All Milestones",
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(color: colorScheme.onSurface),
                                        ),
                                        ..._filteredMilestonePairs.map((entry) => Text(
                                          entry.value,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(color: colorScheme.onSurface),
                                        )),
                                      ];
                                    },
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedContext = value;
                                      });
                                    },
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
                                ] else if (widget.entity == FilterEntityType.habit) ...[
                                  // Habit filters - Cascading dropdowns: Goal first, then Milestone
                                  Text("Filter by Goal", style: textTheme.bodySmall),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    value: _selectedGoalId,
                                    isExpanded: true,
                                    style: TextStyle(color: colorScheme.onSurface),
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                    ),
                                    hint: Text(
                                      "All Goals",
                                      style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6)),
                                    ),
                                    items: [
                                      DropdownMenuItem<String>(
                                        value: null,
                                        child: Text(
                                          "All Goals",
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(color: colorScheme.onSurface),
                                        ),
                                      ),
                                      ..._goalPairs.map((entry) => DropdownMenuItem<String>(
                                        value: entry.key,
                                        child: Text(
                                          entry.value,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(color: colorScheme.onSurface),
                                        ),
                                      )),
                                    ],
                                    selectedItemBuilder: (context) {
                                      return [
                                        Text(
                                          "All Goals",
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(color: colorScheme.onSurface),
                                        ),
                                        ..._goalPairs.map((entry) => Text(
                                          entry.value,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(color: colorScheme.onSurface),
                                        )),
                                      ];
                                    },
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedGoalId = value;
                                        // Clear milestone selection when goal changes
                                        // unless the selected milestone belongs to the new goal
                                        if (_selectedContext != null) {
                                          final milestoneGoalId = _milestoneToGoalMap[_selectedContext];
                                          if (milestoneGoalId != value) {
                                            _selectedContext = null;
                                          }
                                        }
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  Text("Filter by Milestone", style: textTheme.bodySmall),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    value: _selectedContext,
                                    isExpanded: true,
                                    style: TextStyle(color: colorScheme.onSurface),
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                    ),
                                    hint: Text(
                                      "All Milestones",
                                      style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6)),
                                    ),
                                    items: [
                                      DropdownMenuItem<String>(
                                        value: null,
                                        child: Text(
                                          "All Milestones",
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(color: colorScheme.onSurface),
                                        ),
                                      ),
                                      ..._filteredMilestonePairs.map((entry) => DropdownMenuItem<String>(
                                        value: entry.key,
                                        child: Text(
                                          entry.value,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(color: colorScheme.onSurface),
                                        ),
                                      )),
                                    ],
                                    selectedItemBuilder: (context) {
                                      return [
                                        Text(
                                          "All Milestones",
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(color: colorScheme.onSurface),
                                        ),
                                        ..._filteredMilestonePairs.map((entry) => Text(
                                          entry.value,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(color: colorScheme.onSurface),
                                        )),
                                      ];
                                    },
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedContext = value;
                                      });
                                    },
                                  ),
                                ],
                                if (widget.entity == FilterEntityType.itinerary) ...[
                                  // Itinerary filters - Date range and Item type
                                  Text("Filter by Item Type", style: textTheme.bodySmall),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      for (final itemType in travel_constants.ItineraryItemType.values)
                                        ChoiceChip(
                                          label: Text(travel_constants.itineraryItemTypeLabels[itemType]!),
                                          selected: _selectedItemType == itemType.name,
                                          onSelected: (sel) {
                                            setState(() {
                                              _selectedItemType = sel ? itemType.name : null;
                                            });
                                          },
                                        ),
                                    ],
                                  ),
                                ],
                                if (widget.entity == FilterEntityType.trip) ...[
                                  // Trip filters - only date range (no completed items filter)
                                  // Date filters are already shown above for non-habit entities
                                ],
                              ],
                            ),
                          ),
                        ),

                        // Save Filter checkbox
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
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
                              const Text("Save Filter Settings"),
                            ],
                          ),
                        ),

                        // Hide completed items checkbox (excluded for itinerary and trips)
                        if (widget.entity != FilterEntityType.itinerary && widget.entity != FilterEntityType.trip)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: _hideCompleted,
                                  onChanged: (value) {
                                    setState(() {
                                      _hideCompleted = value ?? false;
                                    });
                                  },
                                ),
                                const SizedBox(width: 8),
                                const Text("Hide completed items"),
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
                                      "hideCompleted": _hideCompleted,
                                    });
                                  } else if (widget.entity == FilterEntityType.goal || widget.entity == FilterEntityType.milestone) {
                                    Navigator.of(context).pop({
                                      "context": _selectedContext,
                                      "targetDate": _selectedDateFilter,
                                      "saveFilter": _saveFilter,
                                      "hideCompleted": _hideCompleted,
                                    });
                                  } else if (widget.entity == FilterEntityType.trip) {
                                    // Trip entity — return date filter only (no completed items)
                                    Navigator.of(context).pop({
                                      "targetDate": _selectedDateFilter,
                                      "saveFilter": _saveFilter,
                                    });
                                  } else if (widget.entity == FilterEntityType.itinerary) {
                                    // Itinerary entity — return date filter and item type
                                    Navigator.of(context).pop({
                                      "targetDate": _selectedDateFilter,
                                      "itemType": _selectedItemType,
                                      "saveFilter": _saveFilter,
                                    });
                                  } else {
                                    // Habit entity — return milestone/goal only
                                    Navigator.of(context).pop({
                                      "milestoneId": _selectedContext,
                                      "goalId": _selectedGoalId,
                                      "saveFilter": _saveFilter,
                                      "hideCompleted": _hideCompleted,
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

                    if (!isHabit && !isTrip && !isItinerary)
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
                              const Text("Save Sort Settings"),
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
