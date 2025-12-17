# File Tags Implementation

## Overview

This implementation allows users to add tags to files in the file tracker, and these tags will persist even when the server URL changes or when switching between different servers. The system uses a **stable identifier** (folder + name) instead of the URL to track files, ensuring tags remain intact across server URL changes and server switches.

## Key Features

- **URL-Independent Tags**: Tags persist even when server URLs change
- **Server-Independent Tags**: Tags persist when switching between different servers (as long as folder structure matches)
- **Multiple Server Support**: Configure and switch between multiple servers, each identified by a friendly name
- **Stable File Identification**: Files are identified by folder path + filename, not by URL

## How It Works

### Stable Identifier

Each file has a stable identifier based on its folder path and filename:
- Format: `{folder}/{name}` (e.g., `/photos/2024/vacation.jpg`)
- This identifier remains constant even when:
  - The server URL changes
  - You switch between different servers
  - The server name changes
- Example:
  - Server "Home Server": `https://home-server.com/photos/2024/vacation.jpg`
  - Server "Backup Server": `https://backup-server.com/photos/2024/vacation.jpg`
  - Both have the same stable identifier: `/photos/2024/vacation.jpg`
  - Tags added on one server will appear on the other if the folder structure matches

### Server Management

The system now supports multiple servers, each identified by a friendly name:
- **Server Name**: A user-friendly identifier (e.g., "Home Server", "Work Server")
- **Server URL**: The actual URL of the server
- **Active Server**: The currently selected server
- **Server Switching**: Easily switch between configured servers via the UI

Tags are stored independently of servers, so if two servers have the same folder structure, tags will be shared between them.

### Architecture

1. **FileMetadata Entity** (`domain/entities/file_metadata.dart`)
   - Stores tags, notes, and metadata for files
   - Keyed by stable identifier (server-independent)

2. **FileMetadataRepository** (`domain/repositories/file_metadata_repository.dart`)
   - Interface for managing file metadata
   - Methods: getMetadata, saveMetadata, deleteMetadata, searchByTags

3. **FileMetadataRepositoryImpl** (`data/repositories/file_metadata_repository_impl.dart`)
   - Hive-based implementation
   - Stores metadata in a separate Hive box
   - Metadata is keyed by stable identifier, not server name

4. **FileServerConfigService** (`data/services/file_server_config_service.dart`)
   - Manages multiple server configurations
   - Stores servers by server name (not URL)
   - Handles active server selection
   - Automatically migrates old single-server configs

5. **FileCubit Updates**
   - Automatically loads metadata when files are loaded
   - Provides methods to get/save/delete metadata
   - Caches metadata for performance
   - Works with any server (metadata is server-independent)

## Setup Instructions

### 1. Generate Hive Adapter

Run the build_runner to generate the Hive adapter for FileMetadataModel:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

This will generate `file_metadata_model.g.dart` with the `FileMetadataModelAdapter`.

### 2. Usage Example

```dart
// Get metadata for a file
final metadata = await fileCubit.getFileMetadata(file.stableIdentifier);

// Save tags for a file
final newMetadata = FileMetadata(
  stableIdentifier: file.stableIdentifier,
  tags: ['vacation', '2024', 'beach'],
  notes: 'Summer vacation photos',
  lastUpdated: DateTime.now(),
);
await fileCubit.saveFileMetadata(newMetadata);

// Search files by tags
final fileIds = await fileCubit.searchFilesByTags(['vacation', 'beach']);
```

## Benefits

1. **URL-Independent**: Tags persist even when server URLs change
2. **Server-Independent**: Tags persist when switching between servers (if folder structure matches)
3. **Multiple Server Support**: Configure and manage multiple servers with friendly names
4. **Efficient**: Metadata is cached and loaded in batches
5. **Searchable**: Can search for files by tags across all servers
6. **Extensible**: Easy to add more metadata fields (ratings, favorites, etc.)
7. **Backward Compatible**: Automatically migrates old single-server configurations

## Next Steps

To complete the implementation, you'll need to:

1. ✅ Run `flutter pub run build_runner build` to generate the adapter
2. ✅ Create a UI widget/dialog for adding/editing tags
3. ✅ Display tags in the file list/grid views
4. ⏳ Add tag filtering/search functionality (optional future enhancement)

## UI Implementation

### Tag Editor Dialog

The `FileTagEditorDialog` widget (`presentation/widgets/file_tag_editor_dialog.dart`) provides a complete UI for managing tags and notes:

**Features:**
- Text input for tags (comma-separated)
- Visual tag chips with delete buttons
- Notes field for additional information
- Auto-loads existing metadata
- Saves using stable identifier (server-independent)

