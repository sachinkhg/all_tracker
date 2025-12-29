import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/book.dart';
import '../../domain/entities/read_history_entry.dart';
import '../../domain/entities/book_search_result.dart';
import '../../domain/usecases/book/search_books.dart';
import '../../core/injection.dart';

class BookFormBottomSheet extends StatefulWidget {
  final Book? book;
  final Future<void> Function({
    required String title,
    required String primaryAuthor,
    required int pageCount,
    double? selfRating,
    DateTime? datePublished,
    DateTime? dateStarted,
    DateTime? dateRead,
    List<ReadHistoryEntry>? readHistory,
  }) onSubmit;
  final Future<void> Function()? onDelete;
  final Future<Book?> Function()? onReRead;
  final Future<Book?> Function(int index)? onRemoveHistoryEntry;
  final String title;

  const BookFormBottomSheet({
    super.key,
    this.book,
    required this.onSubmit,
    this.onDelete,
    this.onReRead,
    this.onRemoveHistoryEntry,
    required this.title,
  });

  static Future<void> show(
    BuildContext context, {
    Book? book,
    required Future<void> Function({
      required String title,
      required String primaryAuthor,
      required int pageCount,
      double? selfRating,
      DateTime? datePublished,
      DateTime? dateStarted,
      DateTime? dateRead,
      List<ReadHistoryEntry>? readHistory,
    }) onSubmit,
    Future<void> Function()? onDelete,
    Future<Book?> Function()? onReRead,
    Future<Book?> Function(int index)? onRemoveHistoryEntry,
    String title = 'Create Book',
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return BookFormBottomSheet(
          book: book,
          onSubmit: onSubmit,
          onDelete: onDelete,
          onReRead: onReRead,
          onRemoveHistoryEntry: onRemoveHistoryEntry,
          title: title,
        );
      },
    );
  }

  @override
  State<BookFormBottomSheet> createState() => _BookFormBottomSheetState();
}

