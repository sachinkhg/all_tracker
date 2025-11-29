// lib/features/goals/goal_import_export.dart
/* 
  purpose:
    - Helpers for importing/exporting Goal data to/from XLSX files.
    - Acts as a thin DTO layer for spreadsheet I/O: maps spreadsheet columns
      to the domain Goal entity fields (id, name, description, targetDate, context, isCompleted).
    - NOT a Hive model file — however these helpers must remain compatible with
      the domain entity shape used by the rest of the app.

  serialization rules:
    - id: optional in import. When present, used to update an existing goal; when absent, a new goal is created.
    - name: required for import rows. Empty/blank names will cause the row to be skipped.
    - description: nullable/empty string allowed.
    - target_date: nullable. Exported in DD/MM/YYYY format. Import accepts DateTime objects,
      ISO-like strings, or common localized formats (dd/mm/yyyy, dd-mm-yyyy, dd.mm.yyyy).
    - context: nullable. When importing, values are validated case-insensitively against kContextOptions;
      invalid values are treated as null (no update).
    - is_completed: exported as "Yes"/"No". Import accepts booleans, numeric 1/0, and common yes/no strings.
      If missing, defaults to false for import (the caller can decide otherwise in cubit methods).

  compatibility guidance:
    - Spreadsheet column order is flexible: headers are mapped case-insensitively and normalized (underscores/spaces removed).
    - Do NOT reuse or rename existing header tokens without updating any documentation and migration notes.
    - If you add new exported/imported columns, update migration_notes.md and README/ARCHITECTURE where import/export is referenced.
    - Keep column canonical names stable: id, name, description, target_date, context, is_completed.
    - Changing the date serialization format requires communicating the change to users and updating parsing helpers (_parseExcelDate).
*/

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as p;

import '../domain/entities/goal.dart';
import '../presentation/bloc/goal_cubit.dart';
import '../core/constants.dart'; // <-- adjust path if your constants file is elsewhere

