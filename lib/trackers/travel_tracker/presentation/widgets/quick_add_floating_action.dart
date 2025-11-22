import 'package:flutter/material.dart';
import '../../core/app_icons.dart';

/// Floating action button with quick add menu for travel tracker.
class QuickAddFloatingAction extends StatelessWidget {
  final VoidCallback? onAddPhoto;
  final VoidCallback? onAddNote;
  final VoidCallback? onAddActivity;
  final VoidCallback? onAddExpense;

  const QuickAddFloatingAction({
    super.key,
    this.onAddPhoto,
    this.onAddNote,
    this.onAddActivity,
    this.onAddExpense,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'quickAddFab',
      tooltip: 'Quick Add',
      backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.85),
      onPressed: () => _showQuickAddMenu(context),
      child: const Icon(Icons.add),
    );
  }

  void _showQuickAddMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Quick Add',
              style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),
            if (onAddPhoto != null)
              ListTile(
                leading: Icon(TravelTrackerIcons.photo, color: Theme.of(ctx).colorScheme.primary),
                title: const Text('Photo'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  onAddPhoto?.call();
                },
              ),
            if (onAddNote != null)
              ListTile(
                leading: Icon(TravelTrackerIcons.journal, color: Theme.of(ctx).colorScheme.primary),
                title: const Text('Journal Entry'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  onAddNote?.call();
                },
              ),
            if (onAddActivity != null)
              ListTile(
                leading: Icon(TravelTrackerIcons.itinerary, color: Theme.of(ctx).colorScheme.primary),
                title: const Text('Activity'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  onAddActivity?.call();
                },
              ),
            if (onAddExpense != null)
              ListTile(
                leading: Icon(TravelTrackerIcons.expense, color: Theme.of(ctx).colorScheme.primary),
                title: const Text('Expense'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  onAddExpense?.call();
                },
              ),
          ],
        ),
      ),
    );
  }
}

