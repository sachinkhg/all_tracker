import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/expense_group.dart';
import '../../../../widgets/bottom_sheet_helpers.dart';

/// Filter bottom sheet for expense dashboard
/// Allows users to filter by date range and expense group
class ExpenseFilterBottomSheet extends StatefulWidget {
  final ExpenseGroup? initialGroup;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;

  const ExpenseFilterBottomSheet({
    super.key,
    this.initialGroup,
    this.initialStartDate,
    this.initialEndDate,
  });

  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    ExpenseGroup? initialGroup,
    DateTime? initialStartDate,
    DateTime? initialEndDate,
  }) async {
    return showAppBottomSheet<Map<String, dynamic>>(
      context,
      ExpenseFilterBottomSheet(
        initialGroup: initialGroup,
        initialStartDate: initialStartDate,
        initialEndDate: initialEndDate,
      ),
    );
  }

  @override
  State<ExpenseFilterBottomSheet> createState() => _ExpenseFilterBottomSheetState();
}

class _ExpenseFilterBottomSheetState extends State<ExpenseFilterBottomSheet> {
  ExpenseGroup? _selectedGroup;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _selectedGroup = widget.initialGroup;
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final maxHeight = MediaQuery.of(context).size.height * 0.7;
    final dateFormat = DateFormat('MMM dd, yyyy');

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Filter Expenses',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Date Range Section
                  Text(
                    'Date Range',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _selectDateRange(context),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: colorScheme.outline.withOpacity(0.5),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.date_range,
                            color: colorScheme.onSurface,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _startDate != null && _endDate != null
                                      ? '${dateFormat.format(_startDate!)} - ${dateFormat.format(_endDate!)}'
                                      : 'All dates (tap to select range)',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: _startDate != null && _endDate != null
                                        ? colorScheme.onSurface
                                        : colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_startDate != null && _endDate != null)
                            IconButton(
                              icon: Icon(
                                Icons.clear,
                                size: 20,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              onPressed: () {
                                setState(() {
                                  _startDate = null;
                                  _endDate = null;
                                });
                              },
                              tooltip: 'Clear date range',
                            ),
                          Icon(
                            Icons.chevron_right,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Group Filter Section
                  Text(
                    'Filter by Group',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final group in ExpenseGroup.values)
                        ChoiceChip(
                          label: Text(group.displayName),
                          selected: _selectedGroup == group,
                          onSelected: (sel) {
                            setState(() {
                              _selectedGroup = sel ? group : null;
                            });
                          },
                        ),
                    ],
                  ),
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
                      "group": _selectedGroup?.name,
                      "startDate": _startDate?.millisecondsSinceEpoch,
                      "endDate": _endDate?.millisecondsSinceEpoch,
                    });
                  },
                  child: const Text("Apply Filter"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

