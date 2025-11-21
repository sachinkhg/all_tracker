import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/sign_in.dart';
import '../../domain/usecases/sign_out.dart';
import '../../domain/usecases/check_auth_status.dart';
import '../states/auth_state.dart';

/// Cubit for managing authentication state and operations.
class AuthCubit extends Cubit<AuthState> {
  final SignIn _signIn;
  final SignOut _signOut;
  final CheckAuthStatus _checkAuthStatus;

  AuthCubit({
    required SignIn signIn,
    required SignOut signOut,
    required CheckAuthStatus checkAuthStatus,
  })  : _signIn = signIn,
        _signOut = signOut,
        _checkAuthStatus = checkAuthStatus,
        super(AuthInitial());

  /// Check the current authentication status.
  Future<void> checkAuthStatus() async {
    emit(AuthLoading());

    try {
      final user = await _checkAuthStatus();
      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthError('Failed to check authentication status: $e'));
    }
  }

  /// Sign in the user.
  Future<void> signIn() async {
    emit(AuthLoading());

    try {
      final user = await _signIn();
      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthError('Sign in failed: $e'));
    }
  }

  /// Sign out the current user.
  Future<void> signOut() async {
    emit(AuthLoading());

    try {
      await _signOut();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError('Sign out failed: $e'));
    }
  }
}

