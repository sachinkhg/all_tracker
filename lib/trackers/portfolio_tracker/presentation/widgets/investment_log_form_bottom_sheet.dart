// lib/trackers/portfolio_tracker/presentation/widgets/investment_log_form_bottom_sheet.dart
// Form bottom sheet for creating/editing investment log

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/investment_log.dart';
import '../../../../widgets/bottom_sheet_helpers.dart';

class InvestmentLogFormBottomSheet extends StatefulWidget {
  final InvestmentLog? investmentLog;
  final Future<void> Function({
    required String investmentId,
    required DateTime purchaseDate,
    double? quantity,
    double? averageCostPrice,
    double? costToAcquire,
    double? currencyConversionAmount,
  }) onSubmit;
  final Future<void> Function()? onDelete;
  final String title;
  final bool requiresQuantity;

  const InvestmentLogFormBottomSheet({
    super.key,
    this.investmentLog,
    required this.onSubmit,
    this.onDelete,
    required this.title,
    required this.requiresQuantity,
  });

  static Future<void> show(
    BuildContext context, {
    InvestmentLog? investmentLog,
    required Future<void> Function({
      required String investmentId,
      required DateTime purchaseDate,
      double? quantity,
      double? averageCostPrice,
      double? costToAcquire,
      double? currencyConversionAmount,
    }) onSubmit,
    Future<void> Function()? onDelete,
    String title = 'Add Investment',
    required bool requiresQuantity,
  }) {
    return showAppBottomSheet<void>(
      context,
      InvestmentLogFormBottomSheet(
        investmentLog: investmentLog,
        onSubmit: onSubmit,
        onDelete: onDelete,
        title: title,
        requiresQuantity: requiresQuantity,
      ),
    );
  }

  @override
  State<InvestmentLogFormBottomSheet> createState() => _InvestmentLogFormBottomSheetState();
}

class _InvestmentLogFormBottomSheetState extends State<InvestmentLogFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _quantityController;
  late final TextEditingController _averageCostPriceController;
  late final TextEditingController _costToAcquireController;
  late final TextEditingController _currencyConversionController;
  DateTime? _purchaseDate;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(
      text: widget.investmentLog?.quantity?.toString() ?? '',
    );
    _averageCostPriceController = TextEditingController(
      text: widget.investmentLog?.averageCostPrice?.toString() ?? '',
    );
    _costToAcquireController = TextEditingController(
      text: widget.investmentLog?.costToAcquire?.toString() ?? '',
    );
    _currencyConversionController = TextEditingController(
      text: widget.investmentLog?.currencyConversionAmount?.toString() ?? '',
    );
    _purchaseDate = widget.investmentLog?.purchaseDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _averageCostPriceController.dispose();
    _costToAcquireController.dispose();
    _currencyConversionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate ?? DateTime.now(),
      firstDate: DateTime(1000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _purchaseDate = picked;
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      if (_purchaseDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a purchase date')),
        );
        return;
      }

      final quantityText = _quantityController.text.trim();
      final averageCostPriceText = _averageCostPriceController.text.trim();
      final costToAcquireText = _costToAcquireController.text.trim();
      final currencyConversionText = _currencyConversionController.text.trim();

      await widget.onSubmit(
        investmentId: widget.investmentLog?.investmentId ?? '',
        purchaseDate: _purchaseDate!,
        quantity: quantityText.isEmpty ? null : double.tryParse(quantityText),
        averageCostPrice: averageCostPriceText.isEmpty ? null : double.tryParse(averageCostPriceText),
        costToAcquire: costToAcquireText.isEmpty ? null : double.tryParse(costToAcquireText),
        currencyConversionAmount: currencyConversionText.isEmpty ? null : double.tryParse(currencyConversionText),
      );

      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');

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
                // Purchase Date field
                InkWell(
                  onTap: () => _selectDate(context),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Purchase Date *',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      _purchaseDate != null
                          ? dateFormat.format(_purchaseDate!)
                          : 'Select date',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Quantity field (required if tracking type is Unit)
                TextFormField(
                  controller: _quantityController,
                  decoration: InputDecoration(
                    labelText: widget.requiresQuantity ? 'Quantity *' : 'Quantity',
                    hintText: '0.0',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (widget.requiresQuantity && (value == null || value.trim().isEmpty)) {
                      return 'Quantity is required for Unit tracking type';
                    }
                    if (value != null && value.trim().isNotEmpty) {
                      final quantity = double.tryParse(value.trim());
                      if (quantity == null || quantity <= 0) {
                        return 'Please enter a valid positive number';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Average Cost Price field
                TextFormField(
                  controller: _averageCostPriceController,
                  decoration: const InputDecoration(
                    labelText: 'Average Cost Price',
                    hintText: '0.0',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value != null && value.trim().isNotEmpty) {
                      final price = double.tryParse(value.trim());
                      if (price == null || price < 0) {
                        return 'Please enter a valid non-negative number';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Cost to Acquire field
                TextFormField(
                  controller: _costToAcquireController,
                  decoration: const InputDecoration(
                    labelText: 'Cost to Acquire (fees, charges)',
                    hintText: '0.0',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value != null && value.trim().isNotEmpty) {
                      final cost = double.tryParse(value.trim());
                      if (cost == null || cost < 0) {
                        return 'Please enter a valid non-negative number';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Currency Conversion Amount field
                TextFormField(
                  controller: _currencyConversionController,
                  decoration: const InputDecoration(
                    labelText: 'Currency Conversion Amount',
                    hintText: 'Required if currency is not INR',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value != null && value.trim().isNotEmpty) {
                      final conversion = double.tryParse(value.trim());
                      if (conversion == null || conversion <= 0) {
                        return 'Please enter a valid positive number';
                      }
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

