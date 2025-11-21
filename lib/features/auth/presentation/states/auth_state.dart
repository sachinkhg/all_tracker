import 'package:equatable/equatable.dart';
import '../../domain/entities/user.dart';

/// Base class for authentication states.
sealed class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

/// Initial state - checking authentication status.
class AuthInitial extends AuthState {}

/// Loading state - during sign in/out operations.
class AuthLoading extends AuthState {}

/// User is authenticated.
class AuthAuthenticated extends AuthState {
  final User user;

  AuthAuthenticated(this.user);

  @override
  List<Object?> get props => [user];
}

/// User is not authenticated.
class AuthUnauthenticated extends AuthState {}

/// An error occurred during authentication.
class AuthError extends AuthState {
  final String message;

  AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

