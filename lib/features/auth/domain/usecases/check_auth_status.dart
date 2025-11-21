import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Use case for checking the current authentication status.
class CheckAuthStatus {
  final AuthRepository repository;

  CheckAuthStatus(this.repository);

  /// Check if user is currently authenticated.
  /// 
  /// Returns [User] if authenticated, null otherwise.
  Future<User?> call() async {
    return await repository.getCurrentUser();
  }
}

