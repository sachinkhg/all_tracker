import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/design_tokens.dart';
import '../../domain/entities/investment_plan.dart';
import '../../domain/entities/plan_status.dart';
import '../../domain/entities/investment_component.dart';
import '../../domain/entities/income_category.dart';
import '../../domain/entities/expense_category.dart';
import '../../core/injection.dart';
import '../bloc/investment_component_cubit.dart';
import '../bloc/investment_component_state.dart';
import '../bloc/investment_plan_cubit.dart';
import '../bloc/income_category_cubit.dart';
import '../bloc/income_category_state.dart';
import '../bloc/expense_category_cubit.dart';
import '../bloc/expense_category_state.dart';
import 'plan_create_edit_page.dart';

/// Page for viewing investment plan details
class PlanDetailPage extends StatefulWidget {
  final InvestmentPlan plan;

  const PlanDetailPage({super.key, required this.plan});

  @override
  State<PlanDetailPage> createState() => _PlanDetailPageState();
}

class _PlanDetailPageState extends State<PlanDetailPage> {
  InvestmentPlan? _currentPlan;
  bool _planStatusChanged = false;

  @override
  void initState() {
    super.initState();
    _currentPlan = widget.plan;
  }

  Future<void> _loadPlan(BuildContext context) async {
    final cubit = context.read<InvestmentPlanCubit>();
    final updatedPlan = await cubit.loadPlanById(widget.plan.id);
    if (updatedPlan != null && mounted) {
      setState(() {
        _currentPlan = updatedPlan;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = _currentPlan ?? widget.plan;
    
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => createInvestmentComponentCubit()),
        BlocProvider(create: (_) => createInvestmentPlanCubit()),
        BlocProvider(create: (_) => createIncomeCategoryCubit()),
        BlocProvider(create: (_) => createExpenseCategoryCubit()),
      ],
      child: Builder(
        builder: (context) {
          // Load the latest plan data when the widget is built
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _loadPlan(context);
          });
          final cs = Theme.of(context).colorScheme;
          return PopScope(
            canPop: !_planStatusChanged,
            onPopInvoked: (didPop) {
              if (!didPop && _planStatusChanged) {
                // Prevent default pop and manually pop with result
                Navigator.of(context).pop(true);
              }
            },
            child: Scaffold(
            appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (_planStatusChanged) {
                Navigator.of(context).pop(true);
              } else {
                Navigator.of(context).pop();
              }
            },
          ),
          title: Text(plan.name),
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: AppGradients.appBar(cs),
            ),
          ),
          backgroundColor: Colors.transparent,
          foregroundColor: cs.onPrimary,
          iconTheme: IconThemeData(
            color: cs.brightness == Brightness.dark
                ? Colors.white.withValues(alpha: 0.95)
                : Colors.black87,
            opacity: 1.0,
          ),
          actionsIconTheme: IconThemeData(
            color: cs.brightness == Brightness.dark
                ? Colors.white.withValues(alpha: 0.95)
                : Colors.black87,
            opacity: 1.0,
          ),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: plan.isEditable ? 'Edit Plan' : 'Plan cannot be edited (${plan.status.displayName})',
              onPressed: plan.isEditable ? () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PlanCreateEditPage(plan: plan),
                  ),
                );
                // Reload plan data after returning from edit page
                if (mounted) {
                  await _loadPlan(context);
                }
              } : null,
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: 'Delete Plan',
              onPressed: () {
                final cubit = context.read<InvestmentPlanCubit>();
                _deletePlan(context, plan.id, cubit);
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              plan.name,
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                          _buildStatusChip(plan.status),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text('Total Income: ${_formatAmount(plan.totalIncome)}', style: const TextStyle(fontSize: 18)),
                      const SizedBox(height: 8),
                      Text('Total Expense: ${_formatAmount(plan.totalExpense)}', style: const TextStyle(fontSize: 18)),
                      // Show Available only when plan is in draft status
                      if (plan.status == PlanStatus.draft) ...[
                        const SizedBox(height: 8),
                        Text('Available: ${_formatAmount(plan.availableAmount)}', style: const TextStyle(fontSize: 20, color: Colors.green)),
                      ],
                      // Investment summary dashboard (shown after plan is approved)
                      if (plan.status == PlanStatus.approved || plan.status == PlanStatus.executed) ...[
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total Planned',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatAmount(plan.totalAllocated),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total Actual',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatAmount(plan.allocations.fold(0.0, (sum, a) => sum + (a.actualAmount ?? 0.0))),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
                      // Show Income and Show Expense buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _showIncomeBottomSheet(context, plan),
                              icon: const Icon(Icons.arrow_upward, size: 16),
                              label: const Text('Show Income', style: TextStyle(fontSize: 12)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                minimumSize: const Size(0, 32),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _showExpenseBottomSheet(context, plan),
                              icon: const Icon(Icons.arrow_downward, size: 16),
                              label: const Text('Show Expense', style: TextStyle(fontSize: 12)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                minimumSize: const Size(0, 32),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Status action buttons
                      if (plan.status == PlanStatus.draft) ...[
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _approvePlan(context, plan.id),
                            icon: const Icon(Icons.check_circle),
                            label: const Text('Approve Plan'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ] else if (plan.status == PlanStatus.approved) ...[
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _executePlan(context, plan.id),
                            icon: const Icon(Icons.play_circle),
                            label: const Text('Mark as Executed'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Allocations', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              BlocBuilder<InvestmentComponentCubit, InvestmentComponentState>(
                builder: (context, state) {
                  if (state is ComponentsLoaded) {
                    final components = state.components;
                    final canEditActual = plan.status == PlanStatus.approved; // Only allow editing when approved, not executed
                    final isReadOnly = plan.status == PlanStatus.executed; // Read-only when executed
                    final hasActualData = plan.allocations.any((a) => a.actualAmount != null);
                    
                    return Column(
                      children: plan.allocations.map((allocation) {
                        final component = components.firstWhere(
                          (c) => c.id == allocation.componentId,
                          orElse: () => InvestmentComponent(
                            id: allocation.componentId,
                            name: 'Unknown',
                            percentage: 0,
                            priority: 0,
                          ),
                        );
                        final hasActual = allocation.actualAmount != null;
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    if (canEditActual || isReadOnly)
                                      Checkbox(
                                        value: allocation.isCompleted,
                                        onChanged: isReadOnly ? null : (value) async {
                                          await context.read<InvestmentPlanCubit>().toggleAllocationCompletion(
                                            plan.id,
                                            allocation.componentId,
                                            value ?? false,
                                          );
                                          // Reload plan to reflect changes
                                          if (mounted) {
                                            await _loadPlan(context);
                                          }
                                        },
                                      ),
                                    Expanded(
                                      child: Text(
                                        component.name,
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                if (hasActualData || canEditActual || isReadOnly) ...[
                                  // Table format when actual data exists or can be edited
                                  Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Planned',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                            Text(
                                              _formatAmount(allocation.allocatedAmount),
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (hasActual || canEditActual || isReadOnly) ...[
                                        Expanded(
                                          flex: 2,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Actual',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                              if (canEditActual && !allocation.isCompleted)
                                                SizedBox(
                                                  width: double.infinity,
                                                  child: TextFormField(
                                                    initialValue: allocation.actualAmount?.toString() ?? '',
                                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                    decoration: InputDecoration(
                                                      hintText: '0.00',
                                                      isDense: true,
                                                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                                      border: OutlineInputBorder(
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                    ),
                                                    style: const TextStyle(fontSize: 16),
                                                    onChanged: (value) async {
                                                      final amount = double.tryParse(value);
                                                      if (amount != null && amount >= 0) {
                                                        await context.read<InvestmentPlanCubit>().updateAllocationActualAmount(
                                                          plan.id,
                                                          allocation.componentId,
                                                          amount,
                                                        );
                                                      } else if (value.isEmpty) {
                                                        await context.read<InvestmentPlanCubit>().updateAllocationActualAmount(
                                                          plan.id,
                                                          allocation.componentId,
                                                          null,
                                                        );
                                                      }
                                                      // Reload plan to reflect changes
                                                      if (mounted) {
                                                        await _loadPlan(context);
                                                      }
                                                    },
                                                  ),
                                                )
                                              else
                                                Text(
                                                  hasActual ? _formatAmount(allocation.actualAmount!) : '-',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ] else ...[
                                  // Simple display when no actual data and can't edit
                                  Text(
                                    'Planned: ${_formatAmount(allocation.allocatedAmount)}',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              if (plan.remainingUnallocated > 0) ...[
                const SizedBox(height: 16),
                Card(
                  color: Colors.orange[100],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Remaining Unallocated: ${_formatAmount(plan.remainingUnallocated)}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusChip(PlanStatus status) {
    Color backgroundColor;
    Color textColor;
    
    switch (status) {
      case PlanStatus.draft:
        backgroundColor = Colors.grey.shade300;
        textColor = Colors.grey.shade800;
        break;
      case PlanStatus.approved:
        backgroundColor = Colors.orange.shade200;
        textColor = Colors.orange.shade900;
        break;
      case PlanStatus.executed:
        backgroundColor = Colors.green.shade200;
        textColor = Colors.green.shade900;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
    );
  }

  void _approvePlan(BuildContext context, String planId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Approve Plan'),
        content: const Text('Are you sure you want to approve this plan? Once approved, the plan cannot be edited.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final cubit = context.read<InvestmentPlanCubit>();
              final success = await cubit.updatePlanStatus(planId, PlanStatus.approved);
              if (success && mounted) {
                _planStatusChanged = true;
                await _loadPlan(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Plan approved successfully')),
                  );
                }
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to approve plan')),
                );
              }
            },
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _executePlan(BuildContext context, String planId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Mark as Executed'),
        content: const Text('Are you sure you want to mark this plan as executed? Once executed, the plan cannot be edited.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final cubit = context.read<InvestmentPlanCubit>();
              final success = await cubit.updatePlanStatus(planId, PlanStatus.executed);
              if (success && mounted) {
                _planStatusChanged = true;
                await _loadPlan(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Plan marked as executed')),
                  );
                }
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to mark plan as executed')),
                );
              }
            },
            child: const Text('Mark as Executed'),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    return NumberFormat('#,##0.00', 'en_US').format(amount);
  }

  void _deletePlan(BuildContext context, String id, InvestmentPlanCubit cubit) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Plan'),
        content: const Text('Are you sure you want to delete this plan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              cubit.deletePlanById(id);
              Navigator.pop(dialogContext);
              Navigator.pop(context, true); // Return true to indicate plan was deleted
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showIncomeBottomSheet(BuildContext context, InvestmentPlan plan) {
    final incomeCubit = context.read<IncomeCategoryCubit>();
    incomeCubit.loadCategories();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => BlocProvider.value(
        value: incomeCubit,
        child: BlocBuilder<IncomeCategoryCubit, IncomeCategoryState>(
          builder: (context, state) {
            final categories = state is IncomeCategoriesLoaded ? state.categories : <IncomeCategory>[];
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Income Entries',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: plan.incomeEntries.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  'No income entries',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            )
                          : ListView.builder(
                              controller: scrollController,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: plan.incomeEntries.length,
                              itemBuilder: (context, index) {
                                final entry = plan.incomeEntries[index];
                                final category = categories.firstWhere(
                                  (c) => c.id == entry.categoryId,
                                  orElse: () => IncomeCategory(
                                    id: entry.categoryId,
                                    name: 'Unknown Category',
                                  ),
                                );
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    title: Text(category.name),
                                    trailing: Text(
                                      _formatAmount(entry.amount),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _showExpenseBottomSheet(BuildContext context, InvestmentPlan plan) {
    final expenseCubit = context.read<ExpenseCategoryCubit>();
    expenseCubit.loadCategories();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => BlocProvider.value(
        value: expenseCubit,
        child: BlocBuilder<ExpenseCategoryCubit, ExpenseCategoryState>(
          builder: (context, state) {
            final categories = state is ExpenseCategoriesLoaded ? state.categories : <ExpenseCategory>[];
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Expense Entries',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: plan.expenseEntries.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  'No expense entries',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            )
                          : ListView.builder(
                              controller: scrollController,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: plan.expenseEntries.length,
                              itemBuilder: (context, index) {
                                final entry = plan.expenseEntries[index];
                                final category = categories.firstWhere(
                                  (c) => c.id == entry.categoryId,
                                  orElse: () => ExpenseCategory(
                                    id: entry.categoryId,
                                    name: 'Unknown Category',
                                  ),
                                );
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    title: Text(category.name),
                                    trailing: Text(
                                      _formatAmount(entry.amount),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

