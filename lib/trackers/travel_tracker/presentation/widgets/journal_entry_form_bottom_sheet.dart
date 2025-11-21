import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../bloc/photo_cubit.dart';
import '../bloc/photo_state.dart';
import '../../core/injection.dart';

/// Bottom sheet for creating/editing journal entries.
class JournalEntryFormBottomSheet {

  static Future<void> show(
    BuildContext context, {
    required String tripId,
    DateTime? initialDate,
    String? initialContent,
    String? entryId,
    required Future<String?> Function(DateTime date, String content) onSubmit,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => BlocProvider(
        create: (_) {
          final photoCubit = createPhotoCubit();
          if (entryId != null) {
            photoCubit.loadPhotos(entryId);
          }
          return photoCubit;
        },
        child: _JournalEntryFormContent(
          tripId: tripId,
          initialDate: initialDate,
          initialContent: initialContent,
          entryId: entryId,
          onSubmit: onSubmit,
        ),
      ),
    );
  }
}

class _JournalEntryFormContent extends StatefulWidget {
  final String tripId;
  final DateTime? initialDate;
  final String? initialContent;
  final String? entryId;
  final Future<String?> Function(DateTime date, String content) onSubmit;

  const _JournalEntryFormContent({
    required this.tripId,
    this.initialDate,
    this.initialContent,
    this.entryId,
    required this.onSubmit,
  });

  @override
  State<_JournalEntryFormContent> createState() => _JournalEntryFormContentState();
}

class _JournalEntryFormContentState extends State<_JournalEntryFormContent> {
  late TextEditingController _contentCtrl;
  late DateTime _selectedDate;
  String? _currentEntryId;
  bool _isCreating = false;
  final List<String> _pendingPhotos = []; // Store photos selected before entry creation

  @override
  void initState() {
    super.initState();
    _contentCtrl = TextEditingController(text: widget.initialContent ?? '');
    _selectedDate = widget.initialDate ?? DateTime.now();
    _currentEntryId = widget.entryId;
  }

  @override
  void dispose() {
    _contentCtrl.dispose();
    super.dispose();
  }

  String formatDate(DateTime d) => DateFormat('MMM dd, yyyy').format(d);

  Future<void> _pickImage(ImageSource source) async {
    final photoCubit = context.read<PhotoCubit>();
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    
    if (pickedFile != null && mounted) {
      final entryId = widget.entryId ?? _currentEntryId;
      if (entryId != null) {
        // Entry exists, add photo immediately
        await photoCubit.addPhotoFromPath(
          entryId: entryId,
          sourcePath: pickedFile.path,
          dateTaken: DateTime.now(),
        );
      } else {
        // Entry doesn't exist yet - store photo path temporarily
        setState(() {
          _pendingPhotos.add(pickedFile.path);
        });
      }
    }
  }

  Future<void> _showImageSourceDialog() async {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    if (_contentCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Content is required')),
      );
      return;
    }

    setState(() {
      _isCreating = true;
    });

    final entryId = await widget.onSubmit(_selectedDate, _contentCtrl.text.trim());
    
    if (mounted && entryId != null) {
      final photoCubit = context.read<PhotoCubit>();
      
      // If this was a new entry and we have pending photos, add them now
      if (_currentEntryId == null && _pendingPhotos.isNotEmpty) {
        _currentEntryId = entryId;
        // Load photos first to initialize the state
        await photoCubit.loadPhotos(entryId);
        
        // Add all pending photos
        for (final photoPath in _pendingPhotos) {
          await photoCubit.addPhotoFromPath(
            entryId: entryId,
            sourcePath: photoPath,
            dateTaken: DateTime.now(),
          );
        }
        _pendingPhotos.clear();
      } else if (_currentEntryId == null) {
        _currentEntryId = entryId;
        await photoCubit.loadPhotos(entryId);
      } else if (_pendingPhotos.isNotEmpty) {
        // Editing existing entry with new photos
        for (final photoPath in _pendingPhotos) {
          await photoCubit.addPhotoFromPath(
            entryId: entryId,
            sourcePath: photoPath,
            dateTaken: DateTime.now(),
          );
        }
        _pendingPhotos.clear();
      }
      
      setState(() {
        _isCreating = false;
      });
      
      // Close the form after saving
      Navigator.of(context).pop();
    } else if (mounted) {
      setState(() {
        _isCreating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
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
                  _currentEntryId == null ? 'New Journal Entry' : 'Edit Journal Entry',
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (date != null) {
                  setState(() {
                    _selectedDate = date;
                  });
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date',
                  border: OutlineInputBorder(),
                ),
                child: Text(formatDate(_selectedDate)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentCtrl,
              decoration: const InputDecoration(
                labelText: 'Content *',
                border: OutlineInputBorder(),
              ),
              maxLines: 10,
            ),
            const SizedBox(height: 16),
            // Media section - always visible
            BlocBuilder<PhotoCubit, PhotoState>(
              builder: (context, photoState) {
                final entryId = widget.entryId ?? _currentEntryId;
                final hasExistingEntry = entryId != null;
                
                // Combine existing photos with pending photos
                List<String> allPhotoPaths = List.from(_pendingPhotos);
                
                if (hasExistingEntry && photoState is PhotosLoaded) {
                  // For existing entries, show saved photos
                  allPhotoPaths = photoState.photos.map((p) => p.filePath).toList();
                } else if (hasExistingEntry && photoState is PhotosLoading) {
                  return const SizedBox(
                    height: 100,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Media',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.add_photo_alternate),
                          onPressed: _showImageSourceDialog,
                          tooltip: 'Add Photo',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (allPhotoPaths.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            'No media added',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: allPhotoPaths.length,
                          itemBuilder: (context, index) {
                            final photoPath = allPhotoPaths[index];
                            final isPending = _pendingPhotos.contains(photoPath);
                            
                            return Container(
                              width: 100,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                                ),
                              ),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      File(photoPath),
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          color: Colors.grey[300],
                                          child: const Icon(Icons.broken_image),
                                        );
                                      },
                                    ),
                                  ),
                                  if (isPending)
                                    // Pending indicator
                                    Positioned(
                                      top: 4,
                                      left: 4,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.orange,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'Pending',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () {
                                          if (isPending) {
                                            // Remove from pending list
                                            setState(() {
                                              _pendingPhotos.remove(photoPath);
                                            });
                                          } else if (hasExistingEntry && photoState is PhotosLoaded) {
                                            // Delete saved photo
                                            // entryId is guaranteed non-null when hasExistingEntry is true
                                            final photo = photoState.photos.firstWhere(
                                              (p) => p.filePath == photoPath,
                                            );
                                            // Flow analysis ensures entryId is non-null when hasExistingEntry is true
                                            context.read<PhotoCubit>().deletePhotoById(
                                              photo.id,
                                              entryId,
                                            );
                                          }
                                        },
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: Colors.black54,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isCreating ? null : _handleSave,
              child: _isCreating
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_currentEntryId == null ? 'Save' : 'Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}

