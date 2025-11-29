/*
 * File: ./lib/trackers/password_tracker/domain/entities/password.dart
 *
 * Purpose:
 *   Domain representation of a Password used throughout the application business logic.
 *   This file defines the plain domain entity (immutable, equatable) and documents
 *   how it maps to persistence DTOs / Hive models (those mapper functions live in
 *   the data layer / local datasource).
 *
 * Serialization rules (for implementers of DTO / Hive adapters):
 *   - `id` (String)         : non-nullable, unique identifier (GUID-like). Expected to be persisted.
 *   - `siteName` (String)   : non-nullable, user-facing site name.
 *   - `url` (String?)       : nullable; optional URL for the site.
 *   - `username` (String?)  : nullable; optional username.
 *   - `password` (String?)  : nullable; will be encrypted in storage.
 *   - `isGoogleSignIn` (bool): non-nullable, defaults to `false`.
 *   - `lastUpdated` (DateTime): non-nullable, timestamp of last update.
 *   - `is2FA` (bool)        : non-nullable, defaults to `false`.
 *   - `categoryGroup` (String?): nullable; used for categorisation / grouping.
 *   - `hasSecretQuestions` (bool): non-nullable, defaults to `false`.
 *
 * Compatibility guidance:
 *   - When adding/removing persisted fields, DO NOT reuse Hive field numbers previously used.
 *   - Any change to persisted shape or Hive field numbers must be recorded in migration_notes.md
 *     and corresponding migration code must be added to the local data source.
 *   - Mapper helpers (e.g., PasswordModel.fromEntity(), PasswordModel.toEntity()) should explicitly handle
 *     legacy values (for instance missing `isGoogleSignIn` => default to `false`).
 *
 * Notes for implementers:
 *   - This file intentionally contains only the pure domain entity and no persistence annotations.
 *     Keep persistence concerns (Hive annotations, adapters) inside the data layer to avoid
 *     coupling the domain layer to a storage implementation.
 */

import 'package:equatable/equatable.dart';

/// Domain model for a Password.
///
/// This class is intended for use inside the domain and presentation layers only.
/// Persistence-specific mapping (Hive fields, DTO serialization) should live in the
/// data/local layer (e.g., `password_model.dart`) which converts
/// between this entity and the stored representation.
class Password extends Equatable {
  /// Unique identifier for the password (GUID recommended).
  ///
  /// Persistence hint: typically stored as the primary id in the DTO.
  /// Expected Hive field number (data layer): 0.
  final String id;

  /// Human-readable site name.
  ///
  /// Persistence hint: non-nullable in domain; if a persisted record contains
  /// a null/empty name, the mapper should provide a sensible fallback or reject.
  /// Expected Hive field number (data layer): 1.
  final String siteName;

  /// Optional URL for the site.
  ///
  /// Nullable: optional URL field.
  /// Expected Hive field number (data layer): 2.
  final String? url;

  /// Optional username for the account.
  ///
  /// Nullable: optional username field.
  /// Expected Hive field number (data layer): 3.
  final String? username;

  /// Optional password for the account (will be encrypted in storage).
  ///
  /// Nullable: optional password field. This will be encrypted when stored.
  /// Expected Hive field number (data layer): 4 (encrypted).
  final String? password;

  /// Whether this account uses Google Sign-In.
  ///
  /// Non-nullable in domain. Mappers should default a missing or unknown value
  /// in persisted records to `false` to preserve backward compatibility.
  /// Expected Hive field number (data layer): 5.
  final bool isGoogleSignIn;

  /// Timestamp of last update.
  ///
  /// Non-nullable in domain. Represents when the password entry was last modified.
  /// Expected Hive field number (data layer): 6.
  final DateTime lastUpdated;

  /// Whether this account has 2FA enabled.
  ///
  /// Non-nullable in domain. Mappers should default a missing or unknown value
  /// in persisted records to `false` to preserve backward compatibility.
  /// Expected Hive field number (data layer): 7.
  final bool is2FA;

  /// Optional category/group for the password.
  ///
  /// Nullable: used for filtering/grouping in the UI. Prefer reusing a small set of
  /// canonical category strings where possible.
  /// Expected Hive field number (data layer): 8.
  final String? categoryGroup;

  /// Whether this password has associated secret questions.
  ///
  /// Non-nullable in domain. Mappers should default a missing or unknown value
  /// in persisted records to `false` to preserve backward compatibility.
  /// Expected Hive field number (data layer): 9.
  final bool hasSecretQuestions;

  /// Domain constructor.
  ///
  /// Keep this immutable (`const`) so instances can be compared and used in const contexts.
  const Password({
    required this.id,
    required this.siteName,
    this.url,
    this.username,
    this.password,
    this.isGoogleSignIn = false,
    required this.lastUpdated,
    this.is2FA = false,
    this.categoryGroup,
    this.hasSecretQuestions = false,
  });

  @override
  List<Object?> get props => [
        id,
        siteName,
        url,
        username,
        password,
        isGoogleSignIn,
        lastUpdated,
        is2FA,
        categoryGroup,
        hasSecretQuestions,
      ];

  /// Creates a copy of this Password with the given fields replaced.
  ///
  /// Useful for updates where only certain fields change.
  Password copyWith({
    String? id,
    String? siteName,
    String? url,
    String? username,
    String? password,
    bool? isGoogleSignIn,
    DateTime? lastUpdated,
    bool? is2FA,
    String? categoryGroup,
    bool? hasSecretQuestions,
  }) {
    return Password(
      id: id ?? this.id,
      siteName: siteName ?? this.siteName,
      url: url ?? this.url,
      username: username ?? this.username,
      password: password ?? this.password,
      isGoogleSignIn: isGoogleSignIn ?? this.isGoogleSignIn,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      is2FA: is2FA ?? this.is2FA,
      categoryGroup: categoryGroup ?? this.categoryGroup,
      hasSecretQuestions: hasSecretQuestions ?? this.hasSecretQuestions,
    );
  }
}

