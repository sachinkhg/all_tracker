// lib/presentation/widgets/filter_group_bottom_sheet.dart
import 'package:flutter/material.dart';
import '../../core/constants.dart'; // path to kContextOptions

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
    _selectedContext = widget.initialContext;
    _selectedDateFilter = widget.initialDateFilter;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final maxHeight = MediaQuery.of(context).size.height * 0.40;
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
