import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/design_tokens.dart';
import '../../core/injection.dart';
import '../../domain/entities/retirement_plan.dart';
import '../bloc/retirement_plan_cubit.dart';
import 'retirement_plan_create_edit_page.dart';

/// Page for viewing retirement plan details
class RetirementPlanDetailPage extends StatefulWidget {
  final RetirementPlan plan;

  const RetirementPlanDetailPage({super.key, required this.plan});

  @override
  State<RetirementPlanDetailPage> createState() => _RetirementPlanDetailPageState();
}

class _RetirementPlanDetailPageState extends State<RetirementPlanDetailPage> {
  RetirementPlan? _currentPlan;

  @override
  void initState() {
    super.initState();
    _currentPlan = widget.plan;
  }

  Future<void> _loadPlan(BuildContext context) async {
    final cubit = context.read<RetirementPlanCubit>();
    final updatedPlan = await cubit.loadPlanById(widget.plan.id);
    if (updatedPlan != null && mounted) {
      setState(() {
        _currentPlan = updatedPlan;
      });
    }
  }

  Future<void> _deletePlan(BuildContext context, String id, RetirementPlanCubit cubit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Plan'),
        content: const Text('Are you sure you want to delete this retirement plan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await cubit.deletePlanById(id);
      if (context.mounted) {
        Navigator.pop(context, true); // Return true to indicate plan was deleted
      }
    }
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(amount);
  }

  String _formatPercentage(double rate) {
    return '${(rate * 100).toStringAsFixed(2)}%';
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final plan = _currentPlan ?? widget.plan;
    final cs = Theme.of(context).colorScheme;
    
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => createRetirementPlanCubit()),
      ],
      child: Builder(
        builder: (context) {
          // Load the latest plan data when the widget is built
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _loadPlan(context);
          });
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
                  tooltip: 'Edit Plan',
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RetirementPlanCreateEditPage(plan: plan),
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
                    final cubit = context.read<RetirementPlanCubit>();
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
                  // Input Fields Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('User Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          _DetailRow(label: 'Name', value: plan.name),
                          const SizedBox(height: 8),
                          _DetailRow(label: 'Date of Birth', value: _formatDate(plan.dob)),
                          const SizedBox(height: 8),
                          _DetailRow(label: 'Retirement Age', value: '${plan.retirementAge} years'),
                          const SizedBox(height: 8),
                          _DetailRow(label: 'Life Expectancy', value: '${plan.lifeExpectancy} years'),
                          const SizedBox(height: 8),
                          _DetailRow(label: 'Pre-Retirement Return Rate', value: _formatPercentage(plan.preRetirementReturnRate)),
                          const SizedBox(height: 8),
                          _DetailRow(label: 'Current Monthly Expenses', value: _formatCurrency(plan.currentMonthlyExpenses)),
                          const SizedBox(height: 8),
                          _DetailRow(label: 'Current Savings', value: _formatCurrency(plan.currentSavings)),
                          const SizedBox(height: 8),
                          _DetailRow(label: 'Inflation Rate', value: _formatPercentage(plan.inflationRate)),
                          const SizedBox(height: 8),
                          _DetailRow(label: 'Post-Retirement Return Rate', value: _formatPercentage(plan.postRetirementReturnRate)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Output Fields Section
                  if (plan.monthlyExpensesAtRetirement != null || plan.totalCorpusNeeded != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Retirement Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            if (plan.monthlyExpensesAtRetirement != null)
                              _DetailRow(
                                label: 'Monthly Expenses at Retirement',
                                value: _formatCurrency(plan.monthlyExpensesAtRetirement!),
                              ),
                            const SizedBox(height: 8),
                            if (plan.totalCorpusNeeded != null)
                              _DetailRow(
                                label: 'Total Corpus Needed',
                                value: _formatCurrency(plan.totalCorpusNeeded!),
                              ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  
                  // Final Output Fields Section
                  if (plan.corpusRequiredToBuild != null || plan.monthlyInvestment != null || plan.yearlyInvestment != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Investment Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                            const SizedBox(height: 16),
                            if (plan.corpusRequiredToBuild != null)
                              _DetailRow(
                                label: 'Corpus Required to Build',
                                value: _formatCurrency(plan.corpusRequiredToBuild!),
                                valueStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            const SizedBox(height: 8),
                            if (plan.monthlyInvestment != null)
                              _DetailRow(
                                label: 'Monthly Investment',
                                value: _formatCurrency(plan.monthlyInvestment!),
                                valueStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                              ),
                            const SizedBox(height: 8),
                            if (plan.yearlyInvestment != null)
                              _DetailRow(
                                label: 'Yearly Investment',
                                value: _formatCurrency(plan.yearlyInvestment!),
                                valueStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? valueStyle;

  const _DetailRow({
    required this.label,
    required this.value,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: valueStyle ?? const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