String _formatDateDdMmYyyy(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

/// Attempts to parse various representations of dates found in Excel cells.
/// Accepts:
///  - DateTime objects (some excel libs return DateTime directly)
///  - ISO-like strings (DateTime.parse)
///  - Common localized formats: dd/mm/yyyy, dd-mm-yyyy, dd.mm.yyyy
///
/// Returns null when parsing fails or input is empty.
///
/// Note: If you change accepted formats, update header docs and migration notes.
DateTime? _parseExcelDate(dynamic raw) {
  if (raw == null) return null;
  if (raw is DateTime) return raw;
  final s = raw.toString().trim();
  if (s.isEmpty) return null;

  // Try ISO-like parse first (covers "2024-01-02T..." and "2024-01-02")
  try {
    return DateTime.parse(s);
  } catch (_) {}

  // Try dd/mm/yyyy or variations
  final parts = s.split(RegExp(r'[\/\-\.\s]'));
  if (parts.length >= 3) {
    try {
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      // Basic validity check — protects against malformed values
      if (year > 0 && month >= 1 && month <= 12 && day >= 1 && day <= 31) {
        return DateTime(year, month, day);
      }
    } catch (_) {
      // fallthrough to null
    }
  }

  return null;
}

/// Validate and canonicalize a context value read from Excel against kContextOptions.
///
/// Returns:
///  - the canonical option from kContextOptions if matched case-insensitively
///  - null if not matched or blank
///
/// Rationale:
///  - Keeps storage consistent (avoids storing "Home" vs "home" vs "HOME")
String? _normalizeAndValidateContext(String? raw) {
  if (raw == null) return null;
  final s = raw.trim();
  if (s.isEmpty) return null;
  for (final opt in kContextOptions) {
    if (opt.toLowerCase() == s.toLowerCase()) return opt; // return canonical spelling
  }
  return null;
}

/// Parse a cell into a boolean for is_completed column.
/// Accepts:
///  - bool true/false
///  - numeric 1/0
///  - strings: 'yes','y','true','1' -> true; 'no','n','false','0' -> false
///
/// Returns null when the cell is empty/blank — caller interprets as default (we use false).
bool? _parseYesNo(dynamic raw) {
  if (raw == null) return null;
  if (raw is bool) return raw;
  if (raw is num) {
    return raw != 0;
  }
  final s = raw.toString().trim().toLowerCase();
  if (s.isEmpty) return null;
  const trueValues = {'yes', 'y', 'true', '1', 't'};
  const falseValues = {'no', 'n', 'false', '0', 'f'};
  if (trueValues.contains(s)) return true;
  if (falseValues.contains(s)) return false;
  // fallback: try parsing as int
  try {
    final v = int.parse(s);
    return v != 0;
  } catch (_) {}
  return null;
}

/// Export a list of [goals] into an XLSX file and trigger system share/save.
///
/// Returns the saved file path on success, or null on failure.
///
/// Notes:
///  - Columns exported: id, name, description, target_date (DD/MM/YYYY), context, is_completed (Yes/No)
///  - target_date uses DD/MM/YYYY for human-readability; import accepts multiple formats.
Future<String?> exportGoalsToXlsx(BuildContext context, List<Goal> goals) async {
  final excel = Excel.createExcel();
  final sheetName = excel.getDefaultSheet() ?? 'Sheet1';
  final Sheet sheet = excel[sheetName];

  // Build header as List<CellValue?> (include target_date, context, is_completed)
  final header = <CellValue?>[
    TextCellValue('id'),
    TextCellValue('name'),
    TextCellValue('description'),
    TextCellValue('target_date'), // <--- target date (DD/MM/YYYY)
    TextCellValue('context'), // <--- new context column
    TextCellValue('is_completed'), // <--- new completion column (Yes/No)
  ];
  sheet.appendRow(header);

  // Build rows
  for (var g in goals) {
    final desc = g.description;
    final target = g.targetDate;
    final contextVal = (g.context == null || g.context!.isEmpty) ? null : g.context;

    // Convert isCompleted boolean to "Yes"/"No" for user-friendly export
    final String isCompletedStr = (g.isCompleted == true) ? 'Yes' : 'No';

    final List<CellValue?> row = <CellValue?>[
      g.id.isEmpty ? null : TextCellValue(g.id),
      g.name.isEmpty ? null : TextCellValue(g.name),
      (desc == null || desc.isEmpty) ? null : TextCellValue(desc),
      (target == null) ? null : TextCellValue(_formatDateDdMmYyyy(target)),
      (contextVal == null) ? null : TextCellValue(contextVal),
      TextCellValue(isCompletedStr),
    ];
    sheet.appendRow(row);
  }

  // Encode
  final List<int>? bytes = excel.encode();
  if (bytes == null) throw Exception('Failed to encode Excel file');

  final Uint8List fileData = Uint8List.fromList(bytes);
  final String fileName = 'goals_export_${DateTime.now().toIso8601String()}.xlsx';

  try {
    // Choose appropriate directory (app-specific; no runtime permissions required)
    Directory baseDir;
    if (Platform.isAndroid) {
      // External app-specific directory (e.g., /storage/emulated/0/Android/data/your.package/files)
      final dir = await getExternalStorageDirectory();
      baseDir = dir ?? await getApplicationDocumentsDirectory();
    } else {
      // iOS / others: use application documents
      baseDir = await getApplicationDocumentsDirectory();
    }

    final String destPath = p.join(baseDir.path, fileName);
    final File destFile = File(destPath);
    await destFile.create(recursive: true);
    await destFile.writeAsBytes(fileData, flush: true);

    // Let the user share/save the file using system share dialog
    try {
      await Share.shareXFiles([XFile(destPath)], text: 'Goals export');
    } catch (shareError) {
      debugPrint('Share failed: $shareError');
    }

    return destPath;
  } catch (e, st) {
    debugPrint('Export failed: $e\n$st');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export failed')),
    );
    return null;
  }
}