class _BookFormBottomSheetState extends State<BookFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _authorController;
  late final TextEditingController _pageCountController;
  late final TextEditingController _selfRatingController;
  DateTime? _datePublished;
  DateTime? _dateStarted;
  DateTime? _dateRead;
  Book? _currentBook; // Track current book state for read history display
  int? _selectedHistoryIndex; // Track which read history entry is being edited
  bool _showDateFields = false; // Track if Date Started/Read fields should be visible
  bool _isSearching = false; // Track if search is in progress
  late final SearchBooks _searchBooksUseCase; // Use case for searching books

  @override
  void initState() {
    super.initState();
    _currentBook = widget.book;
    _searchBooksUseCase = createSearchBooksUseCase();
    _titleController = TextEditingController(
      text: widget.book?.title ?? '',
    );
    _authorController = TextEditingController(
      text: widget.book?.primaryAuthor ?? '',
    );
    _pageCountController = TextEditingController(
      text: widget.book?.pageCount.toString() ?? '',
    );
    _selfRatingController = TextEditingController(
      text: widget.book?.selfRating?.toString() ?? '',
    );
    _datePublished = widget.book?.datePublished;
    // Keep Date Started and Date Read empty for edit mode to allow selecting from history
    _dateStarted = null;
    _dateRead = null;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _pageCountController.dispose();
    _selfRatingController.dispose();
    super.dispose();
  }

  /// Searches for books using the Open Library API.
  Future<void> _searchBooks() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a book title to search'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await _searchBooksUseCase(title);

      if (!mounted) return;

      setState(() {
        _isSearching = false;
      });

      if (results.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No books found. Please try a different title or enter details manually.'),
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      // If only one result, auto-fill directly
      if (results.length == 1) {
        _fillBookData(results.first);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Book details filled automatically'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        // Show dialog with multiple results
        _showSearchResultsDialog(results);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSearching = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error searching for books: $e'),
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Shows a dialog with search results for user to select from.
  void _showSearchResultsDialog(List<BookSearchResult> results) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select a Book'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: results.length,
            itemBuilder: (context, index) {
              final result = results[index];
              return ListTile(
                title: Text(result.title),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (result.authors.isNotEmpty)
                      Text('Author: ${result.authors.join(", ")}'),
                    if (result.pageCount != null)
                      Text('Pages: ${result.pageCount}'),
                    if (result.datePublished != null)
                      Text('Published: ${DateFormat('yyyy').format(result.datePublished!)}'),
                  ],
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _fillBookData(result);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  /// Fills the form fields with data from a search result.
  void _fillBookData(BookSearchResult result) {
    setState(() {
      // Fill title
      if (result.title.isNotEmpty) {
        _titleController.text = result.title;
      }

      // Fill author (use first author as primary)
      if (result.primaryAuthor != null) {
        _authorController.text = result.primaryAuthor!;
      }

      // Fill page count
      if (result.pageCount != null && result.pageCount! > 0) {
        _pageCountController.text = result.pageCount.toString();
      }

      // Fill publication date
      if (result.datePublished != null) {
        _datePublished = result.datePublished;
      }
    });
  }

  Future<void> _selectDate(
    BuildContext context,
    Function(DateTime?) onDateSelected,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        onDateSelected(picked);
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      final pageCount = int.parse(_pageCountController.text.trim());
      final selfRatingText = _selfRatingController.text.trim();
      final selfRating = selfRatingText.isEmpty
          ? null
          : double.tryParse(selfRatingText);

      // If editing a read history entry, update that specific entry
      // If editing the current read (_selectedHistoryIndex == -1), update active dates
      List<ReadHistoryEntry>? updatedReadHistory = _currentBook?.readHistory;
      if (_currentBook != null && 
          _selectedHistoryIndex != null && 
          _selectedHistoryIndex! >= 0 && 
          _selectedHistoryIndex! < _currentBook!.readHistory.length) {
        // Update the selected history entry with new dates
        final updatedHistory = List<ReadHistoryEntry>.from(_currentBook!.readHistory);
        updatedHistory[_selectedHistoryIndex!] = ReadHistoryEntry(
          dateStarted: _dateStarted,
          dateRead: _dateRead,
        );
        updatedReadHistory = updatedHistory;
        // Clear the active dates since we're updating a history entry
        // (active dates should remain null when editing history)
      }
      // If _selectedHistoryIndex == -1, we're editing the current read, so update active dates normally

      await widget.onSubmit(
        title: _titleController.text.trim(),
        primaryAuthor: _authorController.text.trim(),
        pageCount: pageCount,
        selfRating: selfRating,
        datePublished: _datePublished,
        dateStarted: (_selectedHistoryIndex != null && _selectedHistoryIndex! >= 0) ? null : _dateStarted,
        dateRead: (_selectedHistoryIndex != null && _selectedHistoryIndex! >= 0) ? null : _dateRead,
        readHistory: updatedReadHistory,
      );
      
      // Reset state after submit
      setState(() {
        _showDateFields = false;
        _selectedHistoryIndex = null;
        _dateStarted = null;
        _dateRead = null;
      });
      
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (widget.onDelete != null)
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          await widget.onDelete!();
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                // Title field with search button
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          hintText: 'Enter book title',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: _isSearching
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.search),
                      tooltip: 'Search for book details',
                      onPressed: _isSearching ? null : _searchBooks,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Author field
                TextFormField(
                  controller: _authorController,
                  decoration: const InputDecoration(
                    labelText: 'Primary Author',
                    hintText: 'Enter author name',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter an author';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Page count field
                TextFormField(
                  controller: _pageCountController,
                  decoration: const InputDecoration(
                    labelText: 'Page Count',
                    hintText: '0',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter page count';
                    }
                    final pageCount = int.tryParse(value.trim());
                    if (pageCount == null || pageCount <= 0) {
                      return 'Please enter a valid positive number';
                    }
                    return null;
                  },
                ),
                // Self Rating field - only show in edit mode if book has been read at least once
                if (widget.book != null && 
                    _currentBook != null && 
                    (_currentBook!.dateRead != null || 
                     _currentBook!.readHistory.any((entry) => entry.isCompleted))) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _selfRatingController,
                    decoration: const InputDecoration(
                      labelText: 'Self Rating (0-5)',
                      hintText: 'Optional',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value != null && value.trim().isNotEmpty) {
                        final selfRating = double.tryParse(value.trim());
                        if (selfRating == null || selfRating < 0 || selfRating > 5) {
                          return 'Self Rating must be between 0 and 5';
                        }
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 16),
                // Read History Section (always show when editing a book)
                if (_currentBook != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Read History',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        tooltip: 'Add new read',
                        onPressed: () {
                          setState(() {
                            _showDateFields = true;
                            _selectedHistoryIndex = null; // Clear selection when adding new
                            _dateStarted = null;
                            _dateRead = null;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...() {
                    // Combine current read with history for display
                    final allReads = <Map<String, dynamic>>[];
                    
                    // Add current read if it exists (treat as the latest read)
                    if (_currentBook!.dateStarted != null || _currentBook!.dateRead != null) {
                      allReads.add({
                        'entry': ReadHistoryEntry(
                          dateStarted: _currentBook!.dateStarted,
                          dateRead: _currentBook!.dateRead,
                        ),
                        'isCurrentRead': true,
                        'historyIndex': null,
                      });
                    }
                    
                    // Add all history entries with their original indices
                    for (int i = 0; i < _currentBook!.readHistory.length; i++) {
                      allReads.add({
                        'entry': _currentBook!.readHistory[i],
                        'isCurrentRead': false,
                        'historyIndex': i,
                      });
                    }
                    
                    // Sort by Date Read (most recent first), then by Date Started
                    allReads.sort((a, b) {
                      final entryA = a['entry'] as ReadHistoryEntry;
                      final entryB = b['entry'] as ReadHistoryEntry;
                      final dateReadA = entryA.dateRead;
                      final dateReadB = entryB.dateRead;
                      
                      if (dateReadA == null && dateReadB == null) {
                        // Both null, sort by Date Started
                        final dateStartedA = entryA.dateStarted;
                        final dateStartedB = entryB.dateStarted;
                        if (dateStartedA == null && dateStartedB == null) return 0;
                        if (dateStartedA == null) return 1;
                        if (dateStartedB == null) return -1;
                        return dateStartedB.compareTo(dateStartedA); // Most recent first
                      }
                      if (dateReadA == null) return 1; // Null dates go to end
                      if (dateReadB == null) return -1;
                      return dateReadB.compareTo(dateReadA); // Most recent first
                    });
                    
                    // Map to widgets
                    return allReads.asMap().entries.map((mapEntry) {
                      final displayIndex = mapEntry.key; // Display index (1, 2, 3...)
                      final readData = mapEntry.value;
                      final historyEntry = readData['entry'] as ReadHistoryEntry;
                      final isCurrentRead = readData['isCurrentRead'] as bool;
                      final historyIndex = readData['historyIndex'] as int?;
                      // Use -1 for current read, actual history index for history entries
                      final originalIndex = isCurrentRead ? -1 : historyIndex!;
                      final isSelected = _selectedHistoryIndex == originalIndex;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      color: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedHistoryIndex = originalIndex;
                            _dateStarted = historyEntry.dateStarted;
                            _dateRead = historyEntry.dateRead;
                            _showDateFields = true; // Show date fields when editing
                          });
                        },
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text('${displayIndex + 1}'),
                          ),
                          title: Text('Read ${displayIndex + 1}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (historyEntry.dateStarted != null)
                                Text(
                                  'Started: ${dateFormat.format(historyEntry.dateStarted!)}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              if (historyEntry.dateRead != null)
                                Text(
                                  'Completed: ${dateFormat.format(historyEntry.dateRead!)}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                            ],
                          ),
                          trailing: widget.onRemoveHistoryEntry != null && !isCurrentRead
                              ? IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () async {
                                    final updatedBook = await widget.onRemoveHistoryEntry!(originalIndex);
                                    if (updatedBook != null && mounted) {
                                      setState(() {
                                        _currentBook = updatedBook;
                                        // Clear selection if the deleted entry was selected
                                        if (_selectedHistoryIndex == originalIndex) {
                                          _selectedHistoryIndex = null;
                                          _dateStarted = null;
                                          _dateRead = null;
                                        } else if (_selectedHistoryIndex != null && _selectedHistoryIndex! > originalIndex) {
                                          // Adjust index if a previous entry was deleted
                                          _selectedHistoryIndex = _selectedHistoryIndex! - 1;
                                        }
                                      });
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Read history entry removed'),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  },
                                  tooltip: 'Delete this read',
                                )
                              : null,
                        ),
                      ),
                    );
                    }).toList();
                  }(),
                  const SizedBox(height: 16),
                ],
                // Date published picker
                InkWell(
                  onTap: () => _selectDate(context, (date) {
                    _datePublished = date;
                  }),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date Published',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      _datePublished != null
                          ? dateFormat.format(_datePublished!)
                          : 'Not set',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Date Started and Date Read fields (shown when adding/editing)
                if (_showDateFields) ...[
                  // Date started picker
                  InkWell(
                    onTap: () => _selectDate(context, (date) {
                      _dateStarted = date;
                      // If dateRead exists and is before dateStarted, clear it
                      if (_dateRead != null && _dateRead!.isBefore(date!)) {
                        setState(() {
                          _dateRead = null;
                        });
                      }
                    }),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date Started',
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        _dateStarted != null
                            ? dateFormat.format(_dateStarted!)
                            : 'Not set',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Date read picker
                  InkWell(
                    onTap: () => _selectDate(context, (date) {
                      // Validate: dateRead must be >= dateStarted
                      if (_dateStarted != null && date != null && date.isBefore(_dateStarted!)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Date read cannot be earlier than date started'),
                          ),
                        );
                        return;
                      }
                      setState(() {
                        _dateRead = date;
                      });
                    }),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date Read',
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        _dateRead != null
                            ? dateFormat.format(_dateRead!)
                            : 'Not set',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Reread button (only for completed books or when dates are set)
                  if (widget.onReRead != null && _currentBook != null && 
                      (_dateStarted != null || _dateRead != null))
                    OutlinedButton.icon(
                      onPressed: () async {
                        // Archive the dates currently in the form fields
                        if (_dateStarted != null || _dateRead != null) {
                          final historyEntry = ReadHistoryEntry(
                            dateStarted: _dateStarted,
                            dateRead: _dateRead,
                          );
                          final updatedHistory = [...(_currentBook!.readHistory), historyEntry];
                          
                          setState(() {
                            _currentBook = _currentBook!.copyWith(
                              readHistory: updatedHistory,
                            );
                            _dateStarted = null;
                            _dateRead = null;
                            _selectedHistoryIndex = null;
                            _showDateFields = false; // Hide fields after archiving
                          });
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Read archived. You can now start a new reading cycle.'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reread'),
                    ),
                  const SizedBox(height: 16),
                ],
                // Submit button
                ElevatedButton(
                  onPressed: _handleSubmit,
                  child: Text(widget.book == null ? 'Create' : 'Update'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

