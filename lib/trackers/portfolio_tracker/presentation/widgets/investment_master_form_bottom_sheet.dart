// lib/trackers/portfolio_tracker/presentation/widgets/investment_master_form_bottom_sheet.dart
// Form bottom sheet for creating/editing investment master

import 'package:flutter/material.dart';
import '../../domain/entities/investment_master.dart';
import '../../domain/entities/investment_category.dart';
import '../../domain/entities/investment_tracking_type.dart';
import '../../domain/entities/investment_currency.dart';
import '../../domain/entities/risk_factor.dart';
import '../../../../widgets/bottom_sheet_helpers.dart';

class InvestmentMasterFormBottomSheet extends StatefulWidget {
  final InvestmentMaster? investmentMaster;
  final Future<void> Function({
    required String shortName,
    required String name,
    required InvestmentCategory investmentCategory,
    required InvestmentTrackingType investmentTrackingType,
    required InvestmentCurrency investmentCurrency,
    required RiskFactor riskFactor,
  }) onSubmit;
  final Future<void> Function()? onDelete;
  final String title;

  const InvestmentMasterFormBottomSheet({
    super.key,
    this.investmentMaster,
    required this.onSubmit,
    this.onDelete,
    required this.title,
  });

  static Future<void> show(
    BuildContext context, {
    InvestmentMaster? investmentMaster,
    required Future<void> Function({
      required String shortName,
      required String name,
      required InvestmentCategory investmentCategory,
      required InvestmentTrackingType investmentTrackingType,
      required InvestmentCurrency investmentCurrency,
      required RiskFactor riskFactor,
    }) onSubmit,
    Future<void> Function()? onDelete,
    String title = 'Create Investment',
  }) {
    return showAppBottomSheet<void>(
      context,
      InvestmentMasterFormBottomSheet(
        investmentMaster: investmentMaster,
        onSubmit: onSubmit,
        onDelete: onDelete,
        title: title,
      ),
    );
  }

  @override
  State<InvestmentMasterFormBottomSheet> createState() => _InvestmentMasterFormBottomSheetState();
}

class _InvestmentMasterFormBottomSheetState extends State<InvestmentMasterFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _shortNameController;
  late final TextEditingController _nameController;
  InvestmentCategory? _selectedCategory;
  InvestmentTrackingType? _selectedTrackingType;
  InvestmentCurrency? _selectedCurrency;
  RiskFactor? _selectedRiskFactor;

  @override
  void initState() {
    super.initState();
    _shortNameController = TextEditingController(
      text: widget.investmentMaster?.shortName ?? '',
    );
    _nameController = TextEditingController(
      text: widget.investmentMaster?.name ?? '',
    );
    _selectedCategory = widget.investmentMaster?.investmentCategory;
    _selectedTrackingType = widget.investmentMaster?.investmentTrackingType;
    _selectedCurrency = widget.investmentMaster?.investmentCurrency;
    _selectedRiskFactor = widget.investmentMaster?.riskFactor;
  }

  @override
  void dispose() {
    _shortNameController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategory == null ||
          _selectedTrackingType == null ||
          _selectedCurrency == null ||
          _selectedRiskFactor == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all required fields')),
        );
        return;
      }

      await widget.onSubmit(
        shortName: _shortNameController.text.trim(),
        name: _nameController.text.trim(),
        investmentCategory: _selectedCategory!,
        investmentTrackingType: _selectedTrackingType!,
        investmentCurrency: _selectedCurrency!,
        riskFactor: _selectedRiskFactor!,
      );

      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (widget.onDelete != null)
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          await widget.onDelete!();
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                // Short Name field
                TextFormField(
                  controller: _shortNameController,
                  decoration: const InputDecoration(
                    labelText: 'Short Name *',
                    hintText: 'e.g., AAPL, GOOGL',
                  ),
                  textCapitalization: TextCapitalization.characters,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a short name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Name field
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name *',
                    hintText: 'Full name or description',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Investment Category dropdown
                DropdownButtonFormField<InvestmentCategory>(
                  initialValue: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category *',
                  ),
                  items: InvestmentCategory.values.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a category';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Tracking Type dropdown
                DropdownButtonFormField<InvestmentTrackingType>(
                  initialValue: _selectedTrackingType,
                  decoration: const InputDecoration(
                    labelText: 'Tracking Type *',
                  ),
                  items: InvestmentTrackingType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedTrackingType = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a tracking type';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Currency dropdown
                DropdownButtonFormField<InvestmentCurrency>(
                  initialValue: _selectedCurrency,
                  decoration: const InputDecoration(
                    labelText: 'Currency *',
                  ),
                  items: InvestmentCurrency.values.map((currency) {
                    return DropdownMenuItem(
                      value: currency,
                      child: Text(currency.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCurrency = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a currency';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Risk Factor dropdown
                DropdownButtonFormField<RiskFactor>(
                  initialValue: _selectedRiskFactor,
                  decoration: const InputDecoration(
                    labelText: 'Risk Factor *',
                  ),
                  items: RiskFactor.values.map((risk) {
                    return DropdownMenuItem(
                      value: risk,
                      child: Text(risk.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedRiskFactor = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a risk factor';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                // Submit button
                ElevatedButton(
                  onPressed: _handleSubmit,
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

