import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/design_tokens.dart';
import '../../core/injection.dart';
import '../../core/constants.dart';
import '../bloc/investment_plan_cubit.dart';
import '../bloc/income_category_cubit.dart';
import '../bloc/income_category_state.dart';
import '../bloc/expense_category_cubit.dart';
import '../bloc/expense_category_state.dart';
import '../../domain/entities/investment_plan.dart';
import '../../domain/entities/income_entry.dart';
import '../../domain/entities/expense_entry.dart';
import '../../domain/entities/income_category.dart';
import '../../domain/entities/expense_category.dart';
import 'plan_detail_page.dart';
import '../widgets/entry_form_bottom_sheet.dart';

/// Page for creating or editing an investment plan
class PlanCreateEditPage extends StatelessWidget {
  final InvestmentPlan? plan;

  const PlanCreateEditPage({super.key, this.plan});

  static String formatAmount(double amount) {
    return NumberFormat('#,##0.00', 'en_US').format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => createInvestmentPlanCubit()),
        BlocProvider(create: (_) => createIncomeCategoryCubit()),
        BlocProvider(create: (_) => createExpenseCategoryCubit()),
      ],
      child: _PlanCreateEditPageView(plan: plan),
    );
  }
}

class _PlanCreateEditPageView extends StatefulWidget {
  final InvestmentPlan? plan;

  const _PlanCreateEditPageView({this.plan});

  @override
  State<_PlanCreateEditPageView> createState() => _PlanCreateEditPageState();
}

class _PlanCreateEditPageState extends State<_PlanCreateEditPageView> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String _duration;
  late String _period;
  final List<IncomeEntry> _incomeEntries = [];
  final List<ExpenseEntry> _expenseEntries = [];

  @override
  void initState() {
    super.initState();
    if (widget.plan != null) {
      _name = widget.plan!.name;
      _duration = widget.plan!.duration;
      _period = widget.plan!.period;
      _incomeEntries.addAll(widget.plan!.incomeEntries);
      _expenseEntries.addAll(widget.plan!.expenseEntries);
    } else {
      _name = '';
      _duration = durationOptions[0];
      _period = DateFormat('MMM yyyy').format(DateTime.now());
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.plan == null ? 'Create Plan' : 'Edit Plan'),
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
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  initialValue: _name,
                  decoration: const InputDecoration(labelText: 'Plan Name'),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Please enter a name' : null,
                  onSaved: (value) => _name = value ?? '',
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _duration,
                  decoration: const InputDecoration(labelText: 'Duration'),
                  items: durationOptions
                      .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                      .toList(),
                  onChanged: (value) => setState(() => _duration = value!),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: _period,
                  decoration: const InputDecoration(labelText: 'Period (e.g., Nov 2025)'),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Please enter a period' : null,
                  onSaved: (value) => _period = value ?? '',
                ),
                const SizedBox(height: 24),
                const Text('Income Entries', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _IncomeEntriesSection(
                  entries: _incomeEntries,
                  onAdd: (entry) => setState(() => _incomeEntries.add(entry)),
                  onUpdate: (index, entry) => setState(() => _incomeEntries[index] = entry),
                  onRemove: (index) => setState(() => _incomeEntries.removeAt(index)),
                ),
                const SizedBox(height: 24),
                const Text('Expense Entries', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _ExpenseEntriesSection(
                  entries: _expenseEntries,
                  onAdd: (entry) => setState(() => _expenseEntries.add(entry)),
                  onUpdate: (index, entry) => setState(() => _expenseEntries[index] = entry),
                  onRemove: (index) => setState(() => _expenseEntries.removeAt(index)),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => _savePlan(context),
                  child: const Text('Save Plan'),
                ),
              ],
            ),
          ),
        ),
      );
  }

  Future<void> _savePlan(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final savedPlan = await context.read<InvestmentPlanCubit>().savePlan(
            name: _name,
            duration: _duration,
            period: _period,
            incomeEntries: _incomeEntries,
            expenseEntries: _expenseEntries,
            planId: widget.plan?.id,
          );
      
      if (savedPlan != null && context.mounted) {
        // If editing, pop back to detail page (which will reload)
        // If creating, navigate to detail page
        if (widget.plan != null) {
          // Editing: pop back to detail page, it will reload automatically
          Navigator.pop(context, true);
        } else {
          // Creating: navigate to detail page
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => PlanDetailPage(plan: savedPlan),
            ),
          );
        }
      } else if (context.mounted) {
        // If save failed, just pop
        Navigator.pop(context);
      }
    }
  }
}

