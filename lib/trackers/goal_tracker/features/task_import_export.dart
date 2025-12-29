// lib/features/tasks/task_import_export.dart
/*
  purpose:
    - Helpers for importing/exporting Task data to/from XLSX files.
    - Thin DTO layer for spreadsheet I/O mapping columns to domain Task fields:
      id, name, target_date, milestone_id/milestone_name, goal_name, status.

  serialization rules:
    - id: optional in import. When present, update existing; when absent, create new.
    - name: required for import rows; empty names are skipped.
    - target_date: nullable; exported DD/MM/YYYY; import accepts DateTime objects,
      ISO-like strings, or common localized formats (dd/mm/yyyy, dd-mm-yyyy, dd.mm.yyyy).
    - milestone_id: required for import rows (cannot create without association).
      Supports milestone_name as alternative — will be resolved to milestone_id.
    - goal_name: read-only for export (derived from milestone); not used for import.
    - status: exported/imported as 'To Do', 'In Progress', 'Complete'. Defaults to 'To Do'.

  compatibility guidance:
    - Header mapping is case-insensitive and normalized by removing spaces/underscores.
    - Keep canonical header names stable: id, name, target_date, milestone_id, milestone_name, status.
    - If you change date format or add columns, update docs and migration notes accordingly.
*/

import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as p;

import '../domain/entities/task.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/models/goal_model.dart';
import '../data/models/milestone_model.dart';
import '../core/constants.dart';
import '../presentation/bloc/task_cubit.dart';

String _formatDateDdMmYyyy(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

DateTime? _parseExcelDate(dynamic raw) {
  if (raw == null) return null;
  if (raw is DateTime) return raw;
  final s = raw.toString().trim();
  if (s.isEmpty) return null;

  try {
    return DateTime.parse(s);
  } catch (_) {}

  final parts = s.split(RegExp(r'[\/\-\.\s]'));
  if (parts.length >= 3) {
    try {
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      if (year > 0 && month >= 1 && month <= 12 && day >= 1 && day <= 31) {
        return DateTime(year, month, day);
      }
    } catch (_) {}
  }
  return null;
}

String? _normalizeStatus(String? raw) {
  if (raw == null) return null;
  final s = raw.trim();
  if (s.isEmpty) return null;
  
  const validStatuses = ['To Do', 'In Progress', 'Complete'];
  for (final status in validStatuses) {
    if (status.toLowerCase() == s.toLowerCase()) return status;
  }
  return null;
}

Future<String?> exportTasksToXlsx(BuildContext context, List<Task> tasks) async {
  // Build maps from Hive to export human-readable names
  final Map<String, String> milestoneNameById = () {
    try {
      final box = Hive.box<MilestoneModel>(milestoneBoxName);
      return {for (final m in box.values) m.id: m.name};
    } catch (_) {
      return <String, String>{};
    }
  }();

  final Map<String, String> goalNameById = () {
    try {
      final box = Hive.box<GoalModel>(goalBoxName);
      return {for (final g in box.values) g.id: g.name};
    } catch (_) {
      return <String, String>{};
    }
  }();

  final excel = Excel.createExcel();
  final sheetName = excel.getDefaultSheet() ?? 'Sheet1';
  final Sheet sheet = excel[sheetName];

  // Header: id, name, target_date, milestone_name, goal_name, status
  final header = <CellValue?>[
    TextCellValue('id'),
    TextCellValue('name'),
    TextCellValue('target_date'),
    TextCellValue('milestone_name'),
    TextCellValue('goal_name'),
    TextCellValue('status'),
  ];
  sheet.appendRow(header);

  for (final t in tasks) {
    final mName = t.milestoneId != null ? (milestoneNameById[t.milestoneId] ?? '') : '';
    final gName = t.goalId != null ? (goalNameById[t.goalId] ?? '') : '';
    final List<CellValue?> row = <CellValue?>[
      t.id.isEmpty ? null : TextCellValue(t.id),
      t.name.isEmpty ? null : TextCellValue(t.name),
      (t.targetDate == null) ? null : TextCellValue(_formatDateDdMmYyyy(t.targetDate!)),
      mName.isEmpty ? null : TextCellValue(mName),
      gName.isEmpty ? null : TextCellValue(gName),
      TextCellValue(t.status),
    ];
    sheet.appendRow(row);
  }

  // Add second sheet listing available milestone names
  final String listSheetName = 'MilestoneNames';
  final Sheet listSheet = excel[listSheetName];
  listSheet.appendRow(<CellValue?>[TextCellValue('Available Milestones')]);
  final names = milestoneNameById.values.toSet().toList()..sort();
  for (final n in names) {
    listSheet.appendRow(<CellValue?>[TextCellValue(n)]);
  }

  final List<int>? bytes = excel.encode();
  if (bytes == null) throw Exception('Failed to encode Excel file');

  final Uint8List fileData = Uint8List.fromList(bytes);
  final String fileName = 'tasks_export_${DateTime.now().toIso8601String()}.xlsx';

  try {
    Directory baseDir;
    if (Platform.isAndroid) {
      final dir = await getExternalStorageDirectory();
      baseDir = dir ?? await getApplicationDocumentsDirectory();
    } else {
      baseDir = await getApplicationDocumentsDirectory();
    }

    final String destPath = p.join(baseDir.path, fileName);
    final File destFile = File(destPath);
    await destFile.create(recursive: true);
    await destFile.writeAsBytes(fileData, flush: true);

    try {
      await Share.shareXFiles([XFile(destPath)], text: 'Tasks export');
    } catch (shareError) {
      debugPrint('Share failed: $shareError');
    }

    return destPath;
  } catch (e, st) {
    debugPrint('Export failed: $e\n$st');
    if (!context.mounted) return null;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export failed')),
    );
    return null;
  }
}

