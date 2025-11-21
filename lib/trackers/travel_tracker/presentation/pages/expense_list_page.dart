import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/expense_cubit.dart';
import '../bloc/expense_state.dart';
import '../../domain/entities/expense.dart';
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
    // Try to use existing provider from parent, otherwise create new one
    try {
      context.read<ExpenseCubit>();
      // Provider exists, use it
      return ExpenseListPageView(tripId: tripId);
    } catch (_) {
      // No provider exists, create one
      return BlocProvider(
        create: (_) {
          final cubit = createExpenseCubit();
          cubit.loadExpenses(tripId);
          return cubit;
        },
        child: ExpenseListPageView(tripId: tripId),
      );
    }
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
    final cubit = context.read<ExpenseCubit>();

    return BlocBuilder<ExpenseCubit, ExpenseState>(
      builder: (context, state) {
        if (state is ExpensesLoading) {
          return const LoadingView();
        }

        if (state is ExpensesLoaded) {
          final expenses = state.expenses;

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
                    onPressed: () => _addExpense(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Expense'),
                  ),
                ],
              ),
            );
          }

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
                  itemCount: expenses.length,
                  itemBuilder: (context, index) {
                    final expense = expenses[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () => _editExpense(context, expense),
                        borderRadius: BorderRadius.circular(12),
                        child: ListTile(
                          isThreeLine: expense.description != null,
                          dense: true,
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
                              Text(
                                DateFormat('MMM dd, yyyy').format(expense.date),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              if (expense.description != null)
                                Text(
                                  expense.description!,
                                  style: Theme.of(context).textTheme.bodySmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
                    );
                  },
                ),
              ),
            ],
          );
        }

        if (state is ExpensesError) {
          return ErrorView(
            message: state.message,
            onRetry: () => cubit.loadExpenses(tripId),
          );
        }

        return const SizedBox.shrink();
      },
    );
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

  void _addExpense(BuildContext context) {
    ExpenseFormBottomSheet.show(
      context,
      tripId: tripId,
      onSubmit: (date, category, amount, currency, description) async {
        final cubit = context.read<ExpenseCubit>();
        await cubit.createExpenseEntry(
          tripId: tripId,
          date: date,
          category: category,
          amount: amount,
          currency: currency,
          description: description,
        );
      },
    );
  }

  void _editExpense(BuildContext context, expense) {
    ExpenseFormBottomSheet.show(
      context,
      tripId: tripId,
      initialDate: expense.date,
      initialCategory: expense.category,
      initialAmount: expense.amount,
      initialCurrency: expense.currency,
      initialDescription: expense.description,
      onSubmit: (date, category, amount, currency, description) async {
        final cubit = context.read<ExpenseCubit>();
        final updated = Expense(
          id: expense.id,
          tripId: expense.tripId,
          date: date,
          category: category,
          amount: amount,
          currency: currency,
          description: description,
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

