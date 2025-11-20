import '../../entities/expense.dart';
import '../../repositories/expense_repository.dart';

/// Use case for retrieving all expenses for a trip.
class GetExpensesByTripId {
  final ExpenseRepository repository;

  GetExpensesByTripId(this.repository);

  Future<List<Expense>> call(String tripId) async => repository.getExpensesByTripId(tripId);
}

