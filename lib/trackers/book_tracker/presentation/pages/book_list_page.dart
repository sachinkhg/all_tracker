import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/book.dart';
import '../../domain/entities/read_history_entry.dart';
import '../../domain/usecases/book/get_book_stats.dart';
import '../bloc/book_cubit.dart';
import '../bloc/book_state.dart';
import '../../core/injection.dart';
import '../../../../widgets/primary_app_bar.dart';
import '../../../../widgets/loading_view.dart';
import '../../../../widgets/error_view.dart';
import '../../../../widgets/bottom_sheet_helpers.dart';
import '../widgets/book_list_item.dart';
import '../widgets/book_form_bottom_sheet.dart';
import '../widgets/book_filter_bottom_sheet.dart';
import '../widgets/book_stats_card.dart';
import '../../features/book_import_export.dart';
import '../../../../widgets/app_drawer.dart';
import '../../../../pages/app_home_page.dart';
import 'package:provider/provider.dart';
import '../../../../core/organization_notifier.dart';

class BookListPage extends StatelessWidget {
  const BookListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = createBookCubit();
        cubit.loadBooks();
        return cubit;
      },
      child: const BookListPageView(),
    );
  }
}

class BookListPageView extends StatefulWidget {
  const BookListPageView({super.key});

  @override
  State<BookListPageView> createState() => _BookListPageViewState();
}

class _BookListPageViewState extends State<BookListPageView> {
  BookFilter _currentFilter = BookFilter(readYear: DateTime.now().year);
  String _sortBy = 'dateRead'; // Default: Date Read (descending)

