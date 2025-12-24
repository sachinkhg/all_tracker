import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/design_tokens.dart';
import '../../domain/entities/investment_plan.dart';
import '../../domain/entities/plan_status.dart';
import '../../domain/entities/investment_component.dart';
import '../../domain/entities/component_allocation.dart';
import '../../domain/entities/income_category.dart';
import '../../domain/entities/expense_category.dart';
import '../../domain/entities/income_entry.dart';
import '../../domain/entities/expense_entry.dart';
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

  Future<void> _handleCheckboxChange(
    BuildContext context,
    String planId,
    String componentId,
    String componentName,
    double plannedAmount,
    double? actualAmount,
    bool newValue,
  ) async {
    log(
      'Handling checkbox change - Component: $componentName, ComponentId: $componentId, '
      'PlannedAmount: $plannedAmount, ActualAmount: $actualAmount, NewValue: $newValue',
      name: 'PlanDetailPage',
    );
    
    final success = await context.read<InvestmentPlanCubit>().toggleAllocationCompletion(
      planId,
      componentId,
      newValue,
    );
    
    log(
      'toggleAllocationCompletion result: $success for component: $componentName',
      name: 'PlanDetailPage',
    );
    
    if (mounted && success) {
      log('Reloading plan after successful toggle for component: $componentName', name: 'PlanDetailPage');
      await _loadPlan(context);
    } else if (!success) {
      log(
        'Toggle failed or widget not mounted. Mounted: $mounted, Success: $success, Component: $componentName',
        name: 'PlanDetailPage',
      );
    }
  }

  Future<void> _loadPlan(BuildContext context) async {
    log('Loading plan with id: ${widget.plan.id}', name: 'PlanDetailPage');
    final cubit = context.read<InvestmentPlanCubit>();
    final updatedPlan = await cubit.loadPlanById(widget.plan.id);
    if (updatedPlan != null && mounted) {
      log(
        'Plan loaded successfully. Plan status: ${updatedPlan.status}, '
        'Allocations count: ${updatedPlan.allocations.length}',
        name: 'PlanDetailPage',
      );
      // Log allocation completion statuses
      for (final allocation in updatedPlan.allocations) {
        log(
          'Allocation - ComponentId: ${allocation.componentId}, '
          'IsCompleted: ${allocation.isCompleted}, AllocatedAmount: ${allocation.allocatedAmount}, '
          'ActualAmount: ${allocation.actualAmount}',
          name: 'PlanDetailPage',
        );
      }
      setState(() {
        _currentPlan = updatedPlan;
      });
    } else {
      log(
        'Plan load failed or widget not mounted. UpdatedPlan is null: ${updatedPlan == null}, '
        'Mounted: $mounted',
        name: 'PlanDetailPage',
      );
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
          final textTheme = Theme.of(context).textTheme;
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
                              style: textTheme.titleLarge,
                            ),
                          ),
                          // _buildStatusChip(plan.status),
                        ],
                      ),
                      const SizedBox(height: 16),
                      RichText(
                        text: TextSpan(
                          style: textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                          children: [
                            const TextSpan(text: 'Total Income: '),
                            TextSpan(
                              text: _formatAmount(plan.totalIncome),
                              style: textTheme.bodyMedium?.copyWith(color: cs.onSurface),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      RichText(
                        text: TextSpan(
                          style: textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                          children: [
                            const TextSpan(text: 'Total Expense: '),
                            TextSpan(
                              text: _formatAmount(plan.totalExpense),
                              style: textTheme.bodyMedium?.copyWith(color: cs.onSurface),
                            ),
                          ],
                        ),
                      ),
                      // Show Available only when plan is in draft status
                      if (plan.status == PlanStatus.draft) ...[
                        const SizedBox(height: 8),
                        RichText(
                          text: TextSpan(
                            style: textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                            children: [
                              const TextSpan(text: 'Available: '),
                              TextSpan(
                                text: _formatAmount(plan.availableAmount),
                                style: textTheme.bodyMedium?.copyWith(color: Colors.green),
                              ),
                            ],
                          ),
                        ),
                      ],
                      // Investment summary dashboard (shown after plan is approved)
                      if (plan.status == PlanStatus.approved || plan.status == PlanStatus.executed) ...[
                        //const SizedBox(height: 16),
                        //const Divider(),
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
                                    style: textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatAmount(plan.totalAllocated),
                                    style: textTheme.bodyMedium?.copyWith(color: cs.onSurface),
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
                                    style: textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatAmount(plan.allocations.fold(0.0, (sum, a) => sum + (a.actualAmount ?? 0.0))),
                                    style: textTheme.bodyMedium?.copyWith(color: cs.onSurface),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      // Show Income and Show Expense buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _showIncomeBottomSheet(context, plan),
                              icon: const Icon(Icons.arrow_upward, size: 16),
                              label: Text('Show Income', style: textTheme.labelLarge),
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
                              label: Text('Show Expense', style: textTheme.labelLarge),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                minimumSize: const Size(0, 32),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
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
                            onPressed: () => _showActualAllocationBottomSheet(context, plan),
                            icon: const Icon(Icons.edit),
                            label: const Text('Add/Edit Actual Allocation'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
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
              const SizedBox(height: 8),
              Text('Allocations', style: textTheme.titleLarge),
              const SizedBox(height: 8),
              BlocBuilder<InvestmentComponentCubit, InvestmentComponentState>(
                builder: (context, state) {
                  if (state is ComponentsLoaded) {
                    final components = state.components;
                    final canEditActual = plan.status == PlanStatus.approved; // Only allow editing when approved, not executed
                    final isReadOnly = plan.status == PlanStatus.executed; // Read-only when executed
                    final hasActualData = plan.allocations.any((a) => a.actualAmount != null);
                    
                    // Sort components by priority
                    final sortedComponents = List<InvestmentComponent>.from(components)
                      ..sort((a, b) => a.priority.compareTo(b.priority));
                    
                    // Show bar chart for draft status
                    if (plan.status == PlanStatus.draft) {
                      return _buildBarChart(
                        context,
                        plan,
                        sortedComponents,
                        cs,
                        textTheme,
                      );
                    }
                    
                    // Show bar chart with actual amount input for approved status
                    if (plan.status == PlanStatus.approved) {
                      return _buildApprovedBarChart(
                        context,
                        plan,
                        sortedComponents,
                        cs,
                        textTheme,
                      );
                    }
                    
                    return Column(
                      children: sortedComponents.map((component) {
                        // Find allocation for this component, or create a default one with 0 allocated
                        final allocation = plan.allocations.firstWhere(
                          (a) => a.componentId == component.id,
                          orElse: () => ComponentAllocation(
                            componentId: component.id,
                            allocatedAmount: 0.0,
                            actualAmount: null,
                            isCompleted: false,
                          ),
                        );
                        final hasActual = allocation.actualAmount != null;
                        final hasAllocation = allocation.allocatedAmount > 0;
                        
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
                                        style: textTheme.bodyMedium,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                if (hasActualData || canEditActual || isReadOnly || hasAllocation) ...[
                                  // Table format when actual data exists, can be edited, or has allocation
                                  Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Planned',
                                              style: textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                                            ),
                                            Text(
                                              _formatAmount(allocation.allocatedAmount),
                                              style: textTheme.bodyMedium?.copyWith(
                                                color: hasAllocation ? cs.onSurface : Colors.grey.shade400,
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
                                                style: textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
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
                                                    style: textTheme.bodyMedium?.copyWith(color: cs.onSurface),
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
                                                  style: textTheme.bodyMedium?.copyWith(color: cs.onSurface),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ] else ...[
                                  // Simple display when no actual data and can't edit
                                  RichText(
                                    text: TextSpan(
                                      style: textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                                      children: [
                                        const TextSpan(text: 'Planned: '),
                                        TextSpan(
                                          text: _formatAmount(allocation.allocatedAmount),
                                          style: textTheme.bodyMedium?.copyWith(
                                            color: hasAllocation ? cs.onSurface : Colors.grey.shade400,
                                          ),
                                        ),
                                      ],
                                    ),
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
                  //color: Colors.orange[100],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: RichText(
                      text: TextSpan(
                        style: textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                        children: [
                          const TextSpan(text: 'Remaining Unallocated: '),
                          TextSpan(
                            text: _formatAmount(plan.remainingUnallocated),
                            style: textTheme.bodyMedium?.copyWith(color: cs.onSurface),
                          ),
                        ],
                      ),
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
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: textColor,
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

  Widget _buildBarChart(
    BuildContext context,
    InvestmentPlan plan,
    List<InvestmentComponent> components,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    // Prepare data for bar chart
    final chartData = components.map((component) {
      final allocation = plan.allocations.firstWhere(
        (a) => a.componentId == component.id,
        orElse: () => ComponentAllocation(
          componentId: component.id,
          allocatedAmount: 0.0,
          actualAmount: null,
          isCompleted: false,
        ),
      );
      return MapEntry(component, allocation.allocatedAmount);
    }).toList();

    // Find max value for scaling
    final amounts = chartData.map((e) => e.value).toList();
    final maxAmount = amounts.isEmpty
        ? 1.0
        : amounts.reduce((a, b) => a > b ? a : b);
    final maxAmountScaled = maxAmount == 0.0 ? 1.0 : maxAmount;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Chart bars
            ...chartData.map((entry) {
              final component = entry.key;
              final amount = entry.value;
              final percentage = maxAmountScaled > 0 ? (amount / maxAmountScaled) : 0.0;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            component.name,
                            style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                        ),
                        Text(
                          _formatAmount(amount),
                          style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Stack(
                        children: [
                          Container(
                            height: 24,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: percentage,
                            child: Container(
                              height: 24,
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildApprovedBarChart(
    BuildContext context,
    InvestmentPlan plan,
    List<InvestmentComponent> components,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    log(
      '_buildApprovedBarChart called with ${components.length} components',
      name: 'PlanDetailPage',
    );
    
    // Prepare data for bar chart with allocations
    final chartData = components.map((component) {
      final allocation = plan.allocations.firstWhere(
        (a) => a.componentId == component.id,
        orElse: () => ComponentAllocation(
          componentId: component.id,
          allocatedAmount: 0.0,
          actualAmount: null,
          isCompleted: false,
        ),
      );
      return MapEntry(component, allocation);
    }).toList();
    
    // Find max value for scaling - consider both planned and actual amounts
    final allAmounts = <double>[];
    for (final entry in chartData) {
      allAmounts.add(entry.value.allocatedAmount);
      if (entry.value.actualAmount != null) {
        allAmounts.add(entry.value.actualAmount!);
      }
    }
    final maxAmount = allAmounts.isEmpty
        ? 1.0
        : allAmounts.reduce((a, b) => a > b ? a : b);
    final maxAmountScaled = maxAmount == 0.0 ? 1.0 : maxAmount;

    // Filter to show only components with allocations or actual amounts
    final displayData = chartData.where((entry) {
      return entry.value.allocatedAmount > 0 || entry.value.actualAmount != null;
    }).toList();

    if (displayData.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              'No allocations to display. Use "Add/Edit Actual Allocation" to add actual amounts.',
              style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Comparison charts for each component
            ...displayData.map((entry) {
              final component = entry.key;
              final allocation = entry.value;
              final plannedAmount = allocation.allocatedAmount;
              final actualAmount = allocation.actualAmount ?? 0.0;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Component name
                    Text(
                      component.name,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Comparison chart
                    _buildComparisonChart(
                      plannedAmount,
                      actualAmount,
                      maxAmountScaled,
                      colorScheme,
                      textTheme,
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonChart(
    double plannedAmount,
    double actualAmount,
    double maxAmount,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    log(
      'Building comparison chart - PlannedAmount: $plannedAmount, ActualAmount: $actualAmount, MaxAmount: $maxAmount',
      name: 'PlanDetailPage',
    );
    
    // Calculate max considering both planned and actual for this specific component
    final componentMax = [plannedAmount, actualAmount].reduce((a, b) => a > b ? a : b);
    final maxForScaling = componentMax > 0 ? componentMax : (maxAmount > 0 ? maxAmount : 1.0);
    
    log(
      'Comparison chart scaling - ComponentMax: $componentMax, MaxForScaling: $maxForScaling',
      name: 'PlanDetailPage',
    );
    
    final plannedPercentage = maxForScaling > 0 ? (plannedAmount / maxForScaling).clamp(0.0, 1.0) : 0.0;
    final actualPercentage = maxForScaling > 0 ? (actualAmount / maxForScaling).clamp(0.0, 1.0) : 0.0;
    
    log(
      'Comparison chart percentages - PlannedPercentage: $plannedPercentage, ActualPercentage: $actualPercentage',
      name: 'PlanDetailPage',
    );
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Labels and values
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Planned',
                    style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                  Text(
                    _formatAmount(plannedAmount),
                    style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Actual',
                    style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                  Text(
                    _formatAmount(actualAmount),
                    style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Side-by-side comparison bars
        SizedBox(
          height: 48,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Planned bar
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Stack(
                        children: [
                          Container(
                            height: 24,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: plannedPercentage.clamp(0.0, 1.0),
                            child: Container(
                              height: 24,
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Actual bar
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Stack(
                        children: [
                          Container(
                            height: 24,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: actualPercentage.clamp(0.0, 1.0),
                            child: Container(
                              height: 24,
                              decoration: BoxDecoration(
                                color: colorScheme.secondary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
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
    final planCubit = context.read<InvestmentPlanCubit>();
    final originalContext = context;
    incomeCubit.loadCategories();
    
    final canEdit = plan.status == PlanStatus.approved || plan.status == PlanStatus.executed;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: incomeCubit),
          BlocProvider.value(value: planCubit),
        ],
        child: _IncomeBottomSheetContent(
          plan: plan,
          originalContext: originalContext,
          onLoadPlan: _loadPlan,
          canEdit: canEdit,
        ),
      ),
    );
  }

  void _showExpenseBottomSheet(BuildContext context, InvestmentPlan plan) {
    final expenseCubit = context.read<ExpenseCategoryCubit>();
    final planCubit = context.read<InvestmentPlanCubit>();
    final originalContext = context;
    expenseCubit.loadCategories();
    
    final canEdit = plan.status == PlanStatus.approved || plan.status == PlanStatus.executed;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: expenseCubit),
          BlocProvider.value(value: planCubit),
        ],
        child: _ExpenseBottomSheetContent(
          plan: plan,
          originalContext: originalContext,
          onLoadPlan: _loadPlan,
          canEdit: canEdit,
        ),
      ),
    );
  }

  void _showActualAllocationBottomSheet(BuildContext context, InvestmentPlan plan) {
    final componentCubit = context.read<InvestmentComponentCubit>();
    final planCubit = context.read<InvestmentPlanCubit>();
    final originalContext = context; // Capture original context for callbacks
    componentCubit.loadComponents();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: componentCubit),
          BlocProvider.value(value: planCubit),
        ],
        child: _ActualAllocationBottomSheetContent(
          plan: plan,
          originalContext: originalContext,
          onLoadPlan: _loadPlan,
        ),
      ),
    );
  }
}

/// StatefulWidget to manage TextEditingController lifecycle for actual allocation bottom sheet
class _ActualAllocationBottomSheetContent extends StatefulWidget {
  final InvestmentPlan plan;
  final BuildContext originalContext;
  final Future<void> Function(BuildContext) onLoadPlan;

  const _ActualAllocationBottomSheetContent({
    required this.plan,
    required this.originalContext,
    required this.onLoadPlan,
  });

  @override
  State<_ActualAllocationBottomSheetContent> createState() => _ActualAllocationBottomSheetContentState();
}

class _ActualAllocationBottomSheetContentState extends State<_ActualAllocationBottomSheetContent> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, double?> _initialValues = {};
  bool _controllersInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    if (_controllersInitialized) return;
    
    // Initialize controllers with current actual amounts
    for (final allocation in widget.plan.allocations) {
      final controller = TextEditingController(
        text: allocation.actualAmount?.toString() ?? '',
      );
      _controllers[allocation.componentId] = controller;
      _initialValues[allocation.componentId] = allocation.actualAmount;
    }
    _controllersInitialized = true;
  }

  void _ensureControllersForComponents(List<InvestmentComponent> components) {
    for (final component in components) {
      if (!_controllers.containsKey(component.id)) {
        _controllers[component.id] = TextEditingController(text: '');
        _initialValues[component.id] = null;
      }
    }
  }

  @override
  void dispose() {
    // Dispose all controllers when widget is disposed
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InvestmentComponentCubit, InvestmentComponentState>(
      builder: (context, state) {
        if (state is! ComponentsLoaded) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final components = state.components;
        // Sort components by priority
        final sortedComponents = List<InvestmentComponent>.from(components)
          ..sort((a, b) => a.priority.compareTo(b.priority));
        
        // Ensure controllers exist for all components
        _ensureControllersForComponents(sortedComponents);
        
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            final cs = Theme.of(context).colorScheme;
            final textTheme = Theme.of(context).textTheme;
            
            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cs.surface,
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
                      Text(
                        'Actual Allocation',
                        style: textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: sortedComponents.length,
                    itemBuilder: (context, index) {
                      final component = sortedComponents[index];
                      final allocation = widget.plan.allocations.firstWhere(
                        (a) => a.componentId == component.id,
                        orElse: () => ComponentAllocation(
                          componentId: component.id,
                          allocatedAmount: 0.0,
                          actualAmount: null,
                          isCompleted: false,
                        ),
                      );
                      final controller = _controllers[component.id]!;
                      final plannedAmount = allocation.allocatedAmount;
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                component.name,
                                style: textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              RichText(
                                text: TextSpan(
                                  style: textTheme.bodySmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                  children: [
                                    const TextSpan(text: 'Planned: '),
                                    TextSpan(
                                      text: _formatAmount(plannedAmount),
                                      style: textTheme.bodySmall?.copyWith(
                                        color: cs.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: controller,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  labelText: 'Actual Amount',
                                  hintText: '0.00',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                style: textTheme.bodyMedium?.copyWith(color: cs.onSurface),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    border: Border(
                      top: BorderSide(color: cs.outline.withValues(alpha: 0.2)),
                    ),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final planCubit = context.read<InvestmentPlanCubit>();
                        bool hasChanges = false;
                        
                        // Save all actual amounts
                        for (final component in sortedComponents) {
                          final controller = _controllers[component.id]!;
                          final text = controller.text.trim();
                          final amount = text.isEmpty 
                              ? null 
                              : double.tryParse(text);
                          
                          // Only update if value changed
                          if (amount != _initialValues[component.id] ||
                              (amount == null && _initialValues[component.id] != null)) {
                            await planCubit.updateAllocationActualAmount(
                              widget.plan.id,
                              component.id,
                              amount,
                            );
                            hasChanges = true;
                          }
                        }
                        
                        // Close bottom sheet
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                        
                        // Reload plan to reflect changes using original context
                        if (hasChanges && widget.originalContext.mounted) {
                          await widget.onLoadPlan(widget.originalContext);
                          if (widget.originalContext.mounted) {
                            ScaffoldMessenger.of(widget.originalContext).showSnackBar(
                              const SnackBar(content: Text('Actual allocations saved successfully')),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.save),
                      label: const Text('Save'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatAmount(double amount) {
    return NumberFormat('#,##0.00', 'en_US').format(amount);
  }
}

/// StatefulWidget to manage TextEditingController lifecycle for income bottom sheet
class _IncomeBottomSheetContent extends StatefulWidget {
  final InvestmentPlan plan;
  final BuildContext originalContext;
  final Future<void> Function(BuildContext) onLoadPlan;
  final bool canEdit;

  const _IncomeBottomSheetContent({
    required this.plan,
    required this.originalContext,
    required this.onLoadPlan,
    required this.canEdit,
  });

  @override
  State<_IncomeBottomSheetContent> createState() => _IncomeBottomSheetContentState();
}

class _IncomeBottomSheetContentState extends State<_IncomeBottomSheetContent> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, double> _initialValues = {};
  bool _controllersInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    if (_controllersInitialized) return;
    
    // Initialize controllers with current amounts
    for (final entry in widget.plan.incomeEntries) {
      final controller = TextEditingController(
        text: entry.amount.toString(),
      );
      _controllers[entry.categoryId] = controller;
      _initialValues[entry.categoryId] = entry.amount;
    }
    _controllersInitialized = true;
  }

  void _ensureControllersForCategories(List<IncomeCategory> categories) {
    for (final category in categories) {
      if (!_controllers.containsKey(category.id)) {
        // Find entry for this category or use 0.0
        final entry = widget.plan.incomeEntries.firstWhere(
          (e) => e.categoryId == category.id,
          orElse: () => IncomeEntry(
            id: '',
            categoryId: category.id,
            amount: 0.0,
          ),
        );
        _controllers[category.id] = TextEditingController(text: entry.amount.toString());
        _initialValues[category.id] = entry.amount;
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<IncomeCategoryCubit, IncomeCategoryState>(
      builder: (context, state) {
        if (state is! IncomeCategoriesLoaded) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final categories = state.categories;
        _ensureControllersForCategories(categories);
        
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            final cs = Theme.of(context).colorScheme;
            final textTheme = Theme.of(context).textTheme;
            
            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cs.surface,
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
                      Text(
                        'Income Entries',
                        style: textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final entry = widget.plan.incomeEntries.firstWhere(
                        (e) => e.categoryId == category.id,
                        orElse: () => IncomeEntry(
                          id: '',
                          categoryId: category.id,
                          amount: 0.0,
                        ),
                      );
                      final controller = _controllers[category.id]!;
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                category.name,
                                style: textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (widget.canEdit)
                                TextFormField(
                                  controller: controller,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: InputDecoration(
                                    labelText: 'Amount',
                                    hintText: '0.00',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  style: textTheme.bodyMedium?.copyWith(color: cs.onSurface),
                                )
                              else
                                Text(
                                  _formatAmount(entry.amount),
                                  style: textTheme.bodyMedium?.copyWith(color: cs.onSurface),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (widget.canEdit)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      border: Border(
                        top: BorderSide(color: cs.outline.withValues(alpha: 0.2)),
                      ),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final planCubit = context.read<InvestmentPlanCubit>();
                          bool hasChanges = false;
                          
                          // Save all amounts
                          for (final category in categories) {
                            final controller = _controllers[category.id]!;
                            final text = controller.text.trim();
                            final amount = double.tryParse(text) ?? 0.0;
                            
                            // Find entry for this category
                            IncomeEntry? existingEntry;
                            try {
                              existingEntry = widget.plan.incomeEntries.firstWhere(
                                (e) => e.categoryId == category.id,
                              );
                            } catch (e) {
                              existingEntry = null;
                            }
                            
                            // Only update if value changed
                            if (amount != _initialValues[category.id]) {
                              if (existingEntry != null) {
                                // Entry exists, update it
                                await planCubit.updateIncomeEntryAmount(
                                  widget.plan.id,
                                  existingEntry.id,
                                  amount,
                                );
                                hasChanges = true;
                              }
                              // If entry doesn't exist, skip it (shouldn't happen since all categories are saved)
                            }
                          }
                          
                          // Close bottom sheet
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                          
                          // Reload plan to reflect changes
                          if (hasChanges && widget.originalContext.mounted) {
                            await widget.onLoadPlan(widget.originalContext);
                            if (widget.originalContext.mounted) {
                              ScaffoldMessenger.of(widget.originalContext).showSnackBar(
                                const SnackBar(content: Text('Income amounts saved successfully')),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.save),
                        label: const Text('Save'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatAmount(double amount) {
    return NumberFormat('#,##0.00', 'en_US').format(amount);
  }
}

/// StatefulWidget to manage TextEditingController lifecycle for expense bottom sheet
class _ExpenseBottomSheetContent extends StatefulWidget {
  final InvestmentPlan plan;
  final BuildContext originalContext;
  final Future<void> Function(BuildContext) onLoadPlan;
  final bool canEdit;

  const _ExpenseBottomSheetContent({
    required this.plan,
    required this.originalContext,
    required this.onLoadPlan,
    required this.canEdit,
  });

  @override
  State<_ExpenseBottomSheetContent> createState() => _ExpenseBottomSheetContentState();
}

class _ExpenseBottomSheetContentState extends State<_ExpenseBottomSheetContent> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, double> _initialValues = {};
  bool _controllersInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    if (_controllersInitialized) return;
    
    // Initialize controllers with current amounts
    for (final entry in widget.plan.expenseEntries) {
      final controller = TextEditingController(
        text: entry.amount.toString(),
      );
      _controllers[entry.categoryId] = controller;
      _initialValues[entry.categoryId] = entry.amount;
    }
    _controllersInitialized = true;
  }

  void _ensureControllersForCategories(List<ExpenseCategory> categories) {
    for (final category in categories) {
      if (!_controllers.containsKey(category.id)) {
        // Find entry for this category or use 0.0
        final entry = widget.plan.expenseEntries.firstWhere(
          (e) => e.categoryId == category.id,
          orElse: () => ExpenseEntry(
            id: '',
            categoryId: category.id,
            amount: 0.0,
          ),
        );
        _controllers[category.id] = TextEditingController(text: entry.amount.toString());
        _initialValues[category.id] = entry.amount;
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExpenseCategoryCubit, ExpenseCategoryState>(
      builder: (context, state) {
        if (state is! ExpenseCategoriesLoaded) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final categories = state.categories;
        _ensureControllersForCategories(categories);
        
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            final cs = Theme.of(context).colorScheme;
            final textTheme = Theme.of(context).textTheme;
            
            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cs.surface,
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
                      Text(
                        'Expense Entries',
                        style: textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final entry = widget.plan.expenseEntries.firstWhere(
                        (e) => e.categoryId == category.id,
                        orElse: () => ExpenseEntry(
                          id: '',
                          categoryId: category.id,
                          amount: 0.0,
                        ),
                      );
                      final controller = _controllers[category.id]!;
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                category.name,
                                style: textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (widget.canEdit)
                                TextFormField(
                                  controller: controller,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: InputDecoration(
                                    labelText: 'Amount',
                                    hintText: '0.00',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  style: textTheme.bodyMedium?.copyWith(color: cs.onSurface),
                                )
                              else
                                Text(
                                  _formatAmount(entry.amount),
                                  style: textTheme.bodyMedium?.copyWith(color: cs.onSurface),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (widget.canEdit)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      border: Border(
                        top: BorderSide(color: cs.outline.withValues(alpha: 0.2)),
                      ),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final planCubit = context.read<InvestmentPlanCubit>();
                          bool hasChanges = false;
                          
                          // Save all amounts
                          for (final category in categories) {
                            final controller = _controllers[category.id]!;
                            final text = controller.text.trim();
                            final amount = double.tryParse(text) ?? 0.0;
                            
                            // Find entry for this category
                            ExpenseEntry? existingEntry;
                            try {
                              existingEntry = widget.plan.expenseEntries.firstWhere(
                                (e) => e.categoryId == category.id,
                              );
                            } catch (e) {
                              existingEntry = null;
                            }
                            
                            // Only update if value changed
                            if (amount != _initialValues[category.id]) {
                              if (existingEntry != null) {
                                // Entry exists, update it
                                await planCubit.updateExpenseEntryAmount(
                                  widget.plan.id,
                                  existingEntry.id,
                                  amount,
                                );
                                hasChanges = true;
                              }
                              // If entry doesn't exist, skip it (shouldn't happen since all categories are saved)
                            }
                          }
                          
                          // Close bottom sheet
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                          
                          // Reload plan to reflect changes
                          if (hasChanges && widget.originalContext.mounted) {
                            await widget.onLoadPlan(widget.originalContext);
                            if (widget.originalContext.mounted) {
                              ScaffoldMessenger.of(widget.originalContext).showSnackBar(
                                const SnackBar(content: Text('Expense amounts saved successfully')),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.save),
                        label: const Text('Save'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatAmount(double amount) {
    return NumberFormat('#,##0.00', 'en_US').format(amount);
  }
}

