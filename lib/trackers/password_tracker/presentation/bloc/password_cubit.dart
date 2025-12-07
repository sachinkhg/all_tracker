import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/password.dart';
import '../../domain/usecases/password/get_all_passwords.dart';
import '../../domain/usecases/password/get_password_by_id.dart';
import '../../domain/usecases/password/get_passwords_by_category.dart';
import '../../domain/usecases/password/create_password.dart';
import '../../domain/usecases/password/update_password.dart';
import '../../domain/usecases/password/delete_password.dart';
import 'package:all_tracker/core/services/view_preferences_service.dart';
import 'package:all_tracker/core/services/filter_preferences_service.dart';
import 'package:all_tracker/core/services/sort_preferences_service.dart';
import 'password_state.dart';

/// ---------------------------------------------------------------------------
/// PasswordCubit
///
/// File purpose:
/// - Manages presentation state for Password entities within the Password feature.
/// - Loads, creates, updates and deletes passwords by delegating
///   to domain use-cases.
/// - Holds an internal master copy (`_allPasswords`) and emits filtered/derived
///   views to the UI via PasswordState.
///
/// Developer guidance:
/// - Keep domain validation and persistence in the use-cases/repository; this
///   cubit should orchestrate and transform results for UI consumption only.
/// ---------------------------------------------------------------------------

class PasswordCubit extends Cubit<PasswordState> {
  final GetAllPasswords getAll;
  final GetPasswordById getById;
  final GetPasswordsByCategory getByCategory;
  final CreatePassword create;
  final UpdatePassword update;
  final DeletePassword delete;
  final ViewPreferencesService viewPreferencesService;
  final FilterPreferencesService filterPreferencesService;
  final SortPreferencesService sortPreferencesService;

  // master copy of all passwords fetched from the domain layer.
  List<Password> _allPasswords = [];

  static const Map<String, bool> _defaultVisibleFieldConfig = {
    'siteName': true,
    'url': false,
    'username': false,
    'password': false,
    'isGoogleSignIn': false,
    'lastUpdated': false,
    'is2FA': false,
    'categoryGroup': false,
    'hasSecretQuestions': false,
  };

  // Visible fields configuration for presentation layer
  Map<String, bool> _visibleFields = Map<String, bool>.from(_defaultVisibleFieldConfig);

  Map<String, bool> get visibleFields => Map<String, bool>.unmodifiable(_visibleFields);

  void setVisibleFields(Map<String, bool> fields) {
    _visibleFields = Map<String, bool>.from(_defaultVisibleFieldConfig);
    _visibleFields.addAll(fields);
    _visibleFields['siteName'] = true;
    // Re-emit current view to trigger UI rebuild with new visibility
    emit(PasswordsLoaded(List<Password>.from(_allPasswords), visibleFields));
  }

  PasswordCubit({
    required this.getAll,
    required this.getById,
    required this.getByCategory,
    required this.create,
    required this.update,
    required this.delete,
    required this.viewPreferencesService,
    required this.filterPreferencesService,
    required this.sortPreferencesService,
  }) : super(PasswordsLoading());

  /// Loads all passwords from the repository.
  Future<void> loadPasswords() async {
    emit(PasswordsLoading());
    try {
      _allPasswords = await getAll();
      emit(PasswordsLoaded(_allPasswords, visibleFields));
    } catch (e) {
      emit(PasswordsError('Failed to load passwords: $e'));
    }
  }

  /// Gets a password by its ID.
  Future<Password?> getPasswordById(String id) async {
    try {
      return await getById(id);
    } catch (e) {
      emit(PasswordsError('Failed to get password: $e'));
      return null;
    }
  }

  /// Gets passwords by category.
  Future<List<Password>> getPasswordsByCategory(String categoryGroup) async {
    try {
      return await getByCategory(categoryGroup);
    } catch (e) {
      emit(PasswordsError('Failed to get passwords by category: $e'));
      return [];
    }
  }

  /// Creates a new password.
  Future<void> createPassword({
    required String siteName,
    String? url,
    String? username,
    String? password,
    bool isGoogleSignIn = false,
    bool is2FA = false,
    String? categoryGroup,
    bool hasSecretQuestions = false,
  }) async {
    try {
      final newPassword = Password(
        id: const Uuid().v4(),
        siteName: siteName,
        url: url,
        username: username,
        password: password,
        isGoogleSignIn: isGoogleSignIn,
        lastUpdated: DateTime.now(),
        is2FA: is2FA,
        categoryGroup: categoryGroup,
        hasSecretQuestions: hasSecretQuestions,
      );

      await create(newPassword);
      await loadPasswords(); // Reload to get updated list
    } catch (e) {
      emit(PasswordsError('Failed to create password: $e'));
    }
  }

  /// Updates an existing password.
  Future<void> updatePassword(Password password) async {
    try {
      final updatedPassword = password.copyWith(
        lastUpdated: DateTime.now(),
      );
      await update(updatedPassword);
      await loadPasswords(); // Reload to get updated list
    } catch (e) {
      emit(PasswordsError('Failed to update password: $e'));
    }
  }

  /// Deletes a password by its ID.
  Future<void> deletePassword(String id) async {
    try {
      await delete(id);
      await loadPasswords(); // Reload to get updated list
    } catch (e) {
      emit(PasswordsError('Failed to delete password: $e'));
    }
  }
}

