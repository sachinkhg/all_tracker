// lib/features/goals/goal_import_export.dart
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

/// Try to parse a value coming from an Excel cell into a DateTime.
/// Supports:
///  - actual DateTime objects (excel package may give DateTime)
///  - ISO-like strings (DateTime.parse)
///  - dd/mm/yyyy, dd-mm-yyyy, dd.mm.yyyy
DateTime? _parseExcelDate(dynamic raw) {
  if (raw == null) return null;
  if (raw is DateTime) return raw;
  final s = raw.toString().trim();
  if (s.isEmpty) return null;

  // Try ISO-like parse first
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
      // Basic validity check
      if (year > 0 && month >= 1 && month <= 12 && day >= 1 && day <= 31) {
        return DateTime(year, month, day);
      }
    } catch (_) {
      // fallthrough to null
    }
  }

  return null;
}

/// Validate a context value read from Excel against kContextOptions.
/// Returns the canonical option (from kContextOptions) when matched (case-insensitive),
/// or null if not matched / empty.
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
/// Accepts a variety of inputs:
/// - bool true/false
/// - numeric 1/0
/// - strings: 'yes','y','true','1' -> true; 'no','n','false','0' -> false
/// Returns null when the cell is empty/blank -> caller can decide default (we use false)
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

/// Export goals to XLSX. Returns the final saved path (if available) or null.
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
      (contextVal == null) ? null : TextCellValue(contextVal!),
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

/// Import goals from selected XLSX file. Uses file_selector openFile.
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No sheets found in Excel file.')));
      return;
    }

    final String firstSheet = excel.tables.keys.first;
    final Sheet? sheet = excel.tables[firstSheet];
    if (sheet == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sheet parsing failed.')));
      return;
    }

    final rows = sheet.rows;
    if (rows.isEmpty || rows.length == 1) {
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Template invalid: "name" column is required.')));
      return;
    }

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
          await cubit.addGoal(name, desc, parsedTarget, contextToUse);
          created++;
        }
      } else {
        // NOTE: addGoal signature is assumed to accept isCompleted as last parameter.
        await cubit.addGoal(name, desc, parsedTarget, contextToUse);
        created++;
      }
    }

    // Refresh
    cubit.loadGoals();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Import complete — created: $created, updated: $updated, skipped: $skipped')),
    );
  } catch (e, st) {
    debugPrint('Import error: $e\n$st');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import failed: ${e.toString()}')));
  }
}

/// Download / share a template XLSX (header only).
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