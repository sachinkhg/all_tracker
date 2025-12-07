import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/expense.dart';
import '../bloc/expense_cubit.dart';
import '../bloc/expense_state.dart';
import '../../core/injection.dart';
import '../../../../widgets/primary_app_bar.dart';
import '../../../../widgets/loading_view.dart';
import '../../../../widgets/error_view.dart';
import '../../../../widgets/bottom_sheet_helpers.dart';
import '../widgets/expense_list_item.dart';
import '../widgets/expense_form_bottom_sheet.dart';
import '../../features/expense_import_export.dart';
import 'expense_dashboard_page.dart';
import '../../../../widgets/app_drawer.dart';
import '../../../../pages/app_home_page.dart';
import 'package:provider/provider.dart';
import '../../../../core/organization_notifier.dart';

class ExpenseListPage extends StatelessWidget {
  const ExpenseListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = createExpenseCubit();
        cubit.loadExpenses();
        return cubit;
      },
      child: const ExpenseListPageView(),
    );
  }
}

class ExpenseListPageView extends StatelessWidget {
  const ExpenseListPageView({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ExpenseCubit>();

    return Scaffold(
      drawer: const AppDrawer(currentPage: AppPage.expenseTracker),
      appBar: PrimaryAppBar(
        title: 'Expense Tracker',
        actions: [
          IconButton(
            tooltip: 'Dashboard',
            icon: const Icon(Icons.dashboard),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ExpenseDashboardPage(),
                ),
              );
            },
          ),
          Consumer<OrganizationNotifier>(
            builder: (context, orgNotifier, _) {
              // Only show home icon if default home page is app_home
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
        child: BlocBuilder<ExpenseCubit, ExpenseState>(
          builder: (context, state) {
            if (state is ExpensesLoading) {
              return const LoadingView();
            }

            if (state is ExpensesLoaded) {
              final expenses = state.expenses;

              if (expenses.isEmpty) {
                return const Center(
                  child: Text('No expenses yet. Tap + to add one.'),
                );
              }

              // Sort by date (newest first)
              final sortedExpenses = List<Expense>.from(expenses)
                ..sort((a, b) => b.date.compareTo(a.date));

              return ListView.builder(
                itemCount: sortedExpenses.length,
                itemBuilder: (context, index) {
                  final expense = sortedExpenses[index];
                  return ExpenseListItem(
                    expense: expense,
                    onTap: () {
                      _showExpenseForm(context, cubit, expense: expense);
                    },
                  );
                },
              );
            }

            if (state is ExpensesError) {
              return ErrorView(
                message: state.message,
                onRetry: () => cubit.loadExpenses(),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
      floatingActionButton: _ActionsFab(
        onAdd: () => _showExpenseForm(context, cubit),
        onMore: () => _showActionsSheet(context, cubit),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  void _showExpenseForm(
    BuildContext context,
    ExpenseCubit cubit, {
    Expense? expense,
  }) {
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
      },
      onDelete: expense != null
          ? () async {
              await cubit.deleteExpense(expense.id);
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            }
          : null,
      title: expense != null ? 'Edit Expense' : 'Create Expense',
    );
  }

  void _showActionsSheet(BuildContext context, ExpenseCubit cubit) {
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
          title: const Text('Add Expense'),
          onTap: () {
            Navigator.of(context).pop();
            _showExpenseForm(context, cubit);
          },
        ),
        ListTile(
          leading: const Icon(Icons.file_download),
          title: const Text('Export'),
          onTap: () async {
            Navigator.of(context).pop();
            final state = cubit.state;
            final expenses = state is ExpensesLoaded ? state.expenses : <Expense>[];
            final path = await exportExpensesToXlsx(context, expenses);
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
            importExpensesFromXlsx(context);
          },
        ),
        ListTile(
          leading: const Icon(Icons.download),
          title: const Text('Download Template'),
          onTap: () async {
            Navigator.of(context).pop();
            final path = await downloadExpensesTemplate(context);
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
    required this.onAdd,
    required this.onMore,
  });

  final VoidCallback onAdd;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton.small(
          heroTag: 'addExpenseFab',
          tooltip: 'Add Expense',
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
    );
  }
}

