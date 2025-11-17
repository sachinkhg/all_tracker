import 'package:equatable/equatable.dart';
import '../../domain/entities/investment_component.dart';

/// Base state for investment component operations
abstract class InvestmentComponentState extends Equatable {
  const InvestmentComponentState();

  @override
  List<Object?> get props => [];
}

/// Loading state — emitted when component data is being fetched
class ComponentsLoading extends InvestmentComponentState {}

/// Loaded state — holds the list of successfully fetched components
class ComponentsLoaded extends InvestmentComponentState {
  final List<InvestmentComponent> components;

  const ComponentsLoaded(this.components);

  @override
  List<Object?> get props => [components];
}

/// Error state — emitted when fetching or modifying components fails
class ComponentsError extends InvestmentComponentState {
  final String message;

  const ComponentsError(this.message);

  @override
  List<Object?> get props => [message];
}

