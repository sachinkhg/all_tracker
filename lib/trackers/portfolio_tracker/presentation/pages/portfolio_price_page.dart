// lib/trackers/portfolio_tracker/presentation/pages/portfolio_price_page.dart
// Main page for portfolio tracker POC - fetches ticker prices from Google Sheets

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../widgets/primary_app_bar.dart';
import '../../../../widgets/loading_view.dart';
import '../../../../widgets/error_view.dart';
import '../../../../widgets/app_drawer.dart';
import '../../../../pages/app_home_page.dart';
import '../../../../core/organization_notifier.dart';
import '../bloc/portfolio_cubit.dart';
import '../bloc/portfolio_state.dart';
import '../../core/injection.dart';
import '../../core/app_icons.dart';

class PortfolioPricePage extends StatelessWidget {
  const PortfolioPricePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => createPortfolioCubit(),
      child: const PortfolioPricePageView(),
    );
  }
}

class PortfolioPricePageView extends StatefulWidget {
  const PortfolioPricePageView({super.key});

  @override
  State<PortfolioPricePageView> createState() => _PortfolioPricePageViewState();
}

class _PortfolioPricePageViewState extends State<PortfolioPricePageView> {
  final _spreadsheetIdController = TextEditingController();
  final _sheetNameController = TextEditingController();
  final _tickerSymbolController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Set default sheet name
    _sheetNameController.text = 'Sheet1';
  }

  @override
  void dispose() {
    _spreadsheetIdController.dispose();
    _sheetNameController.dispose();
    _tickerSymbolController.dispose();
    super.dispose();
  }

  void _fetchPrice() {
    if (_formKey.currentState!.validate()) {
      context.read<PortfolioCubit>().fetchPrice(
            spreadsheetId: _spreadsheetIdController.text.trim(),
            sheetName: _sheetNameController.text.trim(),
            tickerSymbol: _tickerSymbolController.text.trim(),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      drawer: const AppDrawer(currentPage: AppPage.portfolioTracker),
      appBar: PrimaryAppBar(
        title: 'Portfolio Tracker',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              // Instructions card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: cs.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'How to use',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '1. Create a Google Sheet with ticker symbols in column A and prices in column B\n'
                        '2. Copy the Spreadsheet ID from the URL (the long string between /d/ and /edit)\n'
                        '3. Enter the Spreadsheet ID, sheet name, and ticker symbol below\n'
                        '4. Tap "Fetch Price" to get the current price',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Spreadsheet ID input
              TextFormField(
                controller: _spreadsheetIdController,
                decoration: const InputDecoration(
                  labelText: 'Google Spreadsheet ID',
                  hintText: 'Enter the spreadsheet ID from the URL',
                  prefixIcon: Icon(Icons.table_chart),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a spreadsheet ID';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Sheet name input
              TextFormField(
                controller: _sheetNameController,
                decoration: const InputDecoration(
                  labelText: 'Sheet Name',
                  hintText: 'e.g., Sheet1, Portfolio, etc.',
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a sheet name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Ticker symbol input
              TextFormField(
                controller: _tickerSymbolController,
                decoration: const InputDecoration(
                  labelText: 'Ticker Symbol',
                  hintText: 'e.g., AAPL, GOOGL, MSFT',
                  prefixIcon: Icon(Icons.trending_up),
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a ticker symbol';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              // Fetch button
              ElevatedButton.icon(
                onPressed: _fetchPrice,
                icon: const Icon(Icons.search),
                label: const Text('Fetch Price'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 32),
              // Result display
              BlocBuilder<PortfolioCubit, PortfolioState>(
                builder: (context, state) {
                  if (state is PortfolioLoading) {
                    return const LoadingView(message: 'Fetching price from Google Sheets...');
                  }

                  if (state is PortfolioPriceLoaded) {
                    return _buildPriceCard(context, state);
                  }

                  if (state is PortfolioError) {
                    return ErrorView(
                      message: state.message,
                      onRetry: _fetchPrice,
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceCard(BuildContext context, PortfolioPriceLoaded state) {
    final cs = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm:ss');

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  PortfolioTrackerIcons.ticker,
                  color: cs.primary,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Text(
                  state.tickerSymbol,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.primary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Icon(
                  PortfolioTrackerIcons.price,
                  color: cs.secondary,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Text(
                  '\$${state.price.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.secondary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: cs.outline),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: cs.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  'Fetched at: ${dateFormat.format(state.fetchedAt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
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

