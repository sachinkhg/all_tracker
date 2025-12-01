import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/expense_cubit.dart';
import '../bloc/expense_insights_cubit.dart';
import '../bloc/expense_insights_state.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/expense_group.dart';
import '../../core/injection.dart';
import '../../../../widgets/primary_app_bar.dart';
import '../../../../widgets/loading_view.dart';
import '../../../../widgets/error_view.dart';
import '../../../../core/design_tokens.dart';
import '../widgets/expense_insights_card.dart';
import '../widgets/expense_list_item.dart';
import '../widgets/expense_form_bottom_sheet.dart';
import '../widgets/expense_filter_bottom_sheet.dart';

/// Widget to display filtered expenses list
class _FilteredExpensesList extends StatefulWidget {
  final ExpenseGroup? selectedGroup;
  final DateTime? startDate;
  final DateTime? endDate;
  final void Function(Expense) onExpenseTap;

  const _FilteredExpensesList({
    required this.selectedGroup,
    required this.startDate,
    required this.endDate,
    required this.onExpenseTap,
  });

  @override
  State<_FilteredExpensesList> createState() => _FilteredExpensesListState();
}

class _FilteredExpensesListState extends State<_FilteredExpensesList> {
  List<Expense> _filteredExpenses = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  @override
  void didUpdateWidget(_FilteredExpensesList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedGroup != widget.selectedGroup ||
        oldWidget.startDate != widget.startDate ||
        oldWidget.endDate != widget.endDate) {
      _loadExpenses();
    }
  }

  Future<void> _loadExpenses() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final cubit = context.read<ExpenseCubit>();
      final expenses = await cubit.getExpensesByGroupAndDateRange(
        widget.selectedGroup,
        widget.startDate,
        widget.endDate,
      );
      setState(() {
        _filteredExpenses = expenses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const LoadingView();
    }

    if (_error != null) {
      return ErrorView(
        message: _error!,
        onRetry: _loadExpenses,
      );
    }

    if (_filteredExpenses.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.l),
          child: Text('No expenses found for the selected filters.'),
        ),
      );
    }

    // Sort by date (newest first)
    final sortedExpenses = List<Expense>.from(_filteredExpenses)
      ..sort((a, b) => b.date.compareTo(a.date));

    return Column(
      children: sortedExpenses.map((expense) {
        return ExpenseListItem(
          expense: expense,
          onTap: () => widget.onExpenseTap(expense),
        );
      }).toList(),
    );
  }
}

class ExpenseDashboardPage extends StatefulWidget {
  const ExpenseDashboardPage({super.key});

  @override
  State<ExpenseDashboardPage> createState() => _ExpenseDashboardPageState();
}

class _ExpenseDashboardPageState extends State<ExpenseDashboardPage> {
  ExpenseGroup? _selectedGroup;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    // Default to current month
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month + 1, 0);
  }


  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) {
            final cubit = createExpenseCubit();
            cubit.loadExpenses();
            return cubit;
          },
        ),
        BlocProvider(
          create: (_) {
            final cubit = createExpenseInsightsCubit();
            cubit.loadInsights(
              group: _selectedGroup,
              start: _startDate,
              end: _endDate,
            );
            return cubit;
          },
        ),
      ],
      child: Builder(
        builder: (context) => _ExpenseDashboardContent(
          selectedGroup: _selectedGroup,
          startDate: _startDate,
          endDate: _endDate,
          onGroupChanged: (group) {
            setState(() {
              _selectedGroup = group;
            });
          },
          onDateRangeChanged: (start, end) {
            setState(() {
              _startDate = start;
              _endDate = end;
            });
          },
        ),
      ),
    );
  }
}

class _ExpenseDashboardContent extends StatefulWidget {
  final ExpenseGroup? selectedGroup;
  final DateTime? startDate;
  final DateTime? endDate;
  final void Function(ExpenseGroup?) onGroupChanged;
  final void Function(DateTime?, DateTime?) onDateRangeChanged;

  const _ExpenseDashboardContent({
    required this.selectedGroup,
    required this.startDate,
    required this.endDate,
    required this.onGroupChanged,
    required this.onDateRangeChanged,
  });

  @override
  State<_ExpenseDashboardContent> createState() => _ExpenseDashboardContentState();
}

class _ExpenseDashboardContentState extends State<_ExpenseDashboardContent> {
  double? _currentMonthNetBalance;
  double? _lastMonthNetBalance;
  double? _average3MonthsNetBalance;

