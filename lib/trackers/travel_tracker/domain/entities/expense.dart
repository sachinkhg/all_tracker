import 'package:equatable/equatable.dart';
import '../../core/constants.dart';

/// Domain model for an Expense.
///
/// Represents an expense entry for a trip.
/// Expenses are categorized and associated with a specific date.
class Expense extends Equatable {
  /// Unique identifier for the expense (GUID recommended).
  final String id;

  /// Associated trip ID.
  final String tripId;

  /// Date of the expense.
  final DateTime date;

  /// Expense category.
  final ExpenseCategory category;

  /// Amount spent.
  final double amount;

  /// Currency code (e.g., 'USD', 'EUR').
  final String currency;

  /// Optional description of the expense.
  final String? description;

  /// When the expense was created.
  final DateTime createdAt;

  /// When the expense was last updated.
  final DateTime updatedAt;

  const Expense({
    required this.id,
    required this.tripId,
    required this.date,
    required this.category,
    required this.amount,
    required this.currency,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        tripId,
        date,
        category,
        amount,
        currency,
        description,
        createdAt,
        updatedAt,
      ];
}

