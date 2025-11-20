import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../bloc/photo_cubit.dart';
import '../bloc/photo_state.dart';
import '../../core/injection.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Bottom sheet for creating/editing journal entries with photo support.
class JournalEntryFormBottomSheet {
  static Future<void> show(
    BuildContext context, {
    required String tripId,
    DateTime? initialDate,
    String? initialContent,
    String? entryId,
    required Future<void> Function(DateTime date, String content) onSubmit,
  }) {
    final contentCtrl = TextEditingController(text: initialContent ?? '');
    DateTime selectedDate = initialDate ?? DateTime.now();

    String formatDate(DateTime d) => DateFormat('MMM dd, yyyy').format(d);

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => BlocProvider(
        create: (_) => createPhotoCubit(),
        child: Padding(
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
                  'Journal Entry',
                  style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 24),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      selectedDate = date;
                      (ctx as Element).markNeedsBuild();
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(formatDate(selectedDate)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: contentCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Content *',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 10,
                ),
                const SizedBox(height: 16),
                if (entryId != null)
                  BlocBuilder<PhotoCubit, PhotoState>(
                    builder: (context, photoState) {
                      if (photoState is PhotosLoaded) {
                        return Text(
                          '${photoState.photos.length} photos',
                          style: Theme.of(ctx).textTheme.bodySmall,
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                if (entryId != null)
                  ElevatedButton.icon(
                    onPressed: () => _pickPhoto(ctx, entryId),
                    icon: const Icon(Icons.add_photo_alternate),
                    label: const Text('Add Photo'),
                  ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    if (contentCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Content is required')),
                      );
                      return;
                    }
                    await onSubmit(selectedDate, contentCtrl.text.trim());
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
      ),
    );
  }

  static Future<void> _pickPhoto(BuildContext context, String entryId) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final cubit = context.read<PhotoCubit>();
      await cubit.addPhotoFromPath(
        entryId: entryId,
        sourcePath: image.path,
      );
    }
  }
}