class _IncomeEntriesSection extends StatelessWidget {
  final List<IncomeEntry> entries;
  final Function(IncomeEntry) onAdd;
  final Function(int, IncomeEntry) onUpdate;
  final Function(int) onRemove;

  const _IncomeEntriesSection({
    required this.entries,
    required this.onAdd,
    required this.onUpdate,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<IncomeCategoryCubit, IncomeCategoryState>(
      builder: (context, state) {
        final categories = state is IncomeCategoriesLoaded ? state.categories : <IncomeCategory>[];
        return Column(
          children: [
            ...entries.asMap().entries.map((entry) {
              final index = entry.key;
              final incomeEntry = entry.value;
              final category = categories.firstWhere(
                (c) => c.id == incomeEntry.categoryId,
                orElse: () => categories.isNotEmpty 
                    ? categories.first 
                    : IncomeCategory(id: incomeEntry.categoryId, name: 'Unknown Category'),
              );
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(category.name),
                  subtitle: Text('Amount: ${PlanCreateEditPage.formatAmount(incomeEntry.amount)}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => onRemove(index),
                  ),
                  onTap: () => _showEntryForm(
                    context,
                    true,
                    categories,
                    incomeEntry: incomeEntry,
                    onSave: (categoryId, amount) async {
                      // When editing, this is called for:
                      // 1. The original category (if it still has a value) - handled separately
                      // 2. Other categories with values - these are new entries
                      if (categoryId == incomeEntry.categoryId) {
                        // Original category - update the entry
                        final updated = IncomeEntry(
                          id: incomeEntry.id,
                          categoryId: categoryId,
                          amount: amount,
                        );
                        onUpdate(index, updated);
                      } else {
                        // New category - add as new entry
                        onAdd(IncomeEntry(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          categoryId: categoryId,
                          amount: amount,
                        ));
                      }
                    },
                    onRemoveEntry: () => onRemove(index),
                  ),
                ),
              );
            }),
            ElevatedButton.icon(
              onPressed: () => _showEntryForm(
                context,
                true,
                categories,
                existingIncomeEntries: entries,
                onSave: (categoryId, amount) async {
                  // Check if entry already exists for this category
                  final existingIndex = entries.indexWhere((e) => e.categoryId == categoryId);
                  if (existingIndex >= 0) {
                    // Update existing entry
                    onUpdate(existingIndex, IncomeEntry(
                      id: entries[existingIndex].id,
                      categoryId: categoryId,
                      amount: amount,
                    ));
                  } else {
                    // Add new entry
                    onAdd(IncomeEntry(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      categoryId: categoryId,
                      amount: amount,
                    ));
                  }
                },
              ),
              icon: const Icon(Icons.add),
              label: const Text('Add Income'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEntryForm(
    BuildContext context,
    bool isIncome,
    List<dynamic> categories, {
    IncomeEntry? incomeEntry,
    ExpenseEntry? expenseEntry,
    List<IncomeEntry>? existingIncomeEntries,
    List<ExpenseEntry>? existingExpenseEntries,
    required Future<void> Function(String categoryId, double amount) onSave,
    Future<void> Function()? onRemoveEntry,
  }) async {
    await EntryFormBottomSheet.show(
      context,
      isIncome: isIncome,
      categories: categories,
      incomeEntry: incomeEntry,
      expenseEntry: expenseEntry,
      existingIncomeEntries: existingIncomeEntries,
      existingExpenseEntries: existingExpenseEntries,
      onSubmit: onSave,
      onRemoveEntry: onRemoveEntry,
    );
  }
}

class _ExpenseEntriesSection extends StatelessWidget {
  final List<ExpenseEntry> entries;
  final Function(ExpenseEntry) onAdd;
  final Function(int, ExpenseEntry) onUpdate;
  final Function(int) onRemove;

  const _ExpenseEntriesSection({
    required this.entries,
    required this.onAdd,
    required this.onUpdate,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExpenseCategoryCubit, ExpenseCategoryState>(
      builder: (context, state) {
        final categories = state is ExpenseCategoriesLoaded ? state.categories : <ExpenseCategory>[];
        return Column(
          children: [
            ...entries.asMap().entries.map((entry) {
              final index = entry.key;
              final expenseEntry = entry.value;
              final category = categories.firstWhere(
                (c) => c.id == expenseEntry.categoryId,
                orElse: () => categories.isNotEmpty 
                    ? categories.first 
                    : ExpenseCategory(id: expenseEntry.categoryId, name: 'Unknown Category'),
              );
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(category.name),
                  subtitle: Text('Amount: ${PlanCreateEditPage.formatAmount(expenseEntry.amount)}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => onRemove(index),
                  ),
                  onTap: () => _showEntryForm(
                    context,
                    false,
                    categories,
                    expenseEntry: expenseEntry,
                    onSave: (categoryId, amount) async {
                      // When editing, this is called for:
                      // 1. The original category (if it still has a value) - handled separately
                      // 2. Other categories with values - these are new entries
                      if (categoryId == expenseEntry.categoryId) {
                        // Original category - update the entry
                        final updated = ExpenseEntry(
                          id: expenseEntry.id,
                          categoryId: categoryId,
                          amount: amount,
                        );
                        onUpdate(index, updated);
                      } else {
                        // New category - add as new entry
                        onAdd(ExpenseEntry(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          categoryId: categoryId,
                          amount: amount,
                        ));
                      }
                    },
                    onRemoveEntry: () => onRemove(index),
                  ),
                ),
              );
            }),
            ElevatedButton.icon(
              onPressed: () => _showEntryForm(
                context,
                false,
                categories,
                existingExpenseEntries: entries,
                onSave: (categoryId, amount) async {
                  // Check if entry already exists for this category
                  final existingIndex = entries.indexWhere((e) => e.categoryId == categoryId);
                  if (existingIndex >= 0) {
                    // Update existing entry
                    onUpdate(existingIndex, ExpenseEntry(
                      id: entries[existingIndex].id,
                      categoryId: categoryId,
                      amount: amount,
                    ));
                  } else {
                    // Add new entry
                    onAdd(ExpenseEntry(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      categoryId: categoryId,
                      amount: amount,
                    ));
                  }
                },
              ),
              icon: const Icon(Icons.add),
              label: const Text('Add Expense'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEntryForm(
    BuildContext context,
    bool isIncome,
    List<dynamic> categories, {
    IncomeEntry? incomeEntry,
    ExpenseEntry? expenseEntry,
    List<IncomeEntry>? existingIncomeEntries,
    List<ExpenseEntry>? existingExpenseEntries,
    required Future<void> Function(String categoryId, double amount) onSave,
    Future<void> Function()? onRemoveEntry,
  }) async {
    await EntryFormBottomSheet.show(
      context,
      isIncome: isIncome,
      categories: categories,
      incomeEntry: incomeEntry,
      expenseEntry: expenseEntry,
      existingIncomeEntries: existingIncomeEntries,
      existingExpenseEntries: existingExpenseEntries,
      onSubmit: onSave,
      onRemoveEntry: onRemoveEntry,
    );
  }
}

