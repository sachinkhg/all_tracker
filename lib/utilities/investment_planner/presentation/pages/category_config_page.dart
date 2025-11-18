import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/design_tokens.dart';
import '../../core/injection.dart';
import '../bloc/income_category_cubit.dart';
import '../bloc/income_category_state.dart';
import '../bloc/expense_category_cubit.dart';
import '../bloc/expense_category_state.dart';
import '../widgets/category_form_bottom_sheet.dart';
import '../../domain/entities/income_category.dart';
import '../../domain/entities/expense_category.dart';

/// Page for managing income and expense categories
class CategoryConfigPage extends StatelessWidget {
  const CategoryConfigPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => createIncomeCategoryCubit()),
        BlocProvider(create: (_) => createExpenseCategoryCubit()),
      ],
      child: DefaultTabController(
        length: 2,
        child: Builder(
          builder: (context) {
            final cs = Theme.of(context).colorScheme;
            final tabController = DefaultTabController.of(context);
            return Scaffold(
              appBar: AppBar(
                title: const Text('Categories'),
                flexibleSpace: Container(
                  decoration: BoxDecoration(
                    gradient: AppGradients.appBar(cs),
                  ),
                ),
                backgroundColor: Colors.transparent,
                foregroundColor: cs.onPrimary,
                iconTheme: IconThemeData(
                  color: cs.brightness == Brightness.dark
                      ? Colors.white.withOpacity(0.95)
                      : Colors.black87,
                  opacity: 1.0,
                ),
                actionsIconTheme: IconThemeData(
                  color: cs.brightness == Brightness.dark
                      ? Colors.white.withOpacity(0.95)
                      : Colors.black87,
                  opacity: 1.0,
                ),
                elevation: 0,
                bottom: TabBar(
                  tabs: const [
                    Tab(text: 'Income'),
                    Tab(text: 'Expense'),
                  ],
                  labelColor: cs.onPrimary,
                  unselectedLabelColor: cs.onPrimary.withOpacity(0.7),
                  indicatorColor: cs.onPrimary,
                ),
              ),
              body: const TabBarView(
                children: [
                  _IncomeCategoryTab(),
                  _ExpenseCategoryTab(),
                ],
              ),
              floatingActionButton: AnimatedBuilder(
                animation: tabController,
                builder: (context, child) {
                  final currentIndex = tabController.index;
                  return FloatingActionButton.small(
                    heroTag: currentIndex == 0 ? 'addIncomeCategoryFab' : 'addExpenseCategoryFab',
                    tooltip: currentIndex == 0 ? 'Add Income Category' : 'Add Expense Category',
                    backgroundColor: cs.surface.withOpacity(0.85),
                    onPressed: () {
                      final isIncome = currentIndex == 0;
                      _showAddCategoryForm(context, isIncome);
                    },
                    child: const Icon(Icons.add),
                  );
                },
              ),
              floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
            );
          },
        ),
      ),
    );
  }

  static void _showAddCategoryForm(BuildContext context, bool isIncome) {
    CategoryFormBottomSheet.show(
      context,
      isIncome: isIncome,
      onSubmit: (name) async {
        if (isIncome) {
          await context.read<IncomeCategoryCubit>().addCategory(name);
        } else {
          await context.read<ExpenseCategoryCubit>().addCategory(name);
        }
      },
    );
  }
}

class _IncomeCategoryTab extends StatelessWidget {
  const _IncomeCategoryTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<IncomeCategoryCubit, IncomeCategoryState>(
      builder: (context, state) {
        if (state is IncomeCategoriesLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is IncomeCategoriesError) {
          return Center(child: Text('Error: ${state.message}'));
        }

        if (state is IncomeCategoriesLoaded) {
          final categories = state.categories;
          if (categories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No income categories'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => CategoryConfigPage._showAddCategoryForm(context, true),
                    child: const Text('Add Category'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(category.name),
                  onTap: () => _showEditCategoryForm(context, category, true),
                ),
              );
            },
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  void _showEditCategoryForm(BuildContext context, dynamic category, bool isIncome) {
    if (isIncome) {
      final incomeCubit = context.read<IncomeCategoryCubit>();
      CategoryFormBottomSheet.show(
        context,
        isIncome: isIncome,
        category: category,
        onSubmit: (name) async {
          final updated = (category as IncomeCategory).copyWith(name: name);
          await incomeCubit.updateCategory(updated);
        },
        onDelete: () async {
          await incomeCubit.deleteCategory((category as IncomeCategory).id);
        },
      );
    } else {
      final expenseCubit = context.read<ExpenseCategoryCubit>();
      CategoryFormBottomSheet.show(
        context,
        isIncome: isIncome,
        category: category,
        onSubmit: (name) async {
          final updated = (category as ExpenseCategory).copyWith(name: name);
          await expenseCubit.updateCategory(updated);
        },
        onDelete: () async {
          await expenseCubit.deleteCategory((category as ExpenseCategory).id);
        },
      );
    }
  }

}

class _ExpenseCategoryTab extends StatelessWidget {
  const _ExpenseCategoryTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExpenseCategoryCubit, ExpenseCategoryState>(
      builder: (context, state) {
        if (state is ExpenseCategoriesLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is ExpenseCategoriesError) {
          return Center(child: Text('Error: ${state.message}'));
        }

        if (state is ExpenseCategoriesLoaded) {
          final categories = state.categories;
          if (categories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No expense categories'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => CategoryConfigPage._showAddCategoryForm(context, false),
                    child: const Text('Add Category'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(category.name),
                  onTap: () => _showEditCategoryForm(context, category, false),
                ),
              );
            },
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  void _showEditCategoryForm(BuildContext context, dynamic category, bool isIncome) {
    if (isIncome) {
      final incomeCubit = context.read<IncomeCategoryCubit>();
      CategoryFormBottomSheet.show(
        context,
        isIncome: isIncome,
        category: category,
        onSubmit: (name) async {
          final updated = (category as IncomeCategory).copyWith(name: name);
          await incomeCubit.updateCategory(updated);
        },
        onDelete: () async {
          await incomeCubit.deleteCategory((category as IncomeCategory).id);
        },
      );
    } else {
      final expenseCubit = context.read<ExpenseCategoryCubit>();
      CategoryFormBottomSheet.show(
        context,
        isIncome: isIncome,
        category: category,
        onSubmit: (name) async {
          final updated = (category as ExpenseCategory).copyWith(name: name);
          await expenseCubit.updateCategory(updated);
        },
        onDelete: () async {
          await expenseCubit.deleteCategory((category as ExpenseCategory).id);
        },
      );
    }
  }

}

