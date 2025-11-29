import 'package:hive_flutter/hive_flutter.dart';
import 'package:all_tracker/core/hive/hive_module_initializer.dart';
import '../data/models/password_model.dart';
import '../data/models/secret_question_model.dart';
import '../core/constants.dart';

/// Hive initializer for the password_tracker module.
///
/// This class handles registration of all Hive adapters and opening of all
/// Hive boxes required by the password_tracker module. It implements the
/// HiveModuleInitializer interface so it can be discovered and called by
/// the central HiveInitializer.
class PasswordTrackerHiveInitializer implements HiveModuleInitializer {
  @override
  Future<void> registerAdapters() async {
    // Register PasswordModel adapter (TypeId: 22)
    final passwordAdapterId = PasswordModelAdapter().typeId;
    if (!Hive.isAdapterRegistered(passwordAdapterId)) {
      Hive.registerAdapter(PasswordModelAdapter());
    }

    // Register SecretQuestionModel adapter (TypeId: 23)
    final secretQuestionAdapterId = SecretQuestionModelAdapter().typeId;
    if (!Hive.isAdapterRegistered(secretQuestionAdapterId)) {
      Hive.registerAdapter(SecretQuestionModelAdapter());
    }
  }

  @override
  Future<void> openBoxes() async {
    // Open password tracker boxes
    await Hive.openBox<PasswordModel>(passwordBoxName);
    await Hive.openBox<SecretQuestionModel>(secretQuestionBoxName);
  }
}

