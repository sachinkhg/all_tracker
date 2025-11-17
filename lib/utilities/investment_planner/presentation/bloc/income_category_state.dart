import 'package:equatable/equatable.dart';
import '../../domain/entities/income_category.dart';

/// Base state for income category operations
abstract class IncomeCategoryState extends Equatable {
  const IncomeCategoryState();

  @override
  List<Object?> get props => [];
}

/// Loading state
class IncomeCategoriesLoading extends IncomeCategoryState {}

/// Loaded state
class IncomeCategoriesLoaded extends IncomeCategoryState {
  final List<IncomeCategory> categories;

  const IncomeCategoriesLoaded(this.categories);

  @override
  List<Object?> get props => [categories];
}

/// Error state
class IncomeCategoriesError extends IncomeCategoryState {
  final String message;

  const IncomeCategoriesError(this.message);

  @override
  List<Object?> get props => [message];
}

