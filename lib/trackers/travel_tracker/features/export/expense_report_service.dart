import '../../domain/entities/expense.dart';
import '../../core/constants.dart';

/// Service for generating expense reports.
class ExpenseReportService {
  /// Generate expense summary for a trip.
  Map<String, dynamic> generateExpenseSummary(List<Expense> expenses) {
    if (expenses.isEmpty) {
      return {
        'total': 0.0,
        'byCategory': <String, double>{},
        'byCurrency': <String, double>{},
      };
    }

    final byCategory = <ExpenseCategory, double>{};
    final byCurrency = <String, double>{};
    double total = 0.0;

    for (final expense in expenses) {
      total += expense.amount;

      byCategory[expense.category] =
          (byCategory[expense.category] ?? 0.0) + expense.amount;

      byCurrency[expense.currency] =
          (byCurrency[expense.currency] ?? 0.0) + expense.amount;
    }

    return {
      'total': total,
      'byCategory': byCategory.map(
        (key, value) => MapEntry(expenseCategoryLabels[key]!, value),
      ),
      'byCurrency': byCurrency,
      'count': expenses.length,
    };
  }
}