Future<void> importTasksFromXlsx(BuildContext context) async {
  try {
    final XTypeGroup excelGroup = const XTypeGroup(
      label: 'excel',
      extensions: <String>['xlsx', 'xls'],
    );

    final XFile? picked = await openFile(acceptedTypeGroups: <XTypeGroup>[excelGroup]);
    if (picked == null) return; // user canceled

    final Uint8List bytes = await picked.readAsBytes();
    final excel = Excel.decodeBytes(bytes);
    if (excel.tables.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('No sheets found in Excel file.')));
      return;
    }

    final String firstSheet = excel.tables.keys.first;
    final Sheet? sheet = excel.tables[firstSheet];
    if (sheet == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Sheet parsing failed.')));
      return;
    }

    final rows = sheet.rows;
    if (rows.isEmpty || rows.length == 1) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Excel file contains no data rows.')));
      return;
    }

    final headerRaw =
        rows.first.map((cell) => (cell?.value ?? '').toString().trim().toLowerCase()).toList();
    final headerNormalized = headerRaw.map((h) => h.replaceAll(RegExp(r'[_\s]'), '')).toList();

    final idIdx = headerNormalized.indexOf('id');
    final nameIdx = headerNormalized.indexOf('name');
    final targetIdx = headerNormalized.indexOf('targetdate');
    final statusIdx = headerNormalized.indexOf('status');
    // Support both legacy 'milestone_id' and new 'milestone_name'
    final milestoneIdIdx = headerNormalized.indexOf('milestoneid');
    final milestoneNameIdx = headerNormalized.indexOf('milestonename');

    if (nameIdx == -1) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Template invalid: "name" column is required.')));
      return;
    }

    if (!context.mounted) return;
    final cubit = context.read<TaskCubit>();
    int created = 0, updated = 0, skipped = 0;

    // Build a name->id map from Hive to resolve milestone_name on import
    final Map<String, String> milestoneIdByName = () {
      try {
        final box = Hive.box<MilestoneModel>(milestoneBoxName);
        return {for (final m in box.values) m.name: m.id};
      } catch (_) {
        return <String, String>{};
      }
    }();

    for (var r = 1; r < rows.length; r++) {
      final row = rows[r];

      String? id = (idIdx != -1 && idIdx < row.length) ? (row[idIdx]?.value?.toString() ?? '').trim() : null;
      final String? name = (nameIdx < row.length) ? (row[nameIdx]?.value?.toString() ?? '').trim() : null;

      DateTime? parsedTarget;
      if (targetIdx != -1 && targetIdx < row.length) {
        final dynamic raw = row[targetIdx]?.value;
        parsedTarget = _parseExcelDate(raw);
      }

      String? status = 'To Do';
      if (statusIdx != -1 && statusIdx < row.length) {
        final String rawStatus = (row[statusIdx]?.value?.toString() ?? '').trim();
        final normalized = _normalizeStatus(rawStatus);
        if (normalized != null) status = normalized;
      }

      String? milestoneId;
      if (milestoneIdIdx != -1 && milestoneIdIdx < row.length) {
        milestoneId = (row[milestoneIdIdx]?.value?.toString() ?? '').trim();
      } else if (milestoneNameIdx != -1 && milestoneNameIdx < row.length) {
        final String milestoneName = (row[milestoneNameIdx]?.value?.toString() ?? '').trim();
        milestoneId = milestoneIdByName[milestoneName];
      }

      if (name == null || name.isEmpty) {
        skipped++;
        continue;
      }
      if (milestoneId == null || milestoneId.isEmpty) {
        skipped++;
        continue; // cannot create task without milestone linkage
      }

      if (id != null && id.isNotEmpty) {
        try {
          await cubit.editTask(
            id: id,
            name: name,
            targetDate: parsedTarget,
            milestoneId: milestoneId,
            status: status,
          );
          updated++;
        } catch (_) {
          await cubit.addTask(
            name: name,
            targetDate: parsedTarget,
            milestoneId: milestoneId,
            status: status,
          );
          created++;
        }
      } else {
        await cubit.addTask(
          name: name,
          targetDate: parsedTarget,
          milestoneId: milestoneId,
          status: status,
        );
        created++;
      }
    }

    // Refresh
    await cubit.loadTasks();

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Import complete — created: $created, updated: $updated, skipped: $skipped')),
    );
  } catch (e, st) {
    debugPrint('Import error: $e\n$st');
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Import failed: ${e.toString()}')));
  }
}

