import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/expense_cubit.dart';
import '../bloc/expense_state.dart';
import '../bloc/traveler_cubit.dart';
import '../bloc/traveler_state.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/traveler.dart';
import '../../core/injection.dart';
import '../../core/constants.dart';
import '../../core/app_icons.dart';
import '../../../../widgets/loading_view.dart';
import '../../../../widgets/error_view.dart';
import '../widgets/expense_form_bottom_sheet.dart';

/// Page displaying expenses for a trip.
class ExpenseListPage extends StatelessWidget {
  final String tripId;

  const ExpenseListPage({
    super.key,
    required this.tripId,
  });

  @override
  Widget build(BuildContext context) {
    // Try to use existing providers from parent, otherwise create new ones
    bool hasExpenseCubit = false;
    bool hasTravelerCubit = false;
    
    try {
      context.read<ExpenseCubit>();
      hasExpenseCubit = true;
    } catch (_) {}
    
    try {
      context.read<TravelerCubit>();
      hasTravelerCubit = true;
    } catch (_) {}

    Widget child = ExpenseListPageView(tripId: tripId);
    
    // Wrap with TravelerCubit if not available
    if (!hasTravelerCubit) {
      child = BlocProvider(
        create: (_) {
          final cubit = createTravelerCubit();
          cubit.loadTravelers(tripId);
          return cubit;
        },
        child: child,
      );
    }
    
    // Wrap with ExpenseCubit if not available
    if (!hasExpenseCubit) {
      child = BlocProvider(
        create: (_) {
          final cubit = createExpenseCubit();
          cubit.loadExpenses(tripId);
          return cubit;
        },
        child: child,
      );
    }
    
    return child;
  }
}

class ExpenseListPageView extends StatelessWidget {
  final String tripId;

  const ExpenseListPageView({
    super.key,
    required this.tripId,
  });

  @override
  Widget build(BuildContext context) {
    final expenseCubit = context.read<ExpenseCubit>();
    
    // Try to get TravelerCubit if available
    TravelerCubit? travelerCubit;
    try {
      travelerCubit = context.read<TravelerCubit>();
    } catch (_) {
      // TravelerCubit not available in context
    }

    return BlocBuilder<ExpenseCubit, ExpenseState>(
      builder: (context, expenseState) {
        List<Traveler> travelers = [];
        if (travelerCubit != null) {
          final travelerState = travelerCubit.state;
          if (travelerState is TravelersLoaded) {
            travelers = travelerState.travelers;
          }
        }

        if (expenseState is ExpensesLoading) {
          return const LoadingView();
        }

        if (expenseState is ExpensesLoaded) {
          final expenses = expenseState.expenses;

          if (expenses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    TravelTrackerIcons.expense,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No expenses yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _addExpense(context, travelers),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Expense'),
                  ),
                ],
              ),
            );
          }

          // Group expenses by expense date
          final groupedExpenses = _groupExpensesByDate(expenses);
          
          // Sort groups in ascending order (oldest first)
          final sortedDates = groupedExpenses.keys.toList()
            ..sort((a, b) => a.compareTo(b));

          final total = expenses.fold<double>(
            0.0,
            (sum, expense) => sum + expense.amount,
          );

          final totalFormatted = NumberFormat('#,##0.00').format(total);

