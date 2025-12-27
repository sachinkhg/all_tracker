import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/expense_group.dart';

class ExpenseFormBottomSheet extends StatefulWidget {
  final Expense? expense;
  final Future<void> Function(
    DateTime date,
    String description,
    double amount,
    ExpenseGroup group,
  ) onSubmit;
  final Future<void> Function()? onDelete;
  final String title;

  const ExpenseFormBottomSheet({
    super.key,
    this.expense,
    required this.onSubmit,
    this.onDelete,
    required this.title,
  });

  static Future<void> show(
    BuildContext context, {
    Expense? expense,
    required Future<void> Function(
      DateTime date,
      String description,
      double amount,
      ExpenseGroup group,
    ) onSubmit,
    Future<void> Function()? onDelete,
    String title = 'Create Expense',
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return ExpenseFormBottomSheet(
          expense: expense,
          onSubmit: onSubmit,
          onDelete: onDelete,
          title: title,
        );
      },
    );
  }

  @override
  State<ExpenseFormBottomSheet> createState() => _ExpenseFormBottomSheetState();
}

class _ExpenseFormBottomSheetState extends State<ExpenseFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descriptionController;
  late final TextEditingController _amountController;
  late DateTime _selectedDate;
  late ExpenseGroup _selectedGroup;
  bool _isDebit = true; // true for expense (positive), false for credit (negative)

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(
      text: widget.expense?.description ?? '',
    );
    _amountController = TextEditingController(
      text: widget.expense != null
          ? widget.expense!.amount.abs().toString()
          : '',
    );
    _selectedDate = widget.expense?.date ?? DateTime.now();
    _selectedGroup = widget.expense?.group ?? ExpenseGroup.food;
    _isDebit = widget.expense == null || widget.expense!.amount > 0;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      final amount = double.parse(_amountController.text.trim());
      final finalAmount = _isDebit ? amount : -amount;
      
      await widget.onSubmit(
        _selectedDate,
        _descriptionController.text.trim(),
        finalAmount,
        _selectedGroup,
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
                // Date picker
                InkWell(
                  onTap: () => _selectDate(context),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(dateFormat.format(_selectedDate)),
                  ),
                ),
                const SizedBox(height: 16),
                // Description field
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Enter expense description',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Amount field
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    hintText: '0.00',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter an amount';
                    }
                    final amount = double.tryParse(value.trim());
                    if (amount == null || amount <= 0) {
                      return 'Please enter a valid positive amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Debit/Credit toggle
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment<bool>(
                      value: true,
                      label: Text('Debit (Expense)'),
                      icon: Icon(Icons.arrow_downward),
                    ),
                    ButtonSegment<bool>(
                      value: false,
                      label: Text('Credit (Income)'),
                      icon: Icon(Icons.arrow_upward),
                    ),
                  ],
                  selected: {_isDebit},
                  onSelectionChanged: (Set<bool> newSelection) {
                    setState(() {
                      _isDebit = newSelection.first;
                    });
                  },
                ),
                const SizedBox(height: 16),
                // Group dropdown
                DropdownButtonFormField<ExpenseGroup>(
                  initialValue: _selectedGroup,
                  decoration: const InputDecoration(
                    labelText: 'Group',
                  ),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  dropdownColor: Theme.of(context).colorScheme.surface,
                  items: ExpenseGroup.values.map((group) {
                    return DropdownMenuItem<ExpenseGroup>(
                      value: group,
                      child: Text(
                        group.displayName,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedGroup = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 24),
                // Submit button
                ElevatedButton(
                  onPressed: _handleSubmit,
                  child: Text(widget.expense == null ? 'Create' : 'Update'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

