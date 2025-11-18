import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/design_tokens.dart';
import '../../domain/entities/investment_plan.dart';
import '../../domain/entities/investment_component.dart';
import '../../core/injection.dart';
import '../bloc/investment_component_cubit.dart';
import '../bloc/investment_component_state.dart';
import '../bloc/investment_plan_cubit.dart';
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
      ],
      child: Builder(
        builder: (context) {
          // Load the latest plan data when the widget is built
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _loadPlan(context);
          });
          final cs = Theme.of(context).colorScheme;
          return Scaffold(
            appBar: AppBar(
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
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Edit Plan',
              onPressed: () async {
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
              },
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
                      Text('Duration: ${plan.duration}', style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 8),
                      Text('Period: ${plan.period}', style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 16),
                      Text('Total Income: ${_formatAmount(plan.totalIncome)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Total Expense: ${_formatAmount(plan.totalExpense)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Available: ${_formatAmount(plan.availableAmount)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
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
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(component.name),
                            //subtitle: Text('${_formatAmount(allocation.allocatedAmount)} (${component.percentage}%)'),
                            trailing: Text(_formatAmount(allocation.allocatedAmount), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
          );
        },
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
}