Future<String?> downloadTasksTemplate(BuildContext context) async {
  final excel = Excel.createExcel();
  final sheetName = excel.getDefaultSheet() ?? 'Sheet1';
  final Sheet sheet = excel[sheetName];

  // Header with milestone_name
  sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value = 'id' as dynamic;
  sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0)).value = 'name' as dynamic;
  sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 0)).value = 'target_date' as dynamic;
  sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 0)).value = 'milestone_name' as dynamic;
  sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 0)).value = 'status' as dynamic;

  // Add second sheet listing milestone names
  final String listSheetName = 'MilestoneNames';
  final Sheet listSheet = excel[listSheetName];
  listSheet.appendRow(<CellValue?>[TextCellValue('Available Milestones')]);
  final List<String> milestoneNames = () {
    try {
      final box = Hive.box<MilestoneModel>(milestoneBoxName);
      return box.values.map((m) => m.name).toSet().toList()..sort();
    } catch (_) {
      return <String>[];
    }
  }();
  for (final n in milestoneNames) {
    listSheet.appendRow(<CellValue?>[TextCellValue(n)]);
  }

  // Add third sheet listing valid statuses
  final String statusSheetName = 'ValidStatuses';
  final Sheet statusSheet = excel[statusSheetName];
  statusSheet.appendRow(<CellValue?>[TextCellValue('Valid Status Values')]);
  for (final status in ['To Do', 'In Progress', 'Complete']) {
    statusSheet.appendRow(<CellValue?>[TextCellValue(status)]);
  }

  final List<int>? bytes = excel.encode();
  if (bytes == null) throw Exception('Failed to encode Excel template');
  final Uint8List fileData = Uint8List.fromList(bytes);
  final String fileName = 'tasks_template.xlsx';

  try {
    final FileSaveLocation? saveLocation = await getSaveLocation(
      acceptedTypeGroups: <XTypeGroup>[
        const XTypeGroup(label: 'excel', extensions: <String>['xlsx'])
      ],
      suggestedName: fileName,
    );

    if (saveLocation != null) {
      final XFile out = XFile.fromData(
        fileData,
        mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        name: fileName,
      );
      await out.saveTo(saveLocation.path);
      return saveLocation.path;
    }
  } catch (_) {}

  final dir = await getApplicationDocumentsDirectory();
  final fallbackPath = p.join(dir.path, fileName);
  final file = File(fallbackPath);
  await file.writeAsBytes(fileData, flush: true);
  try {
    await Share.shareXFiles([XFile(fallbackPath)], text: 'Tasks import template');
  } catch (_) {}
  return fallbackPath;
}

const MethodChannel _androidSaveChannel = MethodChannel('app.channel.savefile');

Future<String?> androidSaveFile(Uint8List bytes, String fileName) async {
  if (!defaultTargetPlatform.toString().contains('android')) return null;
  try {
    final result = await _androidSaveChannel.invokeMethod<Object?>(
      'saveFile',
      <String, dynamic>{
        'fileName': fileName,
        'bytes': bytes,
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

