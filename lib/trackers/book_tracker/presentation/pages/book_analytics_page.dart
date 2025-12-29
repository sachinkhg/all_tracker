import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/constants.dart';
import '../../data/datasources/book_local_data_source.dart';
import '../../data/models/book_model.dart';
import '../../data/repositories/book_repository_impl.dart';
import '../../domain/usecases/book/get_reading_activity_data.dart';
import '../../domain/usecases/book/get_top_authors_data.dart';
import '../../domain/usecases/book/get_reread_statistics.dart';
import '../../domain/usecases/book/get_page_count_distribution.dart';
import '../widgets/charts/reading_activity_chart.dart';
import '../widgets/charts/top_authors_chart.dart';
import '../widgets/charts/reread_pie_chart.dart';
import '../widgets/charts/page_count_histogram.dart';
import '../../../../widgets/primary_app_bar.dart';
import '../../../../widgets/loading_view.dart';
import '../../../../widgets/error_view.dart';

class BookAnalyticsPage extends StatefulWidget {
  const BookAnalyticsPage({super.key});

  @override
  State<BookAnalyticsPage> createState() => _BookAnalyticsPageState();
}

class _BookAnalyticsPageState extends State<BookAnalyticsPage> {
  bool _isLoading = true;
  String? _errorMessage;

  // Date filters - default to current year
  late DateTime _startDate;
  late DateTime _endDate;
  int _currentYear;

  // Chart data
  List<ReadingActivityDataPoint> _readingActivityData = [];
  List<TopAuthorDataPoint> _topAuthorsData = [];
  RereadStatistics? _rereadStatistics;
  List<PageCountRangeDataPoint> _pageCountData = [];

  _BookAnalyticsPageState() : _currentYear = DateTime.now().year {
    final now = DateTime.now();
    _startDate = DateTime(now.year, 1, 1);
    _endDate = DateTime(now.year, 12, 31);
  }

  @override
  void initState() {
    super.initState();
    _loadChartData();
  }

  Future<void> _loadChartData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get repository using same pattern as injection
      if (!Hive.isBoxOpen(booksTrackerBoxName)) {
        throw StateError(
          'Book tracker box is not open. This may happen during hot reload. '
          'Please restart the app to reinitialize Hive boxes.',
        );
      }
      final Box<BookModel> box = Hive.box<BookModel>(booksTrackerBoxName);

      final localDataSource = BookLocalDataSourceImpl(box);
      final repository = BookRepositoryImpl(localDataSource);

      // Create use cases
      final getReadingActivity = GetReadingActivityData(repository);
      final getTopAuthors = GetTopAuthorsData(repository);
      final getReread = GetRereadStatistics(repository);
      final getPageCount = GetPageCountDistribution(repository);

      // Load all data
      final results = await Future.wait([
        getReadingActivity(startDate: _startDate, endDate: _endDate),
        getTopAuthors(limit: 5, startDate: _startDate, endDate: _endDate),
        getReread(startDate: _startDate, endDate: _endDate),
        getPageCount(startDate: _startDate, endDate: _endDate),
      ]);

      setState(() {
        _readingActivityData = results[0] as List<ReadingActivityDataPoint>;
        _topAuthorsData = results[1] as List<TopAuthorDataPoint>;
        _rereadStatistics = results[2] as RereadStatistics;
        _pageCountData = results[3] as List<PageCountRangeDataPoint>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _showDateRangePicker() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 10, 1, 1);
    final lastDate = DateTime(now.year + 1, 12, 31);

    final picked = await showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        // Update current year if the range spans a single year
        if (picked.start.year == picked.end.year) {
          _currentYear = picked.start.year;
        }
      });
      _loadChartData();
    }
  }

  void _navigateToYear(int year) {
    setState(() {
      _currentYear = year;
      _startDate = DateTime(year, 1, 1);
      _endDate = DateTime(year, 12, 31);
    });
    _loadChartData();
  }

  void _navigateToPreviousYear() {
    _navigateToYear(_currentYear - 1);
  }

  void _navigateToNextYear() {
    final now = DateTime.now();
    if (_currentYear < now.year) {
      _navigateToYear(_currentYear + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PrimaryAppBar(
        title: 'Book Analytics',
      ),
      body: _isLoading
          ? const LoadingView()
          : _errorMessage != null
              ? ErrorView(
                  message: _errorMessage!,
                  onRetry: _loadChartData,
                )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDateFilterSection(),
          const SizedBox(height: 24),
          _buildChartCard(
            title: 'Reading Activity Timeline',
            child: ReadingActivityChart(dataPoints: _readingActivityData),
          ),
          const SizedBox(height: 24),
          _buildChartCard(
            title: 'Top 5 Authors',
            child: TopAuthorsChart(dataPoints: _topAuthorsData),
          ),
          const SizedBox(height: 24),
          _buildChartCard(
            title: 'Re-reads vs First Reads',
            child: _rereadStatistics != null
                ? RereadPieChart(statistics: _rereadStatistics!)
                : const SizedBox(),
          ),
          const SizedBox(height: 24),
          _buildChartCard(
            title: 'Page Count Distribution',
            child: PageCountHistogram(dataPoints: _pageCountData),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDateFilterSection() {
    final now = DateTime.now();
    final canGoNext = _currentYear < now.year;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.filter_alt),
                const SizedBox(width: 8),
                Text(
                  'Date Range Filter',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                IconButton(
                  onPressed: _navigateToPreviousYear,
                  icon: const Icon(Icons.chevron_left),
                  tooltip: 'Previous Year',
                ),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showDateRangePicker,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      '${DateFormat('MMM d, yyyy').format(_startDate)} - ${DateFormat('MMM d, yyyy').format(_endDate)}',
                    ),
                  ),
                ),
                IconButton(
                  onPressed: canGoNext ? _navigateToNextYear : null,
                  icon: const Icon(Icons.chevron_right),
                  tooltip: 'Next Year',
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Year: $_currentYear',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard({required String title, required Widget child}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

