// lib/features/auth/core/injection.dart
// Composition root for auth feature: wires data -> repository -> usecases -> cubit.

import 'package:all_tracker/features/backup/data/datasources/google_auth_datasource.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/usecases/sign_in.dart';
import '../domain/usecases/sign_out.dart';
import '../domain/usecases/check_auth_status.dart';
import '../presentation/cubit/auth_cubit.dart';

/// ---------------------------------------------------------------------------
/// Auth Feature Dependency Injection
/// ---------------------------------------------------------------------------
/// 
/// Purpose:
/// - Provides factory functions for creating auth-related dependencies
/// - Wires up the complete auth feature dependency graph
/// - Ensures proper initialization order and dependency resolution
///
/// Notes:
/// - Uses singleton instance of GoogleAuthDataSource to maintain state across app lifecycle
/// - Wires up the complete auth feature dependency graph:
///   Data source → Repository → Use cases → Cubit
/// ---------------------------------------------------------------------------

/// Create the auth repository with all dependencies.
AuthRepository createAuthRepository() {
  // Create GoogleAuthDataSource instance (stateless, safe to instantiate multiple times)
  final googleAuthDataSource = GoogleAuthDataSource();
  
  // Create repository
  return AuthRepositoryImpl(googleAuthDataSource);
}

/// Create all auth use cases.
///
/// Returns a map of use cases keyed by name for easy access.
Map<String, dynamic> createAuthUseCases() {
  final repository = createAuthRepository();

  return {
    'signIn': SignIn(repository),
    'signOut': SignOut(repository),
    'checkAuthStatus': CheckAuthStatus(repository),
    'repository': repository,
  };
}

/// Create a fully-wired AuthCubit instance.
///
/// This factory function wires up all dependencies for the auth feature:
/// - Data source (Google Auth)
/// - Repository (orchestrates auth operations)
/// - Use cases (single-responsibility operations)
/// - Cubit (state management)
AuthCubit createAuthCubit() {
  // Data source
  final googleAuthDataSource = GoogleAuthDataSource();
  
  // Repository
  final repository = AuthRepositoryImpl(googleAuthDataSource);
  
  // Use cases
  final signIn = SignIn(repository);
  final signOut = SignOut(repository);
  final checkAuthStatus = CheckAuthStatus(repository);
  
  // Cubit
  return AuthCubit(
    signIn: signIn,
    signOut: signOut,
    checkAuthStatus: checkAuthStatus,
  );
}