  List<Book> _applyFiltersAndSort(List<Book> books) {
    var filtered = List<Book>.from(books);

    // Apply filters
    if (_currentFilter.status != null) {
      filtered = filtered.where((book) => book.status == _currentFilter.status).toList();
    }
    if (_currentFilter.author != null && _currentFilter.author!.isNotEmpty) {
      final authorLower = _currentFilter.author!.toLowerCase();
      filtered = filtered.where((book) =>
          book.primaryAuthor.toLowerCase().contains(authorLower)).toList();
    }
    if (_currentFilter.publishedYear != null) {
      filtered = filtered.where((book) =>
          book.datePublished?.year == _currentFilter.publishedYear).toList();
    }
    if (_currentFilter.readYear != null) {
      filtered = filtered.where((book) {
        if (book.dateRead != null && book.dateRead!.year == _currentFilter.readYear) {
          return true;
        }
        return book.readHistory.any((entry) =>
            entry.dateRead != null && entry.dateRead!.year == _currentFilter.readYear);
      }).toList();
    }

    // Apply sorting
    switch (_sortBy) {
      case 'dateRead':
        filtered.sort((a, b) {
          if (a.dateRead == null && b.dateRead == null) return 0;
          if (a.dateRead == null) return 1;
          if (b.dateRead == null) return -1;
          return b.dateRead!.compareTo(a.dateRead!); // Descending
        });
        break;
      case 'avgRating':
        filtered.sort((a, b) {
          if (a.avgRating == null && b.avgRating == null) return 0;
          if (a.avgRating == null) return 1;
          if (b.avgRating == null) return -1;
          return b.avgRating!.compareTo(a.avgRating!); // Descending
        });
        break;
      case 'pageCount':
        filtered.sort((a, b) => b.pageCount.compareTo(a.pageCount)); // Descending
        break;
      case 'title':
        filtered.sort((a, b) => a.title.compareTo(b.title)); // Ascending
        break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BookCubit>();

    return Scaffold(
      drawer: const AppDrawer(currentPage: AppPage.bookTracker),
      appBar: PrimaryAppBar(
        title: 'Book Tracker',
        actions: [
          Consumer<OrganizationNotifier>(
            builder: (context, orgNotifier, _) {
              if (orgNotifier.defaultHomePage == 'app_home') {
                return IconButton(
                  tooltip: 'Home Page',
                  icon: const Icon(Icons.home),
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const AppHomePage()),
                      (route) => false,
                    );
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: BlocBuilder<BookCubit, BookState>(
          builder: (context, state) {
            if (state is BooksLoading) {
              return const LoadingView();
            }

            if (state is BooksLoaded) {
              final books = state.books;
              final filteredAndSorted = _applyFiltersAndSort(books);

              return Column(
                children: [
                  BookStatsCard(stats: _calculateStats(filteredAndSorted)),
                  const SizedBox(height: 12),
                  Expanded(
                    child: filteredAndSorted.isEmpty
                        ? const Center(
                            child: Text('No books found. Tap + to add one.'),
                          )
                        : ListView.builder(
                            itemCount: filteredAndSorted.length,
                            itemBuilder: (context, index) {
                              final book = filteredAndSorted[index];
                              return BookListItem(
                                book: book,
                                onTap: () {
                                  _showBookForm(context, cubit, book: book);
                                },
                              );
                            },
                          ),
                  ),
                ],
              );
            }

            if (state is BooksError) {
              return ErrorView(
                message: state.message,
                onRetry: () => cubit.loadBooks(),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
      floatingActionButton: _ActionsFab(
        onFilter: () {
          BookFilterBottomSheet.show(
            context,
            initialFilter: _currentFilter,
            onApply: (filter) {
              setState(() {
                _currentFilter = filter;
              });
            },
          );
        },
        onSort: () {
          showModalBottomSheet(
            context: context,
            builder: (context) {
              return SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      title: const Text('Date Read'),
                      onTap: () {
                        setState(() {
                          _sortBy = 'dateRead';
                        });
                        Navigator.pop(context);
                      },
                      trailing: _sortBy == 'dateRead' ? const Icon(Icons.check) : null,
                    ),
                    ListTile(
                      title: const Text('Average Rating'),
                      onTap: () {
                        setState(() {
                          _sortBy = 'avgRating';
                        });
                        Navigator.pop(context);
                      },
                      trailing: _sortBy == 'avgRating' ? const Icon(Icons.check) : null,
                    ),
                    ListTile(
                      title: const Text('Page Count'),
                      onTap: () {
                        setState(() {
                          _sortBy = 'pageCount';
                        });
                        Navigator.pop(context);
                      },
                      trailing: _sortBy == 'pageCount' ? const Icon(Icons.check) : null,
                    ),
                    ListTile(
                      title: const Text('Title'),
                      onTap: () {
                        setState(() {
                          _sortBy = 'title';
                        });
                        Navigator.pop(context);
                      },
                      trailing: _sortBy == 'title' ? const Icon(Icons.check) : null,
                    ),
                  ],
                ),
              );
            },
          );
        },
        hasFilters: _currentFilter.hasFilters,
        onAdd: () => _showBookForm(context, cubit),
        onMore: () => _showActionsSheet(context, cubit),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  BookStats _calculateStats(List<Book> books) {
    // Count completed books (unique titles with dateRead or completed readHistory entries)
    final completedBooks = books.where((book) {
      return book.dateRead != null ||
          book.readHistory.any((entry) => entry.isCompleted);
    }).length;

    // Count total reads based on filter
    // If readYear filter is applied, only count reads that match that year
    int totalReads = 0;
    int totalPagesRead = 0;
    double? sumRatings;
    int completedBooksWithRating = 0;

    for (final book in books) {
      int bookReads = 0;
      
      if (_currentFilter.readYear != null) {
        // Filter by read year: count only reads that match the year
        // Check current read
        if (book.dateRead != null && book.dateRead!.year == _currentFilter.readYear) {
          bookReads += 1;
        }
        // Check read history
        for (final entry in book.readHistory) {
          if (entry.isCompleted && 
              entry.dateRead != null && 
              entry.dateRead!.year == _currentFilter.readYear) {
            bookReads += 1;
          }
        }
      } else {
        // No read year filter: count all completed reads
        bookReads = book.totalCompletedReads;
      }
      
      if (bookReads > 0) {
        totalReads += bookReads;
        totalPagesRead += book.pageCount * bookReads;

        // Calculate average rating only for completed books
        // Only include if the current read matches the filter (or no filter)
        bool includeInRating = false;
        if (_currentFilter.readYear != null) {
          // Only include if current read matches the year filter
          includeInRating = book.avgRating != null && 
              book.dateRead != null && 
              book.dateRead!.year == _currentFilter.readYear;
        } else {
          // No filter: include if book has current read completed
          includeInRating = book.avgRating != null && book.dateRead != null;
        }
        
        if (includeInRating) {
          if (sumRatings == null) {
            sumRatings = 0.0;
          }
          sumRatings += book.avgRating!;
          completedBooksWithRating++;
        }
      }
    }

    final averageRating = completedBooksWithRating > 0 && sumRatings != null
        ? sumRatings / completedBooksWithRating
        : null;

    return BookStats(
      totalBooks: 0, // Not used anymore, but keeping for backward compatibility
      completedBooks: completedBooks,
      totalReads: totalReads,
      totalPagesRead: totalPagesRead,
      averageRating: averageRating,
    );
  }

  void _showBookForm(
    BuildContext context,
    BookCubit cubit, {
    Book? book,
  }) {
    BookFormBottomSheet.show(
      context,
      book: book,
      onSubmit: ({
        required String title,
        required String primaryAuthor,
        required int pageCount,
        double? avgRating,
        DateTime? datePublished,
        DateTime? dateStarted,
        DateTime? dateRead,
        List<ReadHistoryEntry>? readHistory,
      }) async {
        if (book != null) {
          // Update existing
          final updated = book.copyWith(
            title: title,
            primaryAuthor: primaryAuthor,
            pageCount: pageCount,
            avgRating: avgRating,
            datePublished: datePublished,
            dateStarted: dateStarted,
            dateRead: dateRead,
            readHistory: readHistory ?? book.readHistory,
            updatedAt: DateTime.now(),
          );
          await cubit.updateBook(updated);
        } else {
          // Create new
          await cubit.createBook(
            title: title,
            primaryAuthor: primaryAuthor,
            pageCount: pageCount,
            avgRating: avgRating,
            datePublished: datePublished,
            dateStarted: dateStarted,
            dateRead: dateRead,
          );
        }
      },
      onDelete: book != null
          ? () async {
              await cubit.deleteBook(book.id);
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            }
          : null,
      onReRead: book != null && book.dateRead != null
          ? () async {
              return await cubit.reReadBook(book);
            }
          : null,
      onRemoveHistoryEntry: book != null
          ? (int index) async {
              return await cubit.removeReadHistoryEntry(book, index);
            }
          : null,
      title: book != null ? 'Edit Book' : 'Create Book',
    );
  }

  void _showActionsSheet(BuildContext context, BookCubit cubit) {
    final sheet = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 12),
        ListTile(
          leading: const Icon(Icons.add),
          title: const Text('Add Book'),
          onTap: () {
            Navigator.of(context).pop();
            _showBookForm(context, cubit);
          },
        ),
        ListTile(
          leading: const Icon(Icons.file_download),
          title: const Text('Export'),
          onTap: () async {
            Navigator.of(context).pop();
            final state = cubit.state;
            final books = state is BooksLoaded ? state.books : <Book>[];
            final path = await exportBooksToXlsx(context, books);
            if (path != null && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('File exported')),
              );
            }
          },
        ),
        ListTile(
          leading: const Icon(Icons.file_upload),
          title: const Text('Import'),
          onTap: () {
            Navigator.of(context).pop();
            importBooksFromXlsx(context);
          },
        ),
        ListTile(
          leading: const Icon(Icons.download),
          title: const Text('Download Template'),
          onTap: () async {
            Navigator.of(context).pop();
            final path = await downloadBooksTemplate(context);
            if (path != null && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Template downloaded')),
              );
            }
          },
        ),
        const SizedBox(height: 8),
      ],
    );

    showAppBottomSheet<void>(context, sheet);
  }
}

class _ActionsFab extends StatelessWidget {
  const _ActionsFab({
    required this.onFilter,
    required this.onSort,
    required this.hasFilters,
    required this.onAdd,
    required this.onMore,
  });

  final VoidCallback onFilter;
  final VoidCallback onSort;
  final bool hasFilters;
  final VoidCallback onAdd;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Filter and Sort row
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton.small(
              heroTag: 'filterFab',
              tooltip: 'Filter',
              backgroundColor: cs.surface.withValues(alpha: 0.85),
              onPressed: onFilter,
              child: Icon(hasFilters ? Icons.filter_alt : Icons.filter_alt_outlined),
            ),
            const SizedBox(width: 12),
            FloatingActionButton.small(
              heroTag: 'sortFab',
              tooltip: 'Sort',
              backgroundColor: cs.surface.withValues(alpha: 0.85),
              onPressed: onSort,
              child: const Icon(Icons.sort),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Add and More row
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton.small(
              heroTag: 'addBookFab',
              tooltip: 'Add Book',
              backgroundColor: cs.surface.withValues(alpha: 0.85),
              onPressed: onAdd,
              child: const Icon(Icons.add),
            ),
            const SizedBox(width: 12),
            FloatingActionButton.small(
              heroTag: 'moreFab',
              tooltip: 'More actions',
              backgroundColor: cs.surface.withValues(alpha: 0.85),
              onPressed: onMore,
              child: const Icon(Icons.more_vert),
            ),
          ],
        ),
      ],
    );
  }
}

