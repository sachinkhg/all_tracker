import 'package:flutter/material.dart';

/// A bottom sheet that lets the user choose which fields
/// are visible in the Goal list view.
///
/// By default, Name and Description are ON.
/// Others (Target Date, Context, Remaining Days) are OFF.
class ViewFieldsBottomSheet extends StatefulWidget {
  final Map<String, bool>? initial;

  const ViewFieldsBottomSheet({Key? key, this.initial}) : super(key: key);

  @override
  State<ViewFieldsBottomSheet> createState() => _ViewFieldsBottomSheetState();
}

class _ViewFieldsBottomSheetState extends State<ViewFieldsBottomSheet> {
  late Map<String, bool> _fields;

  @override
  void initState() {
    super.initState();
    _fields = {
      'name': widget.initial?['name'] ?? true,
      'description': widget.initial?['description'] ?? true,
      'targetDate': widget.initial?['targetDate'] ?? false,
      'context': widget.initial?['context'] ?? false,
      'remainingDays': widget.initial?['remainingDays'] ?? false,
    };
  }

  Widget _buildToggle(String key, String label) {
    return SwitchListTile(
      title: Text(label),
      value: _fields[key] ?? false,
      onChanged: (val) {
        setState(() => _fields[key] = val);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Visible Fields',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _buildToggle('name', 'Name'),
            _buildToggle('description', 'Description'),
            _buildToggle('targetDate', 'Target Date'),
            _buildToggle('context', 'Context'),
            _buildToggle('remainingDays', 'Remaining Days'),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  child: const Text('CANCEL'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  child: const Text('APPLY'),
                  onPressed: () => Navigator.of(context).pop(_fields),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
