import 'package:flutter/material.dart';
import '../../domain/entities/trip_profile.dart';
import '../../domain/usecases/profile/create_profile.dart';
import '../../domain/usecases/profile/get_profile_by_trip_id.dart';
import '../../domain/usecases/profile/update_profile.dart';
import '../../core/injection.dart';
import 'package:uuid/uuid.dart';

/// Bottom sheet for setting up trip profile.
class ProfileSetupBottomSheet {
  static Future<void> show(
    BuildContext context, {
    required String tripId,
  }) async {
    final profileRepo = createTripProfileRepository();
    final getProfile = GetProfileByTripId(profileRepo);
    final createProfile = CreateProfile(profileRepo);
    final updateProfile = UpdateProfile(profileRepo);

    final existingProfile = await getProfile(tripId);

    final nameCtrl = TextEditingController(
      text: existingProfile?.travelerName ?? '',
    );
    final emailCtrl = TextEditingController(
      text: existingProfile?.email ?? '',
    );
    final notesCtrl = TextEditingController(
      text: existingProfile?.notes ?? '',
    );

    final uuid = const Uuid();

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
              Text(
                'Trip Profile',
                style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Traveler Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  final now = DateTime.now();
                  if (existingProfile != null) {
                    final updated = TripProfile(
                      id: existingProfile.id,
                      tripId: existingProfile.tripId,
                      travelerName: nameCtrl.text.trim().isEmpty
                          ? null
                          : nameCtrl.text.trim(),
                      email: emailCtrl.text.trim().isEmpty
                          ? null
                          : emailCtrl.text.trim(),
                      notes: notesCtrl.text.trim().isEmpty
                          ? null
                          : notesCtrl.text.trim(),
                      createdAt: existingProfile.createdAt,
                      updatedAt: now,
                    );
                    await updateProfile(updated);
                  } else {
                    final profile = TripProfile(
                      id: uuid.v4(),
                      tripId: tripId,
                      travelerName: nameCtrl.text.trim().isEmpty
                          ? null
                          : nameCtrl.text.trim(),
                      email: emailCtrl.text.trim().isEmpty
                          ? null
                          : emailCtrl.text.trim(),
                      notes: notesCtrl.text.trim().isEmpty
                          ? null
                          : notesCtrl.text.trim(),
                      createdAt: now,
                      updatedAt: now,
                    );
                    await createProfile(profile);
                  }
                  if (ctx.mounted) {
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Profile saved')),
                    );
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

