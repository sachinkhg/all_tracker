import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/design_tokens.dart';
import '../../core/injection.dart';
import '../../core/preferences_service.dart';
import '../../domain/entities/retirement_plan.dart';
import '../../domain/usecases/plan/calculate_retirement_plan.dart';
import '../bloc/retirement_plan_cubit.dart';
import '../widgets/retirement_input_field.dart';

/// Page for creating or editing a retirement plan
class RetirementPlanCreateEditPage extends StatefulWidget {
  final RetirementPlan? plan;

  const RetirementPlanCreateEditPage({super.key, this.plan});

  @override
  State<RetirementPlanCreateEditPage> createState() => _RetirementPlanCreateEditPageState();
}

class _RetirementPlanCreateEditPageState extends State<RetirementPlanCreateEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _retirementAgeController = TextEditingController();
  final _lifeExpectancyController = TextEditingController();
  final _preRetirementReturnRateController = TextEditingController();
  final _currentMonthlyExpensesController = TextEditingController();
  final _currentSavingsController = TextEditingController();
  final _inflationRateController = TextEditingController();
  final _postRetirementReturnRateController = TextEditingController();
  final _preRetirementReturnRatioVariationController = TextEditingController();
  final _monthlyExpensesVariationController = TextEditingController();

  DateTime? _dob;
  RetirementPlan? _calculatedPlan;
  bool _showResults = false;
  bool _useAdvanceDefaults = true;
  bool _isAdvanceInputExpanded = false;
  final _preferencesService = RetirementPreferencesService();
  final _calculateRetirementPlan = CalculateRetirementPlan();

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    if (widget.plan != null) {
      _nameController.text = widget.plan!.name;
      _dob = widget.plan!.dob;
      _retirementAgeController.text = widget.plan!.retirementAge.toString();
      _lifeExpectancyController.text = widget.plan!.lifeExpectancy.toString();
      _preRetirementReturnRateController.text = (widget.plan!.preRetirementReturnRate * 100).toString();
      _currentMonthlyExpensesController.text = widget.plan!.currentMonthlyExpenses.toString();
      _currentSavingsController.text = widget.plan!.currentSavings.toString();
      _inflationRateController.text = (widget.plan!.inflationRate * 100).toString();
      _postRetirementReturnRateController.text = (widget.plan!.postRetirementReturnRate * 100).toString();
      _preRetirementReturnRatioVariationController.text = widget.plan!.preRetirementReturnRatioVariation.toString();
      _monthlyExpensesVariationController.text = widget.plan!.monthlyExpensesVariation.toString();
      _useAdvanceDefaults = false;
      _calculatedPlan = widget.plan;
      _showResults = widget.plan!.monthlyExpensesAtRetirement != null;
    }
  }

  Future<void> _loadPreferences() async {
    await _preferencesService.init();
    if (widget.plan == null) {
      final defaults = _preferencesService.getDefaults();
      setState(() {
        _inflationRateController.text = (defaults['inflationRate']! * 100).toString();
        _postRetirementReturnRateController.text = (defaults['postRetirementReturnRate']! * 100).toString();
        _preRetirementReturnRatioVariationController.text = defaults['preRetirementReturnRatioVariation']!.toString();
        _monthlyExpensesVariationController.text = defaults['monthlyExpensesVariation']!.toString();
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(1990, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) {
      setState(() {
        _dob = picked;
      });
    }
  }

  void _calculate() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_dob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date of birth')),
      );
      return;
    }

    try {
      final now = DateTime.now();
      final plan = RetirementPlan(
        id: widget.plan?.id ?? '',
        name: _nameController.text,
        dob: _dob!,
        retirementAge: int.parse(_retirementAgeController.text),
        lifeExpectancy: int.parse(_lifeExpectancyController.text),
        inflationRate: double.parse(_inflationRateController.text) / 100,
        postRetirementReturnRate: double.parse(_postRetirementReturnRateController.text) / 100,
        preRetirementReturnRate: double.parse(_preRetirementReturnRateController.text) / 100,
        preRetirementReturnRatioVariation: double.parse(_preRetirementReturnRatioVariationController.text),
        monthlyExpensesVariation: double.parse(_monthlyExpensesVariationController.text),
        currentMonthlyExpenses: double.parse(_currentMonthlyExpensesController.text),
        currentSavings: double.parse(_currentSavingsController.text),
        createdAt: widget.plan?.createdAt ?? now,
        updatedAt: now,
      );

      final calculated = _calculateRetirementPlan(plan);
      setState(() {
        _calculatedPlan = calculated;
        _showResults = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error calculating: ${e.toString()}')),
      );
    }
  }

  Future<void> _savePlan(BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_dob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date of birth')),
      );
      return;
    }
    if (!_showResults) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please calculate before saving')),
      );
      return;
    }

    final cubit = context.read<RetirementPlanCubit>();
    final savedPlan = await cubit.savePlan(_calculatedPlan!);
    if (savedPlan != null && context.mounted) {
      Navigator.pop(context);
    }
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(amount);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _retirementAgeController.dispose();
    _lifeExpectancyController.dispose();
    _preRetirementReturnRateController.dispose();
    _currentMonthlyExpensesController.dispose();
    _currentSavingsController.dispose();
    _inflationRateController.dispose();
    _postRetirementReturnRateController.dispose();
    _preRetirementReturnRatioVariationController.dispose();
    _monthlyExpensesVariationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => createRetirementPlanCubit(),
      child: Builder(
        builder: (builderContext) {
          final cs = Theme.of(builderContext).colorScheme;
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
            ),
          body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Input Fields
                const Text('User Profile Inputs', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                RetirementInputField(
                  label: 'Name',
                  controller: _nameController,
                  validator: (value) => value?.isEmpty ?? true ? 'Please enter a name' : null,
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () => _selectDate(context),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date of Birth (DD/MM/YYYY)',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      _dob != null ? DateFormat('dd/MM/yyyy').format(_dob!) : 'Select date',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                RetirementInputField(
                  label: 'Retirement Age',
                  controller: _retirementAgeController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) => value?.isEmpty ?? true ? 'Please enter retirement age' : null,
                ),
                const SizedBox(height: 16),
                RetirementInputField(
                  label: 'Life Expectancy',
                  controller: _lifeExpectancyController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) => value?.isEmpty ?? true ? 'Please enter life expectancy' : null,
                ),
                const SizedBox(height: 16),
                RetirementInputField(
                  label: 'Pre-Retirement Return Rate (%)',
                  controller: _preRetirementReturnRateController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) => value?.isEmpty ?? true ? 'Please enter return rate' : null,
                ),
                const SizedBox(height: 16),
                RetirementInputField(
                  label: 'Current Monthly Expenses (₹)',
                  controller: _currentMonthlyExpensesController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                  validator: (value) => value?.isEmpty ?? true ? 'Please enter monthly expenses' : null,
                ),
                const SizedBox(height: 16),
                RetirementInputField(
                  label: 'Current Savings (₹)',
                  controller: _currentSavingsController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                  validator: (value) => value?.isEmpty ?? true ? 'Please enter current savings' : null,
                ),
                const SizedBox(height: 24),
                
                // Advance Input Fields
                Card(
                  child: ExpansionTile(
                    title: const Text(
                      'Advance Input',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text(
                      'You can override these values or use defaults from Advanced Settings',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    initiallyExpanded: _isAdvanceInputExpanded,
                    onExpansionChanged: (expanded) {
                      setState(() {
                        _isAdvanceInputExpanded = expanded;
                      });
                    },
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: const Text('Use default values from Advanced Settings'),
                                ),
                                const SizedBox(width: 8),
                                Switch(
                                  value: _useAdvanceDefaults,
                                  onChanged: (value) {
                                    setState(() {
                                      _useAdvanceDefaults = value;
                                      if (value) {
                                        _loadPreferences();
                                      }
                                    });
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            RetirementInputField(
                              label: 'Inflation Rate (%)',
                              controller: _inflationRateController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              enabled: !_useAdvanceDefaults,
                              validator: (value) => value?.isEmpty ?? true ? 'Please enter inflation rate' : null,
                            ),
                            const SizedBox(height: 16),
                            RetirementInputField(
                              label: 'Post-Retirement Return Rate (%)',
                              controller: _postRetirementReturnRateController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              enabled: !_useAdvanceDefaults,
                              validator: (value) => value?.isEmpty ?? true ? 'Please enter return rate' : null,
                            ),
                            const SizedBox(height: 16),
                            RetirementInputField(
                              label: 'Pre-Retirement Return Ratio Variation',
                              controller: _preRetirementReturnRatioVariationController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              enabled: !_useAdvanceDefaults,
                              validator: (value) => value?.isEmpty ?? true ? 'Please enter variation' : null,
                            ),
                            const SizedBox(height: 16),
                            RetirementInputField(
                              label: 'Monthly Expenses Variation',
                              controller: _monthlyExpensesVariationController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              enabled: !_useAdvanceDefaults,
                              validator: (value) => value?.isEmpty ?? true ? 'Please enter variation' : null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                ElevatedButton(
                  onPressed: _calculate,
                  child: const Text('Calculate'),
                ),
                const SizedBox(height: 24),
                
                // Results Section
                if (_showResults && _calculatedPlan != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Retirement Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      if (_calculatedPlan!.monthlyExpensesAtRetirement != null)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: const Text('Monthly Expenses at Retirement'),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    _formatCurrency(_calculatedPlan!.monthlyExpensesAtRetirement!),
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.end,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      if (_calculatedPlan!.totalCorpusNeeded != null)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: const Text('Total Corpus Needed'),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    _formatCurrency(_calculatedPlan!.totalCorpusNeeded!),
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.end,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                      const Text('Investment Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                      const SizedBox(height: 16),
                      if (_calculatedPlan!.corpusRequiredToBuild != null)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: const Text('Corpus Required to Build'),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    _formatCurrency(_calculatedPlan!.corpusRequiredToBuild!),
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.end,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      if (_calculatedPlan!.monthlyInvestment != null)
                        Card(
                          color: Colors.green.shade50,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: const Text('Monthly Investment'),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    _formatCurrency(_calculatedPlan!.monthlyInvestment!),
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                                    textAlign: TextAlign.end,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      if (_calculatedPlan!.yearlyInvestment != null)
                        Card(
                          color: Colors.green.shade50,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: const Text('Yearly Investment'),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    _formatCurrency(_calculatedPlan!.yearlyInvestment!),
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                                    textAlign: TextAlign.end,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                    ],
                  ),
                
                ElevatedButton(
                  onPressed: () => _savePlan(builderContext),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Save Plan'),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          ),
        );
        },
      ),
    );
  }
}