/// Import goals from an XLSX file selected by the user using file_selector.
///
/// Behaviour summary:
///  - Reads the first sheet.
///  - First row is treated as header and is normalized (lowercased, spaces/underscores removed).
///  - Required column: 'name'. Optional: id, description, target_date, context, is_completed.
///  - When 'id' is present and non-empty, attempts to edit existing goal; on failure falls back to create.
///  - When 'id' is absent, creates a new goal.
///
/// Shows user-facing SnackBars for common error states.
///
/// Important:
///  - Header matching is flexible but relies on canonical tokens:
///    id, name, description, target_date (normalized to 'targetdate'), context, is_completed (normalized to 'iscompleted')
Future<void> importGoalsFromXlsx(BuildContext context) async {
  try {
    // Filter for xlsx/xls
    final XTypeGroup excelGroup = const XTypeGroup(
      label: 'excel',
      extensions: <String>['xlsx', 'xls'],
    );

    final XFile? picked = await openFile(acceptedTypeGroups: <XTypeGroup>[excelGroup]);

    if (picked == null) {
      // user cancelled
      return;
    }

    final Uint8List bytes = await picked.readAsBytes();
    final excel = Excel.decodeBytes(bytes);

    if (excel.tables.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No sheets found in Excel file.')));
      return;
    }

    final String firstSheet = excel.tables.keys.first;
    final Sheet? sheet = excel.tables[firstSheet];
    if (sheet == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sheet parsing failed.')));
      return;
    }

    final rows = sheet.rows;
    if (rows.isEmpty || rows.length == 1) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Excel file contains no data rows.')));
      return;
    }

    // map header (case-insensitive), and normalize (remove spaces/underscores) to find target_date variants
    final headerRaw = rows.first.map((cell) => (cell?.value ?? '').toString().trim().toLowerCase()).toList();
    final headerNormalized = headerRaw.map((h) => h.replaceAll(RegExp(r'[_\s]'), '')).toList();

    final idIdx = headerNormalized.indexOf('id');
    final nameIdx = headerNormalized.indexOf('name');
    final descIdx = headerNormalized.indexOf('description');
    final contextIdx = headerNormalized.indexOf('context');
    final targetIdx = headerNormalized.indexOf('targetdate'); // matches 'target_date', 'target date', 'targetdate'
    final isCompletedIdx = headerNormalized.indexOf('iscompleted'); // matches 'is_completed', 'is completed', 'iscompleted'

    if (nameIdx == -1) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Template invalid: "name" column is required.')));
      return;
    }

    if (!context.mounted) return;
    final cubit = context.read<GoalCubit>();
    int created = 0, updated = 0, skipped = 0;

    for (var r = 1; r < rows.length; r++) {
      final row = rows[r];

      String? id = (idIdx != -1 && idIdx < row.length) ? (row[idIdx]?.value?.toString() ?? '').trim() : null;
      final String? name = (nameIdx < row.length) ? (row[nameIdx]?.value?.toString() ?? '').trim() : null;
      final String desc = (descIdx != -1 && descIdx < row.length) ? (row[descIdx]?.value?.toString() ?? '').trim() : '';
      final String? contextColRaw = (contextIdx != -1 && contextIdx < row.length) ? (row[contextIdx]?.value?.toString() ?? '').trim() : null;

      DateTime? parsedTarget;
      if (targetIdx != -1 && targetIdx < row.length) {
        final dynamic raw = row[targetIdx]?.value;
        parsedTarget = _parseExcelDate(raw);
      }

      // parse isCompleted (if present). Default to false if null/empty.
      bool parsedIsCompleted = false;
      if (isCompletedIdx != -1 && isCompletedIdx < row.length) {
        final dynamic raw = row[isCompletedIdx]?.value;
        final bool? parsed = _parseYesNo(raw);
        if (parsed != null) parsedIsCompleted = parsed;
      }

      if (name == null || name.isEmpty) {
        skipped++;
        continue;
      }

      // Validate context against allowed options. If not valid -> null (do not update)
      final String? contextToUse = _normalizeAndValidateContext(contextColRaw);

      if (id != null && id.isNotEmpty) {
        try {
          // Pass parsedTarget, contextToUse, and isCompleted (both may be null/false)
          // NOTE: editGoal signature is assumed to accept isCompleted as last parameter.
          await cubit.editGoal(id, name, desc, parsedTarget, contextToUse, parsedIsCompleted);
          updated++;
        } catch (e) {
          // fallback to create if edit fails
          await cubit.addGoal(name, desc, parsedTarget, contextToUse, parsedIsCompleted);
          created++;
        }
      } else {
        // NOTE: addGoal signature is assumed to accept isCompleted as last parameter.
        await cubit.addGoal(name, desc, parsedTarget, contextToUse, parsedIsCompleted);
        created++;
      }
    }

    // Refresh
    cubit.loadGoals();

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Import complete — created: $created, updated: $updated, skipped: $skipped')),
    );
  } catch (e, st) {
    debugPrint('Import error: $e\n$st');
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import failed: ${e.toString()}')));
  }
}

