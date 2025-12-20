import 'package:flutter/material.dart';
import '../../domain/entities/book_status.dart';

class BookFilter {
  final BookStatus? status;
  final String? author;
  final int? publishedYear;
  final int? readYear;

  const BookFilter({
    this.status,
    this.author,
    this.publishedYear,
    this.readYear,
  });

  bool get hasFilters =>
      status != null || author != null || publishedYear != null || readYear != null;

  BookFilter copyWith({
    BookStatus? status,
    String? author,
    int? publishedYear,
    int? readYear,
  }) {
    return BookFilter(
      status: status ?? this.status,
      author: author ?? this.author,
      publishedYear: publishedYear ?? this.publishedYear,
      readYear: readYear ?? this.readYear,
    );
  }
}

class BookFilterBottomSheet extends StatefulWidget {
  final BookFilter initialFilter;
  final Function(BookFilter) onApply;

  const BookFilterBottomSheet({
    super.key,
    required this.initialFilter,
    required this.onApply,
  });

  static Future<void> show(
    BuildContext context, {
    required BookFilter initialFilter,
    required Function(BookFilter) onApply,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return BookFilterBottomSheet(
          initialFilter: initialFilter,
          onApply: onApply,
        );
      },
    );
  }

  @override
  State<BookFilterBottomSheet> createState() => _BookFilterBottomSheetState();
}

class _BookFilterBottomSheetState extends State<BookFilterBottomSheet> {
  late BookFilter _filter;
  final _authorController = TextEditingController();
  final _publishedYearController = TextEditingController();
  final _readYearController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Default readYear to current year if not set
    final currentYear = DateTime.now().year;
    final readYear = widget.initialFilter.readYear ?? currentYear;
    _filter = widget.initialFilter.copyWith(readYear: readYear);
    _authorController.text = _filter.author ?? '';
    _publishedYearController.text =
        _filter.publishedYear?.toString() ?? '';
    _readYearController.text = readYear.toString();
  }

  @override
  void dispose() {
    _authorController.dispose();
    _publishedYearController.dispose();
    _readYearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        top: 16.0,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16.0,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filter Books',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Status filter
          DropdownButtonFormField<BookStatus?>(
            value: _filter.status,
            decoration: const InputDecoration(
              labelText: 'Status',
            ),
            items: [
              const DropdownMenuItem<BookStatus?>(
                value: null,
                child: Text('All'),
              ),
              ...BookStatus.values.map((status) {
                return DropdownMenuItem<BookStatus?>(
                  value: status,
                  child: Text(status.displayName),
                );
              }),
            ],
            onChanged: (value) {
              setState(() {
                _filter = _filter.copyWith(status: value);
              });
            },
          ),
          const SizedBox(height: 16),
          // Author filter
          TextFormField(
            controller: _authorController,
            decoration: const InputDecoration(
              labelText: 'Author',
              hintText: 'Filter by author name',
            ),
            onChanged: (value) {
              _filter = _filter.copyWith(
                author: value.trim().isEmpty ? null : value.trim(),
              );
            },
          ),
          const SizedBox(height: 16),
          // Published year filter
          TextFormField(
            controller: _publishedYearController,
            decoration: const InputDecoration(
              labelText: 'Published Year',
              hintText: 'e.g., 2020',
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              final year = int.tryParse(value.trim());
              _filter = _filter.copyWith(
                publishedYear: year,
              );
            },
          ),
          const SizedBox(height: 16),
          // Read year filter
          TextFormField(
            controller: _readYearController,
            decoration: const InputDecoration(
              labelText: 'Read Year',
              hintText: 'e.g., 2024',
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              final year = int.tryParse(value.trim());
              _filter = _filter.copyWith(
                readYear: year,
              );
            },
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    final currentYear = DateTime.now().year;
                    setState(() {
                      _filter = BookFilter(readYear: currentYear);
                      _authorController.clear();
                      _publishedYearController.clear();
                      _readYearController.text = currentYear.toString();
                    });
                  },
                  child: const Text('Clear'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    widget.onApply(_filter);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
          ],
        ),
      ),
    );
  }
}

