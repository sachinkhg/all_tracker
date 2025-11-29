import 'package:hive/hive.dart';
import '../../domain/entities/password.dart';

part 'password_model.g.dart'; // Generated via build_runner

/// ---------------------------------------------------------------------------
/// PasswordModel – Data Transfer Object (DTO) / Hive Persistence Model
/// ---------------------------------------------------------------------------
///
/// Purpose:
/// - Represents a persisted `Password` entity within Hive.
/// - Handles encryption/decryption of password field through PasswordEncryptionService.
/// - Acts as a bridge between domain-layer entities and Hive storage.
///
/// Schema & Migration Guidelines:
/// - Each `@HiveField` index is permanent once written to storage.
/// - Never reuse or reorder field numbers — doing so will corrupt persisted data.
/// - Add new fields only at the end with new, unique field numbers.
/// - Document any changes in `migration_notes.md`.
///
/// Security:
/// - Password field is encrypted before storage and decrypted when retrieved.
/// - Encryption is handled by PasswordEncryptionService.
/// ---------------------------------------------------------------------------

@HiveType(typeId: 22)
class PasswordModel extends HiveObject {
  /// Unique identifier for the password.
  ///
  /// Hive field number **0** — stable ID, never change or reuse.
  @HiveField(0)
  String id;

  /// Human-readable site name.
  ///
  /// Hive field number **1** — required.
  @HiveField(1)
  String siteName;

  /// Optional URL for the site.
  ///
  /// Hive field number **2** — nullable.
  @HiveField(2)
  String? url;

  /// Optional username for the account.
  ///
  /// Hive field number **3** — nullable.
  @HiveField(3)
  String? username;

  /// Encrypted password (stored as encrypted string).
  ///
  /// Hive field number **4** — nullable; stores encrypted password.
  /// The actual password is encrypted before storage.
  @HiveField(4)
  String? encryptedPassword;

  /// Whether this account uses Google Sign-In.
  ///
  /// Hive field number **5** — defaults to false.
  @HiveField(5)
  bool isGoogleSignIn;

  /// Timestamp of last update.
  ///
  /// Hive field number **6** — required.
  @HiveField(6)
  DateTime lastUpdated;

  /// Whether this account has 2FA enabled.
  ///
  /// Hive field number **7** — defaults to false.
  @HiveField(7)
  bool is2FA;

  /// Optional category/group for the password.
  ///
  /// Hive field number **8** — nullable.
  @HiveField(8)
  String? categoryGroup;

  /// Whether this password has associated secret questions.
  ///
  /// Hive field number **9** — defaults to false.
  @HiveField(9)
  bool hasSecretQuestions;

  PasswordModel({
    required this.id,
    required this.siteName,
    this.url,
    this.username,
    this.encryptedPassword,
    this.isGoogleSignIn = false,
    required this.lastUpdated,
    this.is2FA = false,
    this.categoryGroup,
    this.hasSecretQuestions = false,
  });

  /// Factory constructor to build a [PasswordModel] from a domain [Password].
  ///
  /// Note: This method requires an encryption service to encrypt the password.
  /// The encryption should be handled by the repository layer, not here.
  /// This factory assumes the password is already encrypted if provided.
  factory PasswordModel.fromEntity(Password p, {String? encryptedPassword}) => PasswordModel(
        id: p.id,
        siteName: p.siteName,
        url: p.url,
        username: p.username,
        encryptedPassword: encryptedPassword ?? (p.password != null ? '' : null),
        isGoogleSignIn: p.isGoogleSignIn,
        lastUpdated: p.lastUpdated,
        is2FA: p.is2FA,
        categoryGroup: p.categoryGroup,
        hasSecretQuestions: p.hasSecretQuestions,
      );

  /// Converts this model back into a domain [Password] entity.
  ///
  /// Note: This method requires an encryption service to decrypt the password.
  /// The decryption should be handled by the repository layer.
  /// This method assumes the password will be decrypted by the repository.
  Password toEntity({String? decryptedPassword}) => Password(
        id: id,
        siteName: siteName,
        url: url,
        username: username,
        password: decryptedPassword,
        isGoogleSignIn: isGoogleSignIn,
        lastUpdated: lastUpdated,
        is2FA: is2FA,
        categoryGroup: categoryGroup,
        hasSecretQuestions: hasSecretQuestions,
      );

  /// Creates a copy of this PasswordModel with the given fields replaced.
  ///
  /// Useful for updates where only certain fields change.
  PasswordModel copyWith({
    String? id,
    String? siteName,
    String? url,
    String? username,
    String? encryptedPassword,
    bool? isGoogleSignIn,
    DateTime? lastUpdated,
    bool? is2FA,
    String? categoryGroup,
    bool? hasSecretQuestions,
  }) {
    return PasswordModel(
      id: id ?? this.id,
      siteName: siteName ?? this.siteName,
      url: url ?? this.url,
      username: username ?? this.username,
      encryptedPassword: encryptedPassword ?? this.encryptedPassword,
      isGoogleSignIn: isGoogleSignIn ?? this.isGoogleSignIn,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      is2FA: is2FA ?? this.is2FA,
      categoryGroup: categoryGroup ?? this.categoryGroup,
      hasSecretQuestions: hasSecretQuestions ?? this.hasSecretQuestions,
    );
  }
}

