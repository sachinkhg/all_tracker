// lib/features/milestones/milestone_import_export.dart
/*
  purpose:
    - Helpers for importing/exporting Milestone data to/from XLSX files.
    - Thin DTO layer for spreadsheet I/O mapping columns to domain Milestone fields:
      id, name, description, planned_value, actual_value, target_date, goal_id.

  serialization rules:
    - id: optional in import. When present, update existing; when absent, create new.
    - name: required for import rows; empty names are skipped.
    - description: nullable/empty allowed.
    - planned_value/actual_value: nullable; numbers or numeric strings accepted.
    - target_date: nullable; exported DD/MM/YYYY; import accepts DateTime objects,
      ISO-like strings, or common localized formats (dd/mm/yyyy, dd-mm-yyyy, dd.mm.yyyy).
    - goal_id: required for import rows (cannot create without association) — rows with
      missing goal_id are skipped.

  compatibility guidance:
    - Header mapping is case-insensitive and normalized by removing spaces/underscores.
    - Keep canonical header names stable: id, name, description, planned_value, actual_value, target_date, goal_id.
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

import '../domain/entities/milestone.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/models/goal_model.dart';
import '../core/constants.dart';
import '../presentation/bloc/milestone_cubit.dart';

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

double? _parseDouble(dynamic raw) {
  if (raw == null) return null;
  if (raw is num) return raw.toDouble();
  final s = raw.toString().trim();
  if (s.isEmpty) return null;
  return double.tryParse(s);
}

Future<String?> exportMilestonesToXlsx(BuildContext context, List<Milestone> milestones) async {
  // Build goalId -> goalName map from Hive to export human-readable names
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

  // Header: id, name, description, planned_value, actual_value, target_date, goal_name
  final header = <CellValue?>[
    TextCellValue('id'),
    TextCellValue('name'),
    TextCellValue('description'),
    TextCellValue('planned_value'),
    TextCellValue('actual_value'),
    TextCellValue('target_date'),
    TextCellValue('goal_name'),
  ];
  sheet.appendRow(header);

  for (final m in milestones) {
    final gName = goalNameById[m.goalId] ?? '';
    final List<CellValue?> row = <CellValue?>[
      m.id.isEmpty ? null : TextCellValue(m.id),
      m.name.isEmpty ? null : TextCellValue(m.name),
      (m.description == null || m.description!.isEmpty) ? null : TextCellValue(m.description!),
      (m.plannedValue == null) ? null : TextCellValue(m.plannedValue!.toString()),
      (m.actualValue == null) ? null : TextCellValue(m.actualValue!.toString()),
      (m.targetDate == null) ? null : TextCellValue(_formatDateDdMmYyyy(m.targetDate!)),
      gName.isEmpty ? null : TextCellValue(gName),
    ];
    sheet.appendRow(row);
  }

  // Add a second sheet listing available goal names to assist with manual dropdown creation
  final String listSheetName = 'GoalNames';
  final Sheet listSheet = excel[listSheetName];
  listSheet.appendRow(<CellValue?>[TextCellValue('Available Goals')]);
  final names = goalNameById.values.toSet().toList()..sort();
  for (final n in names) {
    listSheet.appendRow(<CellValue?>[TextCellValue(n)]);
  }

  final List<int>? bytes = excel.encode();
  if (bytes == null) throw Exception('Failed to encode Excel file');

  final Uint8List fileData = Uint8List.fromList(bytes);
  final String fileName = 'milestones_export_${DateTime.now().toIso8601String()}.xlsx';

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
      await Share.shareXFiles([XFile(destPath)], text: 'Milestones export');
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

Future<void> importMilestonesFromXlsx(BuildContext context) async {
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
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('No sheets found in Excel file.')));
      return;
    }

    final String firstSheet = excel.tables.keys.first;
    final Sheet? sheet = excel.tables[firstSheet];
    if (sheet == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Sheet parsing failed.')));
      return;
    }

    final rows = sheet.rows;
    if (rows.isEmpty || rows.length == 1) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Excel file contains no data rows.')));
      return;
    }

    final headerRaw =
        rows.first.map((cell) => (cell?.value ?? '').toString().trim().toLowerCase()).toList();
    final headerNormalized = headerRaw.map((h) => h.replaceAll(RegExp(r'[_\s]'), '')).toList();

    final idIdx = headerNormalized.indexOf('id');
    final nameIdx = headerNormalized.indexOf('name');
    final descIdx = headerNormalized.indexOf('description');
    final plannedIdx = headerNormalized.indexOf('plannedvalue');
    final actualIdx = headerNormalized.indexOf('actualvalue');
    final targetIdx = headerNormalized.indexOf('targetdate');
    // Support both legacy 'goal_id' and new 'goal_name'
    final goalIdIdx = headerNormalized.indexOf('goalid');
    final goalNameIdx = headerNormalized.indexOf('goalname');

    if (nameIdx == -1) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Template invalid: "name" column is required.')));
      return;
    }

    final cubit = context.read<MilestoneCubit>();
    int created = 0, updated = 0, skipped = 0;

    // Build a name->id map from Hive to resolve goal_name on import
    final Map<String, String> goalIdByName = () {
      try {
        final box = Hive.box<GoalModel>(goalBoxName);
        return {for (final g in box.values) g.name: g.id};
      } catch (_) {
        return <String, String>{};
      }
    }();

    for (var r = 1; r < rows.length; r++) {
      final row = rows[r];

      String? id = (idIdx != -1 && idIdx < row.length) ? (row[idIdx]?.value?.toString() ?? '').trim() : null;
      final String? name = (nameIdx < row.length) ? (row[nameIdx]?.value?.toString() ?? '').trim() : null;
      final String desc = (descIdx != -1 && descIdx < row.length) ? (row[descIdx]?.value?.toString() ?? '').trim() : '';

      final double? planned = (plannedIdx != -1 && plannedIdx < row.length)
          ? _parseDouble(row[plannedIdx]?.value)
          : null;
      final double? actual = (actualIdx != -1 && actualIdx < row.length)
          ? _parseDouble(row[actualIdx]?.value)
          : null;

      DateTime? parsedTarget;
      if (targetIdx != -1 && targetIdx < row.length) {
        final dynamic raw = row[targetIdx]?.value;
        parsedTarget = _parseExcelDate(raw);
      }

      String? goalId;
      if (goalIdIdx != -1 && goalIdIdx < row.length) {
        goalId = (row[goalIdIdx]?.value?.toString() ?? '').trim();
      } else if (goalNameIdx != -1 && goalNameIdx < row.length) {
        final String goalName = (row[goalNameIdx]?.value?.toString() ?? '').trim();
        goalId = goalIdByName[goalName];
      }

      if (name == null || name.isEmpty) {
        skipped++;
        continue;
      }
      if (goalId == null || goalId.isEmpty) {
        skipped++;
        continue; // cannot create milestone without goal linkage
      }

      if (id != null && id.isNotEmpty) {
        try {
          await cubit.editMilestone(
            id: id,
            name: name,
            description: desc.isEmpty ? null : desc,
            plannedValue: planned,
            actualValue: actual,
            targetDate: parsedTarget,
            goalId: goalId,
          );
          updated++;
        } catch (_) {
          await cubit.addMilestone(
            name: name,
            description: desc.isEmpty ? null : desc,
            plannedValue: planned,
            actualValue: actual,
            targetDate: parsedTarget,
            goalId: goalId,
          );
          created++;
        }
      } else {
        await cubit.addMilestone(
          name: name,
          description: desc.isEmpty ? null : desc,
          plannedValue: planned,
          actualValue: actual,
          targetDate: parsedTarget,
          goalId: goalId,
        );
        created++;
      }
    }

    // Refresh
    await cubit.loadMilestones();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Import complete — created: $created, updated: $updated, skipped: $skipped')),
    );
  } catch (e, st) {
    debugPrint('Import error: $e\n$st');
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Import failed: ${e.toString()}')));
  }
}

Future<String?> downloadMilestonesTemplate(BuildContext context) async {
  final excel = Excel.createExcel();
  final sheetName = excel.getDefaultSheet() ?? 'Sheet1';
  final Sheet sheet = excel[sheetName];

  // Header with goal_name
  sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value = 'id' as dynamic;
  sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0)).value = 'name' as dynamic;
  sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 0)).value = 'description' as dynamic;
  sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 0)).value = 'planned_value' as dynamic;
  sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 0)).value = 'actual_value' as dynamic;
  sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: 0)).value = 'target_date' as dynamic;
  sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: 0)).value = 'goal_name' as dynamic;

  // Add second sheet listing goal names
  final String listSheetName = 'GoalNames';
  final Sheet listSheet = excel[listSheetName];
  listSheet.appendRow(<CellValue?>[TextCellValue('Available Goals')]);
  final List<String> goalNames = () {
    try {
      final box = Hive.box<GoalModel>(goalBoxName);
      return box.values.map((g) => g.name).toSet().toList()..sort();
    } catch (_) {
      return <String>[];
    }
  }();
  for (final n in goalNames) {
    listSheet.appendRow(<CellValue?>[TextCellValue(n)]);
  }

  final List<int>? bytes = excel.encode();
  if (bytes == null) throw Exception('Failed to encode Excel template');
  final Uint8List fileData = Uint8List.fromList(bytes);
  final String fileName = 'milestones_template.xlsx';

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
    await Share.shareXFiles([XFile(fallbackPath)], text: 'Milestones import template');
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


