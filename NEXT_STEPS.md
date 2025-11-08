# Google Drive Backup - Next Steps

## Implementation Status

Created **19 files** for the backup system infrastructure:

### Completed Files
1. Core encryption service (AES-256-GCM)
2. Device info service (device identification)
3. Backup manifest model
4. Backup metadata Hive model (TypeId: 5)
5. Google Auth datasource (OAuth)
6. Drive API client (REST integration)
7. Backup metadata local datasource
8. Domain entities (BackupMetadata, BackupResult, RestoreResult, BackupProgress, BackupMode)
9. Use cases (CreateBackup, ListBackups, RestoreBackup, DeleteBackup)
10. Backup builder service (snapshot creation)
11. Repository interface
12. Backup repository implementation (TODO)
13. Backup scheduler service (TODO)
14. Backup preferences service (TODO)
15. BackupCubit and states (TODO)
16. Backup settings page UI (TODO)
17. Backup list item widget (TODO)
18. Passphrase dialog widget (TODO)
19. Progress dialog widget (TODO)

## Remaining Implementation

### Critical Files to Complete

#### 1. Backup Repository Implementation
**File:** `lib/goal_tracker/features/backup/data/repositories/backup_repository_impl.dart`

This is the core business logic that orchestrates:
- Backup creation: snapshot → compress → encrypt → upload to Drive
- Backup listing: fetch from Drive + merge local metadata
- Restore: download → decrypt → validate → import
- Delete: remove from Drive + update local metadata

**Key Requirements:**
- Implement `BackupRepository` interface
- Use `BackupBuilderService` for snapshots
- Use `EncryptionService` for encryption/decryption
- Use `DriveApiClient` for Drive operations
- Emit progress events to `backupProgress` stream
- Handle E2EE and device key modes

#### 2. Backup Preferences Service
**File:** `lib/goal_tracker/features/backup/core/backup_preferences_service.dart`

Store user preferences in Hive:
- Auto-backup enabled/disabled
- Encryption mode (device key / E2EE)
- Retention count (how many backups to keep)
- Last backup timestamp

#### 3. Backup Scheduler Service
**File:** `lib/goal_tracker/features/backup/core/backup_scheduler_service.dart`

Handle automatic periodic backups:
- Check last backup time on app start
- Trigger backup if > 24 hours since last backup
- Run in foreground (no background processing for MVP)

#### 4. Presentation Layer (Cubit + States)
**Files:**
- `lib/goal_tracker/features/backup/presentation/cubit/backup_state.dart`
- `lib/goal_tracker/features/backup/presentation/cubit/backup_cubit.dart`

Implement state management:
- Handle Google Sign-In flow
- Manage backup/restore operations
- Emit progress updates
 scatterh errors

#### 5. UI Components
**Files:**
- `lib/goal_tracker/features/backup/presentation/pages/backup_settings_page.dart`
- `lib/goal_tracker/features/backup/presentation/widgets/backup_list_item.dart`
- `lib/goal_tracker/features/backup/presentation/widgets/passphrase_dialog.dart`
- `lib/goal_tracker/features/backup/presentation/widgets/backup_progress_dialog.dart`

UI sections:
1. Google Drive sign-in
2. Auto-backup toggle and settings
3. Manual backup button
4. Backup list with restore options
5. E2EE passphrase entry

### Integration Steps

1. **Update Hive Initializer**
   - Add `BackupMetadataModelAdapter` registration
   - Open `backup_metadata_box`

2. **Wire DI**
   - Add `createBackupCubit()` to `core/injection.dart`
   - Wire all dependencies (services → datasources → repository → usecases → cubit)

3. **Update Settings Page**
   - Add navigation to `BackupSettingsPage`
   - Keep local backup/restore separate

4. **Initialize Scheduler in main.dart**
   - Call `checkAndRunBackup()` after Hive init

### Testing Checklist

- [ ] Unit test encryption service
- [ ] Unit test backup repository (mock Drive API)
- [ ] Widget test backup UI
- [ ] Integration test full backup/restore flow
- [ ] Test E2EE mode with passphrase
- [ ] Test device key mode
- [ ] Test automatic backup scheduling
- [ ] Test cross-device restore
- [ ] Test error handling (network, auth, etc.)

### Configuration Requirements

For Google Drive integration to work:

1. **Android:**
   - Add `google-services.json` from Firebase Console
   - Configure SHA-1 fingerprint in Firebase
   - Add OAuth client ID to build.gradle (if needed)

2. **iOS:**
   - Add `GoogleService-Info.plist` from Firebase Console
   - Configure URL scheme in Info.plist
   - Add keychain sharing entitlement

3. **Firebase Console:**
   - Enable Google Drive API
   - Configure OAuth consent screen
   - Add `drive.appdata` scope

### Documentation Needed

- Update `README.md` with backup feature description
- Create `readme/google_drive_backup\.md` setup guide
- Document OAuth configuration process
- Add troubleshooting section

## Summary

Infrastructure is 60% complete. Remaining work focuses on:
1. Repository implementation (complex, business logic heavy)
2. Presentation layer (Cubit + UI)
3. Integration (DI wiring, Hive init)
4. Configuration (OAuth setup)
5. Testing

The architecture is sound and follows clean architecture principles. All core services and data sources are in place.

