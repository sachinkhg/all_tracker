import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/design_tokens.dart';
import '../../core/preferences_service.dart';
import '../../core/constants.dart';
import '../widgets/retirement_input_field.dart';

/// Page for configuring advanced retirement planning default settings
class RetirementAdvanceSettingsPage extends StatefulWidget {
  const RetirementAdvanceSettingsPage({super.key});

  @override
  State<RetirementAdvanceSettingsPage> createState() => _RetirementAdvanceSettingsPageState();
}

class _RetirementAdvanceSettingsPageState extends State<RetirementAdvanceSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _inflationRateController = TextEditingController();
  final _postRetirementReturnRateController = TextEditingController();
  final _preRetirementReturnRatioVariationController = TextEditingController();
  final _monthlyExpensesVariationController = TextEditingController();

  final _preferencesService = RetirementPreferencesService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDefaults();
  }

  Future<void> _loadDefaults() async {
    await _preferencesService.init();
    final defaults = _preferencesService.getDefaults();
    setState(() {
      _inflationRateController.text = (defaults['inflationRate']! * 100).toString();
      _postRetirementReturnRateController.text = (defaults['postRetirementReturnRate']! * 100).toString();
      _preRetirementReturnRatioVariationController.text = defaults['preRetirementReturnRatioVariation']!.toString();
      _monthlyExpensesVariationController.text = defaults['monthlyExpensesVariation']!.toString();
      _isLoading = false;
    });
  }

  Future<void> _saveDefaults() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      await _preferencesService.saveDefaults(
        inflationRate: double.parse(_inflationRateController.text) / 100,
        postRetirementReturnRate: double.parse(_postRetirementReturnRateController.text) / 100,
        preRetirementReturnRatioVariation: double.parse(_preRetirementReturnRatioVariationController.text),
        monthlyExpensesVariation: double.parse(_monthlyExpensesVariationController.text),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving settings: ${e.toString()}')),
        );
      }
    }
  }

  void _resetToDefaults() {
    setState(() {
      _inflationRateController.text = (defaultInflationRate * 100).toString();
      _postRetirementReturnRateController.text = (defaultPostRetirementReturnRate * 100).toString();
      _preRetirementReturnRatioVariationController.text = defaultPreRetirementReturnRatioVariation.toString();
      _monthlyExpensesVariationController.text = defaultMonthlyExpensesVariation.toString();
    });
  }

  @override
  void dispose() {
    _inflationRateController.dispose();
    _postRetirementReturnRateController.dispose();
    _preRetirementReturnRatioVariationController.dispose();
    _monthlyExpensesVariationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Settings'),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Default Advance Input Settings',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'These values will be used as defaults when creating new retirement plans. You can override them for individual plans.',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    RetirementInputField(
                      label: 'Inflation Rate (%)',
                      hint: 'Default: ${(defaultInflationRate * 100).toStringAsFixed(2)}%',
                      controller: _inflationRateController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) => value?.isEmpty ?? true ? 'Please enter inflation rate' : null,
                    ),
                    const SizedBox(height: 16),
                    RetirementInputField(
                      label: 'Post-Retirement Return Rate (%)',
                      hint: 'Default: ${(defaultPostRetirementReturnRate * 100).toStringAsFixed(2)}%',
                      controller: _postRetirementReturnRateController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) => value?.isEmpty ?? true ? 'Please enter return rate' : null,
                    ),
                    const SizedBox(height: 16),
                    RetirementInputField(
                      label: 'Pre-Retirement Return Ratio Variation',
                      hint: 'Default: ${defaultPreRetirementReturnRatioVariation.toString()}',
                      controller: _preRetirementReturnRatioVariationController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) => value?.isEmpty ?? true ? 'Please enter variation' : null,
                    ),
                    const SizedBox(height: 16),
                    RetirementInputField(
                      label: 'Monthly Expenses Variation',
                      hint: 'Default: ${defaultMonthlyExpensesVariation.toString()}',
                      controller: _monthlyExpensesVariationController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) => value?.isEmpty ?? true ? 'Please enter variation' : null,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _resetToDefaults,
                            child: const Text('Reset to Defaults'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _saveDefaults,
                            child: const Text('Save Settings'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