          return Column(
            children: [
              Card(
                margin: const EdgeInsets.all(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Expenses',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        totalFormatted,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: sortedDates.length,
                  itemBuilder: (context, index) {
                    final dateAdded = sortedDates[index];
                    final expensesForDate = groupedExpenses[dateAdded]!;
                    
                    // Calculate total for this date group
                    final dateTotal = expensesForDate.fold<double>(
                      0.0,
                      (sum, expense) => sum + expense.amount,
                    );
                    final dateTotalFormatted = NumberFormat('#,##0.00').format(dateTotal);
                    
                    // Format the date
                    final dateFormatted = DateFormat('MMM dd, yyyy').format(dateAdded);
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: ExpansionTile(
                        initiallyExpanded: true,
                        tilePadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        childrenPadding: const EdgeInsets.symmetric(
                          vertical: 8,
                        ),
                        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                        collapsedBackgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                        leading: Icon(
                          Icons.calendar_today,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        title: Text(
                          dateFormatted,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                        subtitle: Text(
                          'Total: $dateTotalFormatted',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        children: expensesForDate.map((expense) {
                          return Container(
                            color: Theme.of(context).colorScheme.surface,
                            child: InkWell(
                              onTap: () => _editExpense(context, expense, travelers),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                child: ListTile(
                                isThreeLine: expense.description != null || expense.paidBy != null,
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 0,
                                  vertical: 0,
                                ),
                                leading: Icon(
                                  _getCategoryIcon(expense.category),
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                title: Text(
                                  expenseCategoryLabels[expense.category]!,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Text(
                                    //   DateFormat('MMM dd, yyyy').format(expense.date),
                                    //   style: Theme.of(context).textTheme.bodySmall,
                                    // ),
                                    if (expense.paidBy != null)
                                      Builder(
                                        builder: (context) {
                                          final traveler = travelers.firstWhere(
                                            (t) => t.id == expense.paidBy,
                                            orElse: () => Traveler(
                                              id: '',
                                              tripId: '',
                                              name: 'Unknown',
                                              createdAt: DateTime.now(),
                                              updatedAt: DateTime.now(),
                                            ),
                                          );
                                          return Row(
                                            // children: [
                                            //   Icon(
                                            //     Icons.person,
                                            //     size: 14,
                                            //     color: Theme.of(context).colorScheme.onSurfaceVariant,
                                            //   ),
                                            //   const SizedBox(width: 4),
                                            //   Text(
                                            //     'Paid by: ${traveler.name}',
                                            //     style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            //       color: Theme.of(context).colorScheme.primary,
                                            //       fontWeight: FontWeight.w500,
                                            //     ),
                                            //   ),
                                            // ],
                                          );
                                        },
                                      ),
                                    if (expense.description != null)
                                      Text(
                                        expense.description!,
                                        style: Theme.of(context).textTheme.bodySmall,
                                        maxLines: 3,
                                        overflow: TextOverflow.visible,
                                      ),
                                  ],
                                ),
                                trailing: Text(
                                  NumberFormat('#,##0.00').format(expense.amount),
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                            ),
                          ),
                        );
                        }).toList(),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        }

        if (expenseState is ExpensesError) {
          return ErrorView(
            message: expenseState.message,
            onRetry: () => expenseCubit.loadExpenses(tripId),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  /// Groups expenses by expense date.
  /// Returns a map where keys are dates (without time) and values are lists of expenses.
  Map<DateTime, List<Expense>> _groupExpensesByDate(List<Expense> expenses) {
    final Map<DateTime, List<Expense>> grouped = {};
    
    for (final expense in expenses) {
      // Get date without time component
      final dateKey = DateTime(
        expense.date.year,
        expense.date.month,
        expense.date.day,
      );
      
      grouped.putIfAbsent(dateKey, () => []).add(expense);
    }
    
    // Sort expenses within each group by date (ascending)
    grouped.forEach((date, expenseList) {
      expenseList.sort((a, b) => a.date.compareTo(b.date));
    });
    
    return grouped;
  }

  IconData _getCategoryIcon(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.food:
        return Icons.restaurant;
      case ExpenseCategory.travel:
        return Icons.directions_transit;
      case ExpenseCategory.stay:
        return Icons.hotel;
      case ExpenseCategory.other:
        return Icons.category;
    }
  }

  void _addExpense(BuildContext context, List<Traveler> travelers) {
    ExpenseFormBottomSheet.show(
      context,
      tripId: tripId,
      travelers: travelers.isNotEmpty ? travelers : null,
      onSubmit: (date, category, amount, currency, description, paidBy) async {
        final cubit = context.read<ExpenseCubit>();
        await cubit.createExpenseEntry(
          tripId: tripId,
          date: date,
          category: category,
          amount: amount,
          currency: currency,
          description: description,
          paidBy: paidBy,
        );
      },
    );
  }

  void _editExpense(BuildContext context, Expense expense, List<Traveler> travelers) {
    ExpenseFormBottomSheet.show(
      context,
      tripId: tripId,
      travelers: travelers.isNotEmpty ? travelers : null,
      initialDate: expense.date,
      initialCategory: expense.category,
      initialAmount: expense.amount,
      initialCurrency: expense.currency,
      initialDescription: expense.description,
      initialPaidBy: expense.paidBy,
      onSubmit: (date, category, amount, currency, description, paidBy) async {
        final cubit = context.read<ExpenseCubit>();
        final updated = Expense(
          id: expense.id,
          tripId: expense.tripId,
          date: date,
          category: category,
          amount: amount,
          currency: currency,
          description: description,
          paidBy: paidBy,
          createdAt: expense.createdAt,
          updatedAt: DateTime.now(),
        );
        await cubit.updateExpenseEntry(updated);
      },
      onDelete: () async {
        final cubit = context.read<ExpenseCubit>();
        await cubit.deleteExpenseEntry(expense.id, tripId);
      },
    );
  }
}