/// Generate and offer a header-only template XLSX for users to download or share.
///
/// Template columns (canonical names): id, name, description, target_date, context, is_completed
///
/// Notes:
///  - Uses getSaveLocation where desktop/desktop-like environments are available,
///    otherwise falls back to saving to application documents and triggering a share.
Future<String?> downloadGoalsTemplate(BuildContext context) async {
  final excel = Excel.createExcel();
  final sheetName = excel.getDefaultSheet() ?? 'Sheet1';
  final Sheet sheet = excel[sheetName];

  // header (include target_date, context, is_completed)
  sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value = 'id' as dynamic;
  sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0)).value = 'name' as dynamic;
  sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 0)).value = 'description' as dynamic;
  sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 0)).value = 'target_date' as dynamic;
  sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 0)).value = 'context' as dynamic;
  sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: 0)).value = 'is_completed' as dynamic;

  final List<int>? bytes = excel.encode();
  if (bytes == null) throw Exception('Failed to encode Excel template');

  final Uint8List fileData = Uint8List.fromList(bytes);
  final String fileName = 'goals_template.xlsx';

  // Try desktop save dialog
  try {
    final FileSaveLocation? saveLocation = await getSaveLocation(
      acceptedTypeGroups: <XTypeGroup>[
        const XTypeGroup(label: 'excel', extensions: <String>['xlsx'])
      ],
      suggestedName: fileName,
    );

    if (saveLocation != null) {
      final XFile out = XFile.fromData(fileData, mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', name: fileName);
      await out.saveTo(saveLocation.path);
      return saveLocation.path;
    }
  } catch (_) {
    // fall back to mobile behavior below
  }

  // Fallback for mobile: save to documents and share
  final dir = await getApplicationDocumentsDirectory();
  final fallbackPath = '${dir.path}/$fileName';
  final file = File(fallbackPath);
  await file.writeAsBytes(fileData, flush: true);
  try {
    await Share.shareXFiles([XFile(fallbackPath)], text: 'Goals import template');
  } catch (_) {}
  return fallbackPath;
}

const MethodChannel _androidSaveChannel = MethodChannel('app.channel.savefile');

/// Requests Android Save As dialog and writes [bytes] into the chosen location with [fileName].
/// Returns a platform-specific string (URI path) on success, or null if user cancelled / failed.
///
/// Platform note:
///  - This method is a no-op (returns null) on non-Android platforms.
///  - The 'saveFile' method name is expected to be implemented in Android native layer.
///  - The bytes are sent binary-safe via standard method channel codec.
///
/// Error handling:
///  - PlatformException logs the message and returns null.
Future<String?> androidSaveFile(Uint8List bytes, String fileName) async {
  if (!defaultTargetPlatform.toString().contains('android')) return null;

  try {
    final result = await _androidSaveChannel.invokeMethod<Object?>(
      'saveFile',
      <String, dynamic>{
        'fileName': fileName,
        'bytes': bytes, // Binary-safe via standard method channel codec
      },
    );

    if (result is String) return result;
    return null;
  } on PlatformException catch (e) {
    debugPrint('androidSaveFile PlatformException: ${e.message}');
    return null;
  } catch (e) {
    debugPrint('androidSaveFile error: $e');
    return null;
  }
}