  @override
  void initState() {
    super.initState();
    // Load insights when widget is first created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInsights();
      _loadNetBalances();
    });
  }

  @override
  void didUpdateWidget(_ExpenseDashboardContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload insights when filters change
    if (oldWidget.selectedGroup != widget.selectedGroup ||
        oldWidget.startDate != widget.startDate ||
        oldWidget.endDate != widget.endDate) {
      _loadInsights();
      _loadNetBalances();
    }
  }

  void _loadInsights() {
    context.read<ExpenseInsightsCubit>().loadInsights(
          group: widget.selectedGroup,
          start: widget.startDate,
          end: widget.endDate,
        );
  }

  Future<void> _loadNetBalances() async {
    try {
      final cubit = context.read<ExpenseInsightsCubit>();
      final now = DateTime.now();

      // Current month
      final currentMonthStart = DateTime(now.year, now.month, 1);
      final currentMonthEnd = DateTime(now.year, now.month + 1, 0);
      final currentMonthInsights = await cubit.getInsights.call(
        widget.selectedGroup,
        currentMonthStart,
        currentMonthEnd,
      );

      // Last month
      final lastMonthStart = DateTime(now.year, now.month - 1, 1);
      final lastMonthEnd = DateTime(now.year, now.month, 0);
      final lastMonthInsights = await cubit.getInsights.call(
        widget.selectedGroup,
        lastMonthStart,
        lastMonthEnd,
      );

      // Calculate average of last 3 months (month -1, month -2, month -3)
      double totalNetBalance = lastMonthInsights.netBalance;
      
      // Month -2
      final month2Start = DateTime(now.year, now.month - 2, 1);
      final month2End = DateTime(now.year, now.month - 1, 0);
      final month2Insights = await cubit.getInsights.call(
        widget.selectedGroup,
        month2Start,
        month2End,
      );
      totalNetBalance += month2Insights.netBalance;
      
      // Month -3
      final month3Start = DateTime(now.year, now.month - 3, 1);
      final month3End = DateTime(now.year, now.month - 2, 0);
      final month3Insights = await cubit.getInsights.call(
        widget.selectedGroup,
        month3Start,
        month3End,
      );
      totalNetBalance += month3Insights.netBalance;

      if (mounted) {
        setState(() {
          _currentMonthNetBalance = currentMonthInsights.netBalance;
          _lastMonthNetBalance = lastMonthInsights.netBalance;
          // Average of last 3 months (month -1, -2, -3)
          _average3MonthsNetBalance = totalNetBalance / 3;
        });
      }
    } catch (e) {
      // Handle error silently or show a message
      debugPrint('Error loading net balances: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PrimaryAppBar(
        title: 'Expense Dashboard',
        actions: [
          IconButton(
            tooltip: 'Home Page',
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
          onRefresh: () async {
            _loadInsights();
            _loadNetBalances();
            context.read<ExpenseCubit>().loadExpenses();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.m),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Insights cards
                BlocBuilder<ExpenseInsightsCubit, ExpenseInsightsState>(
                  builder: (context, state) {
                    if (state is ExpenseInsightsLoading) {
                      return const LoadingView();
                    }

                    if (state is ExpenseInsightsError) {
                      return ErrorView(
                        message: state.message,
                        onRetry: _loadInsights,
                      );
                    }

                    if (state is ExpenseInsightsLoaded) {
                      final insights = state.insights;
                      final cs = Theme.of(context).colorScheme;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Summary cards
                          Row(
                            children: [
                              Expanded(
                                child: ExpenseInsightsCard(
                                  title: 'Total Expenses',
                                  value: insights.totalExpenses,
                                  icon: Icons.arrow_downward,
                                  color: cs.errorContainer,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.s),
                              Expanded(
                                child: ExpenseInsightsCard(
                                  title: 'Total Refunds',
                                  value: insights.totalCredits,
                                  icon: Icons.arrow_upward,
                                  color: cs.primaryContainer,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.s),
                          // Net Balance sections
                          Text(
                            'Net Balance',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: AppSpacing.s),
                          Row(
                            children: [
                              Expanded(
                                child: ExpenseInsightsCard(
                                  title: 'Current Month',
                                  value: _currentMonthNetBalance?.abs() ?? 0.0,
                                  icon: Icons.calendar_month,
                                  color: (_currentMonthNetBalance ?? 0) >= 0
                                      ? cs.tertiaryContainer
                                      : cs.errorContainer,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.s),
                              Expanded(
                                child: ExpenseInsightsCard(
                                  title: 'Last Month',
                                  value: _lastMonthNetBalance?.abs() ?? 0.0,
                                  icon: Icons.calendar_today,
                                  color: (_lastMonthNetBalance ?? 0) >= 0
                                      ? cs.tertiaryContainer
                                      : cs.errorContainer,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.s),
                              Expanded(
                                child: ExpenseInsightsCard(
                                  title: 'Avg 3 Months',
                                  value: _average3MonthsNetBalance?.abs() ?? 0.0,
                                  icon: Icons.trending_up,
                                  color: (_average3MonthsNetBalance ?? 0) >= 0
                                      ? cs.tertiaryContainer
                                      : cs.errorContainer,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.m),
                          // Group breakdown
                          Text(
                            'Breakdown by Group',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: AppSpacing.s),
                          ...insights.totalsByGroup.entries.map((entry) {
                            final group = entry.key;
                            final total = entry.value;
                            final percentage = insights.percentagesByGroup[group] ?? 0.0;
                            final count = insights.countsByGroup[group] ?? 0;

                            return Card(
                              margin: const EdgeInsets.only(bottom: AppSpacing.s),
                              child: ListTile(
                                leading: CircleAvatar(
                                  child: Text(group.displayName[0]),
                                ),
                                title: Text(group.displayName),
                                subtitle: Text(
                                  '$count transaction${count != 1 ? 's' : ''} • ${percentage.toStringAsFixed(1)}%',
                                ),
                                trailing: Text(
                                  NumberFormat('#,##0.00').format(total.abs()),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: total >= 0
                                            ? cs.error
                                            : cs.primary,
                                      ),
                                ),
                              ),
                            );
                          }),
                        ],
                      );
                    }

                    return const SizedBox.shrink();
                  },
                ),
                const SizedBox(height: AppSpacing.m),
                // Filtered expenses list
                Text(
                  'Expenses',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.s),
                _FilteredExpensesList(
                  selectedGroup: widget.selectedGroup,
                  startDate: widget.startDate,
                  endDate: widget.endDate,
                  onExpenseTap: (expense) {
                    _showExpenseForm(expense: expense);
                  },
                ),
              ],
            ),
          ),
        ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'expenseFilterFab',
            tooltip: 'Filter Expenses',
            backgroundColor: (widget.selectedGroup != null || widget.startDate != null || widget.endDate != null)
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
            onPressed: () => _showFilterBottomSheet(context),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(Icons.filter_alt),
                if (widget.selectedGroup != null || widget.startDate != null || widget.endDate != null)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onPrimary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'expenseAddFab',
            tooltip: 'Add Expense',
            onPressed: () => _showExpenseForm(),
            child: const Icon(Icons.add),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Future<void> _showFilterBottomSheet(BuildContext context) async {
    final result = await ExpenseFilterBottomSheet.show(
      context,
      initialGroup: widget.selectedGroup,
      initialStartDate: widget.startDate,
      initialEndDate: widget.endDate,
    );

    if (result != null) {
      ExpenseGroup? newGroup;
      if (result['group'] != null && result['group'] is String) {
        try {
          newGroup = ExpenseGroup.values.firstWhere(
            (g) => g.name == result['group'] as String,
          );
        } catch (e) {
          newGroup = null;
        }
      } else {
        newGroup = null;
      }

      DateTime? newStartDate;
      DateTime? newEndDate;
      if (result['startDate'] != null && result['endDate'] != null) {
        newStartDate = DateTime.fromMillisecondsSinceEpoch(result['startDate'] as int);
        newEndDate = DateTime.fromMillisecondsSinceEpoch(result['endDate'] as int);
      } else {
        // Clear date range if not provided
        newStartDate = null;
        newEndDate = null;
      }

      widget.onGroupChanged(newGroup);
      widget.onDateRangeChanged(newStartDate, newEndDate);
      // Insights will reload automatically via didUpdateWidget
    }
  }

  void _showExpenseForm({Expense? expense}) {
    final cubit = context.read<ExpenseCubit>();
    ExpenseFormBottomSheet.show(
      context,
      expense: expense,
      onSubmit: (date, description, amount, group) async {
        if (expense != null) {
          // Update existing
          final updated = expense.copyWith(
            date: date,
            description: description,
            amount: amount,
            group: group,
            updatedAt: DateTime.now(),
          );
          await cubit.updateExpense(updated);
        } else {
          // Create new
          await cubit.createExpense(
            date: date,
            description: description,
            amount: amount,
            group: group,
          );
        }
        _loadInsights();
      },
      onDelete: expense != null
          ? () async {
              await cubit.deleteExpense(expense.id);
              if (context.mounted) {
                Navigator.of(context).pop();
              }
              _loadInsights();
            }
          : null,
      title: expense != null ? 'Edit Expense' : 'Create Expense',
    );
  }
}

