import 'package:flutter/material.dart';

/// Bottom sheet for creating/editing a traveler.
class TravelerFormBottomSheet {
  static Future<void> show(
    BuildContext context, {
    required String tripId,
    String? initialName,
    String? initialRelationship,
    String? initialEmail,
    String? initialPhone,
    String? initialNotes,
    bool initialIsMainTraveler = false,
    String? travelerId,
    bool hasMainTraveler = false, // Whether a main traveler already exists
    required Future<void> Function(
      String name,
      String? relationship,
      String? email,
      String? phone,
      String? notes,
      bool isMainTraveler,
    ) onSubmit,
    Future<void> Function()? onDelete,
    String title = 'Add Traveler',
  }) {
    final nameCtrl = TextEditingController(text: initialName ?? '');
    final relationshipCtrl = TextEditingController(text: initialRelationship ?? '');
    final emailCtrl = TextEditingController(text: initialEmail ?? '');
    final phoneCtrl = TextEditingController(text: initialPhone ?? '');
    final notesCtrl = TextEditingController(text: initialNotes ?? '');
    bool isMainTraveler = initialIsMainTraveler;

    final cs = Theme.of(context).colorScheme;

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      color: cs.error,
                      onPressed: () async {
                        await onDelete();
                        if (ctx.mounted) {
                          Navigator.of(ctx).pop();
                        }
                      },
                    ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Name *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: relationshipCtrl,
                decoration: const InputDecoration(
                  labelText: 'Relationship (e.g., Self, Spouse, Child, Friend)',
                  hintText: 'Optional',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'Optional',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  hintText: 'Optional',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  hintText: 'Optional',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              // Only show Main Traveler checkbox if:
              // 1. No main traveler exists yet, OR
              // 2. We're editing the existing main traveler (travelerId is set and initialIsMainTraveler is true)
              if (!hasMainTraveler || (travelerId != null && initialIsMainTraveler)) ...[
                CheckboxListTile(
                  title: const Text('Main Traveler (Self)'),
                  subtitle: const Text('Mark this traveler as the main traveler'),
                  value: isMainTraveler,
                  onChanged: (value) {
                    isMainTraveler = value ?? false;
                    (ctx as Element).markNeedsBuild();
                  },
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Name is required')),
                    );
                    return;
                  }
                  // Ensure isMainTraveler is false if main traveler already exists and we're not editing it
                  final finalIsMainTraveler = (hasMainTraveler && (travelerId == null || !initialIsMainTraveler))
                      ? false
                      : isMainTraveler;
                  
                  await onSubmit(
                    nameCtrl.text.trim(),
                    relationshipCtrl.text.trim().isEmpty ? null : relationshipCtrl.text.trim(),
                    emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
                    phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                    notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                    finalIsMainTraveler,
                  );
                  if (ctx.mounted) {
                    Navigator.of(ctx).pop();
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

