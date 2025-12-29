// lib/trackers/portfolio_tracker/presentation/widgets/redemption_log_form_bottom_sheet.dart
// Form bottom sheet for creating/editing redemption log

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/redemption_log.dart';
import '../../../../widgets/bottom_sheet_helpers.dart';

class RedemptionLogFormBottomSheet extends StatefulWidget {
  final RedemptionLog? redemptionLog;
  final Future<void> Function({
    required String investmentId,
    required DateTime redemptionDate,
    double? quantity,
    double? averageSellPrice,
    double? costToSellOrWithdraw,
    double? currencyConversionAmount,
  }) onSubmit;
  final Future<void> Function()? onDelete;
  final String title;

  const RedemptionLogFormBottomSheet({
    super.key,
    this.redemptionLog,
    required this.onSubmit,
    this.onDelete,
    required this.title,
  });

  static Future<void> show(
    BuildContext context, {
    RedemptionLog? redemptionLog,
    required Future<void> Function({
      required String investmentId,
      required DateTime redemptionDate,
      double? quantity,
      double? averageSellPrice,
      double? costToSellOrWithdraw,
      double? currencyConversionAmount,
    }) onSubmit,
    Future<void> Function()? onDelete,
    String title = 'Add Redemption',
  }) {
    return showAppBottomSheet<void>(
      context,
      RedemptionLogFormBottomSheet(
        redemptionLog: redemptionLog,
        onSubmit: onSubmit,
        onDelete: onDelete,
        title: title,
      ),
    );
  }

  @override
  State<RedemptionLogFormBottomSheet> createState() => _RedemptionLogFormBottomSheetState();
}

class _RedemptionLogFormBottomSheetState extends State<RedemptionLogFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _quantityController;
  late final TextEditingController _averageSellPriceController;
  late final TextEditingController _costToSellController;
  late final TextEditingController _currencyConversionController;
  DateTime? _redemptionDate;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(
      text: widget.redemptionLog?.quantity?.toString() ?? '',
    );
    _averageSellPriceController = TextEditingController(
      text: widget.redemptionLog?.averageSellPrice?.toString() ?? '',
    );
    _costToSellController = TextEditingController(
      text: widget.redemptionLog?.costToSellOrWithdraw?.toString() ?? '',
    );
    _currencyConversionController = TextEditingController(
      text: widget.redemptionLog?.currencyConversionAmount?.toString() ?? '',
    );
    _redemptionDate = widget.redemptionLog?.redemptionDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _averageSellPriceController.dispose();
    _costToSellController.dispose();
    _currencyConversionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _redemptionDate ?? DateTime.now(),
      firstDate: DateTime(1000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _redemptionDate = picked;
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      if (_redemptionDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a redemption date')),
        );
        return;
      }

      final quantityText = _quantityController.text.trim();
      final averageSellPriceText = _averageSellPriceController.text.trim();
      final costToSellText = _costToSellController.text.trim();
      final currencyConversionText = _currencyConversionController.text.trim();

      await widget.onSubmit(
        investmentId: widget.redemptionLog?.investmentId ?? '',
        redemptionDate: _redemptionDate!,
        quantity: quantityText.isEmpty ? null : double.tryParse(quantityText),
        averageSellPrice: averageSellPriceText.isEmpty ? null : double.tryParse(averageSellPriceText),
        costToSellOrWithdraw: costToSellText.isEmpty ? null : double.tryParse(costToSellText),
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
                // Redemption Date field
                InkWell(
                  onTap: () => _selectDate(context),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Redemption Date *',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      _redemptionDate != null
                          ? dateFormat.format(_redemptionDate!)
                          : 'Select date',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Quantity field
                TextFormField(
                  controller: _quantityController,
                  decoration: const InputDecoration(
                    labelText: 'Quantity',
                    hintText: '0.0',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
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
                // Average Sell Price field
                TextFormField(
                  controller: _averageSellPriceController,
                  decoration: const InputDecoration(
                    labelText: 'Average Sell Price',
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
                // Cost to Sell or Withdraw field
                TextFormField(
                  controller: _costToSellController,
                  decoration: const InputDecoration(
                    labelText: 'Cost to Sell or Withdraw (fees, charges)',
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

