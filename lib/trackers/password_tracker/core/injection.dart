// lib/trackers/password_tracker/core/injection.dart
// Composition root: wires data -> repository -> usecases -> cubit.

import 'package:hive_flutter/hive_flutter.dart';

import '../data/datasources/password_local_data_source.dart';
import '../data/repositories/password_repository_impl.dart';
import '../data/models/password_model.dart';
import '../domain/usecases/password/create_password.dart';
import '../domain/usecases/password/get_all_passwords.dart';
import '../domain/usecases/password/get_password_by_id.dart';
import '../domain/usecases/password/get_passwords_by_category.dart';
import '../domain/usecases/password/update_password.dart';
import '../domain/usecases/password/delete_password.dart';
import '../presentation/bloc/password_cubit.dart';

import '../data/datasources/secret_question_local_data_source.dart';
import '../data/repositories/secret_question_repository_impl.dart';
import '../data/models/secret_question_model.dart';
import '../domain/usecases/secret_question/create_secret_question.dart';
import '../domain/usecases/secret_question/get_secret_questions_by_password_id.dart';
import '../domain/usecases/secret_question/update_secret_question.dart';
import '../domain/usecases/secret_question/delete_secret_question.dart';
import '../presentation/bloc/secret_question_cubit.dart';

import '../data/services/password_encryption_service.dart';
import 'constants.dart';
import 'package:all_tracker/core/injection.dart';
import 'package:all_tracker/core/services/view_preferences_service.dart';
import 'package:all_tracker/core/services/filter_preferences_service.dart';
import 'package:all_tracker/core/services/sort_preferences_service.dart';

/// Factory that constructs a fully-wired [PasswordCubit].
///
/// Implementation details:
/// - This function performs an *eager, manual wiring* of concrete implementations for the feature.
/// - It assumes the Hive boxes have already been opened (typically in `main()`).
/// - All objects created here are plain Dart instances (no DI container used).
PasswordCubit createPasswordCubit() {
  // IMPORTANT: Hive.box must be already opened (open in main.dart).
  // During hot reload, boxes might not be open - check first
  if (!Hive.isBoxOpen(passwordBoxName)) {
    throw StateError(
      'Password box is not open. This may happen during hot reload. '
      'Please restart the app to reinitialize Hive boxes.',
    );
  }
  final Box<PasswordModel> box = Hive.box<PasswordModel>(passwordBoxName);

  // ---------------------------------------------------------------------------
  // Encryption Service
  // ---------------------------------------------------------------------------
  final encryptionService = PasswordEncryptionService();

  // ---------------------------------------------------------------------------
  // Data layer
  // ---------------------------------------------------------------------------
  final local = PasswordLocalDataSourceImpl(box);

  // ---------------------------------------------------------------------------
  // Repository layer
  // ---------------------------------------------------------------------------
  final repo = PasswordRepositoryImpl(local, encryptionService);

  // ---------------------------------------------------------------------------
  // Use-cases (domain)
  // ---------------------------------------------------------------------------
  final getAll = GetAllPasswords(repo);
  final getById = GetPasswordById(repo);
  final getByCategory = GetPasswordsByCategory(repo);
  final create = CreatePassword(repo);
  final update = UpdatePassword(repo);
  final delete = DeletePassword(repo);

  // ---------------------------------------------------------------------------
  // Presentation
  // ---------------------------------------------------------------------------
  final viewPrefsService = getIt<ViewPreferencesService>();
  final filterPrefsService = getIt<FilterPreferencesService>();
  final sortPrefsService = getIt<SortPreferencesService>();
  
  return PasswordCubit(
    getAll: getAll,
    getById: getById,
    getByCategory: getByCategory,
    create: create,
    update: update,
    delete: delete,
    viewPreferencesService: viewPrefsService,
    filterPreferencesService: filterPrefsService,
    sortPreferencesService: sortPrefsService,
  );
}

/// Factory that constructs a fully-wired [SecretQuestionCubit].
///
/// Implementation details:
/// - This function performs an *eager, manual wiring* of concrete implementations for the feature.
/// - It assumes the Hive boxes have already been opened (typically in `main()`).
SecretQuestionCubit createSecretQuestionCubit() {
  // IMPORTANT: Hive.box must be already opened (open in main.dart).
  // During hot reload, boxes might not be open - check first
  if (!Hive.isBoxOpen(secretQuestionBoxName)) {
    throw StateError(
      'Secret question box is not open. This may happen during hot reload. '
      'Please restart the app to reinitialize Hive boxes.',
    );
  }
  final Box<SecretQuestionModel> box = Hive.box<SecretQuestionModel>(secretQuestionBoxName);

  // ---------------------------------------------------------------------------
  // Encryption Service
  // ---------------------------------------------------------------------------
  final encryptionService = PasswordEncryptionService();

  // ---------------------------------------------------------------------------
  // Data layer
  // ---------------------------------------------------------------------------
  final local = SecretQuestionLocalDataSourceImpl(box);

  // ---------------------------------------------------------------------------
  // Repository layer
  // ---------------------------------------------------------------------------
  final repo = SecretQuestionRepositoryImpl(local, encryptionService);

  // ---------------------------------------------------------------------------
  // Use-cases (domain)
  // ---------------------------------------------------------------------------
  final getByPasswordId = GetSecretQuestionsByPasswordId(repo);
  final create = CreateSecretQuestion(repo);
  final update = UpdateSecretQuestion(repo);
  final delete = DeleteSecretQuestion(repo);

  // ---------------------------------------------------------------------------
  // Presentation
  // ---------------------------------------------------------------------------
  return SecretQuestionCubit(
    getByPasswordId: getByPasswordId,
    create: create,
    update: update,
    delete: delete,
  );
}

