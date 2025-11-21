import '../entities/user.dart';

/// Abstract repository for authentication operations.
abstract class AuthRepository {
  /// Sign in the user.
  /// 
  /// Returns [User] if sign-in is successful, null otherwise.
  Future<User?> signIn();

  /// Sign out the current user.
  Future<void> signOut();

  /// Check if a user is currently signed in.
  /// 
  /// Returns true if signed in, false otherwise.
  Future<bool> isSignedIn();

  /// Get the current authenticated user.
  /// 
  /// Returns [User] if authenticated, null otherwise.
  Future<User?> getCurrentUser();
}