**Usage:**
```dart
// Open tag editor for a file
await FileTagEditorDialog.show(context, file, fileCubit);
```

**Access Methods:**
- **Long press** on any file in grid or list view to open tag editor
- Tags are displayed as chips in list view
- Tag count indicator shown in grid view

### Tag Display

**Grid View:**
- Tag count badge in top-left corner (if file has tags)
- Long press to edit tags

**List View:**
- Tags displayed as chips below file info
- Shows up to 3 tags, with "+X more" indicator
- Tag icon in trailing area if file has tags
- Long press to edit tags

## Server Management Example

```dart
// Get the config service
final configService = FileServerConfigService();

// Add a new server
final newServer = FileServerConfig(
  serverName: 'Home Server',
  baseUrl: 'https://home-server.com/files',
  username: 'user',
  password: 'pass',
);
await configService.saveConfig(newServer);
await configService.setActiveServerName('Home Server');

// Switch to another server
final allServers = await configService.getAllConfigs();
final workServer = allServers.firstWhere((s) => s.serverName == 'Work Server');
await configService.setActiveServerName(workServer.serverName);

// Get active server
final activeConfig = await configService.getActiveConfig();
```

## Important Notes

1. **Tag Persistence Across Servers**: Tags are stored by stable identifier, not server name. This means:
   - If Server A has `/photos/2024/vacation.jpg` with tags `['vacation', 'beach']`
   - And Server B also has `/photos/2024/vacation.jpg` (same folder structure)
   - The tags will appear on both servers automatically

2. **Server Name vs URL**: Servers are identified by their friendly name, not URL. This allows:
   - Changing a server's URL without losing configuration
   - Having multiple entries pointing to the same server with different names
   - Easy server management and switching

3. **Stable Identifier Format**: The stable identifier is `{folder}/{name}` where:
   - `folder` is the relative path from the server root (e.g., `/photos/2024`)
   - `name` is the filename (e.g., `vacation.jpg`)
   - Leading/trailing slashes are normalized

## Migration Notes

### FileMetadataModel
- TypeId 31 is used for FileMetadataModel (check migration_notes.md)
- Metadata is stored in a separate Hive box: `file_tracker_metadata_box`
- No migration needed for existing files - metadata will be empty until tags are added

### FileServerConfigModel
- TypeId 30 is used for FileServerConfigModel
- **Field Order (for backward compatibility)**:
  - Field 0: `baseUrl` (existing)
  - Field 1: `username` (existing)
  - Field 2: `password` (existing)
  - Field 3: `serverName` (new, nullable)
- **Automatic Migration**:
  - Old configs (stored with key 'config') are automatically migrated
  - Server name is auto-generated from URL if missing
  - Old single-server configs are converted to named servers
  - Migration happens on first access via `FileServerConfigService`

### Storage Structure
- **Server Configs**: Stored in `file_tracker_config_box` with server name as key
- **Active Server**: Stored in `file_tracker_config_box_active` box
- **File Metadata**: Stored in `file_tracker_metadata_box` with stable identifier as key

### Backup and Restore

File tracker data is fully integrated with the app's backup and restore system:

**Backed Up Data:**
- ✅ All server configurations (server name, URL, credentials)
- ✅ Active server selection
- ✅ All file metadata (tags, notes) with stable identifiers

**Restore Behavior:**
- Server configurations are restored with their names and settings
- Active server is restored if it exists in the backup
- File metadata (tags, notes) are restored using stable identifiers
- Tags remain intact even if server URLs change after restore

**Important Notes:**
- Server credentials (username/password) are backed up in plain text (same as other tracker data)
- Tags are restored by stable identifier, so they will appear on files with matching folder structure
- If you restore to a different device, tags will work as long as the folder structure matches

## User Guide

### Adding Tags to Files

1. **Long press** on any file (image or video) in either grid or list view
2. The tag editor dialog will open
3. Enter tags separated by commas (e.g., "vacation, beach, 2024")
4. Optionally add notes about the file
5. Tap "Save" to store the tags

### Viewing Tags

- **Grid View**: Files with tags show a badge with tag count in the top-left corner
- **List View**: Tags are displayed as chips below the file information
- Tag icon appears in the trailing area for files with tags

### Tag Persistence

- Tags are automatically saved and persist across:
  - Server URL changes
  - Server switches
  - App restarts
- Tags are shared between servers if they have the same folder structure
- Example: If you tag `/photos/2024/vacation.jpg` on Server A, the same tags will appear on Server B if it also has `/photos/2024/vacation.jpg`

