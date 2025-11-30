// lib/trackers/expense_tracker/features/expense_import_export.dart
/* 
  purpose:
    - Helpers for importing/exporting Expense data to/from XLSX files.
    - Acts as a thin DTO layer for spreadsheet I/O: maps spreadsheet columns
      to the domain Expense entity fields (id, date, description, amount, group, created_at, updated_at).
    - NOT a Hive model file — however these helpers must remain compatible with
      the domain entity shape used by the rest of the app.

  serialization rules:
    - id: optional in import. When present, used to update an existing expense; when absent, a new expense is created.
    - date: required for import rows. Exported in DD/MM/YYYY format. Import accepts DateTime objects,
      ISO-like strings, or common localized formats (dd/mm/yyyy, dd-mm-yyyy, dd.mm.yyyy).
    - description: required for import rows. Empty/blank descriptions will cause the row to be skipped.
    - amount: required for import rows. Positive values represent debits/expenses, negative values represent credits/income.
    - group: required for import rows. Values are validated case-insensitively against ExpenseGroup enum;
      invalid values are treated as null and the row is skipped.
    - created_at: optional in import. If missing, defaults to current timestamp.
    - updated_at: optional in import. If missing, defaults to current timestamp.
    - delete: optional in import. When set to "Yes", "Y", "1", "True", or any truthy value, and id is present,
      the expense with that id will be deleted. If delete is marked but id is missing, the row is skipped.

  compatibility guidance:
    - Spreadsheet column order is flexible: headers are mapped case-insensitively and normalized (underscores/spaces removed).
    - Do NOT reuse or rename existing header tokens without updating any documentation and migration notes.
    - If you add new exported/imported columns, update migration_notes.md and README/ARCHITECTURE where import/export is referenced.
    - Keep column canonical names stable: id, date, description, amount, group, created_at, updated_at, delete.
    - Changing the date serialization format requires communicating the change to users and updating parsing helpers (_parseExcelDate).
*/

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:excel/excel.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as p;

import '../domain/entities/expense.dart';
import '../domain/entities/expense_group.dart';
import '../presentation/bloc/expense_cubit.dart';

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

/// Validate and canonicalize a group value read from Excel against ExpenseGroup enum.
///
/// Returns:
///  - the ExpenseGroup enum value if matched case-insensitively
///  - null if not matched or blank
///
/// Rationale:
///  - Keeps storage consistent (avoids storing "Food" vs "food" vs "FOOD")
///  - Handles formats like "health (Health)" by extracting the name part
ExpenseGroup? _normalizeAndValidateGroup(String? raw) {
  if (raw == null) return null;
  final s = raw.trim();
  if (s.isEmpty) return null;
  
  // Handle format like "health (Health)" - extract the part before parentheses
  String groupValue = s;
  final parenMatch = RegExp(r'^(.+?)\s*\(.+\)$').firstMatch(s);
  if (parenMatch != null) {
    groupValue = parenMatch.group(1)!.trim();
  }
  
  // Try to match against enum values case-insensitively
  for (final group in ExpenseGroup.values) {
    if (group.name.toLowerCase() == groupValue.toLowerCase() ||
        group.displayName.toLowerCase() == groupValue.toLowerCase()) {
      return group;
    }
  }
  return null;
}

/// Parse a cell into a double for amount column.
/// Accepts:
///  - numeric values (int, double)
///  - strings that can be parsed as numbers
///
/// Returns null when the cell is empty/blank or cannot be parsed.
double? _parseAmount(dynamic raw) {
  if (raw == null) return null;
  if (raw is num) return raw.toDouble();
  final s = raw.toString().trim();
  if (s.isEmpty) return null;
  try {
    return double.parse(s);
  } catch (_) {
    return null;
  }
}

/// Parse a cell into a boolean for delete column.
/// Accepts:
///  - bool true/false
///  - numeric 1/0
///  - strings: 'yes','y','true','1' -> true; 'no','n','false','0' -> false
///
/// Returns null when the cell is empty/blank — caller interprets as false (no deletion).
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

/// Export a list of [expenses] into an XLSX file and trigger system share/save.
///
/// Returns the saved file path on success, or null on failure.
///
/// Notes:
///  - Columns exported: id, date (DD/MM/YYYY), description, amount, group, created_at (DD/MM/YYYY), updated_at (DD/MM/YYYY), delete
///  - date uses DD/MM/YYYY for human-readability; import accepts multiple formats.
///  - delete column is empty by default; mark with "Yes", "Y", "1", or "True" to delete the expense on import.
Future<String?> exportExpensesToXlsx(BuildContext context, List<Expense> expenses) async {
  final excel = Excel.createExcel();
  final sheetName = excel.getDefaultSheet() ?? 'Sheet1';
  final Sheet sheet = excel[sheetName];

  // Build header
  final header = <CellValue?>[
    TextCellValue('id'),
    TextCellValue('date'),
    TextCellValue('description'),
    TextCellValue('amount'),
    TextCellValue('group'),
    TextCellValue('created_at'),
    TextCellValue('updated_at'),
    TextCellValue('delete'), // Column for bulk deletion
  ];
  sheet.appendRow(header);

  // Build rows
  for (var expense in expenses) {
    final List<CellValue?> row = <CellValue?>[
      expense.id.isEmpty ? null : TextCellValue(expense.id),
      TextCellValue(_formatDateDdMmYyyy(expense.date)),
      expense.description.isEmpty ? null : TextCellValue(expense.description),
      TextCellValue(expense.amount.toString()),
      TextCellValue(expense.group.displayName),
      TextCellValue(_formatDateDdMmYyyy(expense.createdAt)),
      TextCellValue(_formatDateDdMmYyyy(expense.updatedAt)),
      null, // delete column - empty by default
    ];
    sheet.appendRow(row);
  }

  // Encode
  final List<int>? bytes = excel.encode();
  if (bytes == null) throw Exception('Failed to encode Excel file');

  final Uint8List fileData = Uint8List.fromList(bytes);
  final String fileName = 'expenses_export_${DateTime.now().toIso8601String()}.xlsx';

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
      await Share.shareXFiles([XFile(destPath)], text: 'Expenses export');
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

/// Import expenses from an XLSX file selected by the user using file_selector.
///
/// Behaviour summary:
///  - Reads the first sheet.
///  - First row is treated as header and is normalized (lowercased, spaces/underscores removed).
///  - Required columns: 'date', 'description', 'amount', 'group'. Optional: id, created_at, updated_at.
///  - When 'id' is present and non-empty, attempts to edit existing expense; on failure falls back to create.
///  - When 'id' is absent, creates a new expense.
///
/// Shows user-facing SnackBars for common error states.
///
/// Important:
///  - Header matching is flexible but relies on canonical tokens:
///    id, date, description, amount, group (normalized), created_at (normalized to 'createdat'), updated_at (normalized to 'updatedat')
Future<void> importExpensesFromXlsx(BuildContext context) async {
  try {
    // Filter for xlsx/xls
    // On iOS, we need to provide uniformTypeIdentifiers
    final XTypeGroup excelGroup = const XTypeGroup(
      label: 'excel',
      extensions: <String>['xlsx', 'xls'],
      uniformTypeIdentifiers: <String>[
        'org.openxmlformats.spreadsheetml.sheet', // .xlsx
        'com.microsoft.excel.xls', // .xls
        'public.data', // fallback for iOS
      ],
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

    // map header (case-insensitive), and normalize (remove spaces/underscores)
    final headerRaw = rows.first.map((cell) => (cell?.value ?? '').toString().trim().toLowerCase()).toList();
    final headerNormalized = headerRaw.map((h) => h.replaceAll(RegExp(r'[_\s]'), '')).toList();

    final idIdx = headerNormalized.indexOf('id');
    final dateIdx = headerNormalized.indexOf('date');
    final descIdx = headerNormalized.indexOf('description');
    final amountIdx = headerNormalized.indexOf('amount');
    final groupIdx = headerNormalized.indexOf('group');
    final createdAtIdx = headerNormalized.indexOf('createdat');
    final updatedAtIdx = headerNormalized.indexOf('updatedat');
    final deleteIdx = headerNormalized.indexOf('delete');

    // Validate required columns
    if (dateIdx == -1) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Template invalid: "date" column is required.')));
      return;
    }
    if (descIdx == -1) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Template invalid: "description" column is required.')));
      return;
    }
    if (amountIdx == -1) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Template invalid: "amount" column is required.')));
      return;
    }
    if (groupIdx == -1) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Template invalid: "group" column is required.')));
      return;
    }

    if (!context.mounted) return;
    final cubit = context.read<ExpenseCubit>();
    int created = 0, updated = 0, skipped = 0, deleted = 0;

    for (var r = 1; r < rows.length; r++) {
      final row = rows[r];

      String? id = (idIdx != -1 && idIdx < row.length) ? (row[idIdx]?.value?.toString() ?? '').trim() : null;
      
      // Check if delete column is marked
      bool shouldDelete = false;
      if (deleteIdx != -1 && deleteIdx < row.length) {
        final dynamic deleteRaw = row[deleteIdx]?.value;
        final bool? deleteValue = _parseYesNo(deleteRaw);
        shouldDelete = deleteValue == true;
      }
      
      // If delete is marked and id is present, delete the expense
      if (shouldDelete && id != null && id.isNotEmpty) {
        try {
          await cubit.deleteExpense(id);
          deleted++;
          continue; // Skip to next row
        } catch (e) {
          debugPrint('Failed to delete expense $id: $e');
          skipped++;
          continue;
        }
      }
      
      // If delete is marked but no id, skip this row
      if (shouldDelete) {
        skipped++;
        continue;
      }
      
      // Parse date (required)
      DateTime? parsedDate;
      if (dateIdx < row.length) {
        final dynamic raw = row[dateIdx]?.value;
        parsedDate = _parseExcelDate(raw);
      }
      
      // Parse description (required)
      final String? description = (descIdx < row.length) ? (row[descIdx]?.value?.toString() ?? '').trim() : null;
      
      // Parse amount (required)
      double? parsedAmount;
      if (amountIdx < row.length) {
        final dynamic raw = row[amountIdx]?.value;
        parsedAmount = _parseAmount(raw);
      }
      
      // Parse group (required)
      ExpenseGroup? parsedGroup;
      if (groupIdx < row.length) {
        final String? groupRaw = (row[groupIdx]?.value?.toString() ?? '').trim();
        parsedGroup = _normalizeAndValidateGroup(groupRaw);
      }
      
      // Parse created_at (optional)
      DateTime? parsedCreatedAt;
      if (createdAtIdx != -1 && createdAtIdx < row.length) {
        final dynamic raw = row[createdAtIdx]?.value;
        parsedCreatedAt = _parseExcelDate(raw);
      }
      
      // Parse updated_at (optional)
      DateTime? parsedUpdatedAt;
      if (updatedAtIdx != -1 && updatedAtIdx < row.length) {
        final dynamic raw = row[updatedAtIdx]?.value;
        parsedUpdatedAt = _parseExcelDate(raw);
      }

      // Validate required fields
      if (parsedDate == null) {
        skipped++;
        continue;
      }
      if (description == null || description.isEmpty) {
        skipped++;
        continue;
      }
      if (parsedAmount == null) {
        skipped++;
        continue;
      }
      if (parsedGroup == null) {
        skipped++;
        continue;
      }

      if (id != null && id.isNotEmpty) {
        try {
          // Try to update existing expense
          final existing = await cubit.getExpenseById(id);
          if (existing != null) {
            final updatedExpense = existing.copyWith(
              date: parsedDate,
              description: description,
              amount: parsedAmount,
              group: parsedGroup,
              createdAt: parsedCreatedAt ?? existing.createdAt,
              updatedAt: parsedUpdatedAt ?? DateTime.now(),
            );
            await cubit.updateExpense(updatedExpense);
            updated++;
          } else {
            // Create new if not found
            await cubit.createExpense(
              date: parsedDate,
              description: description,
              amount: parsedAmount,
              group: parsedGroup,
            );
            created++;
          }
        } catch (e) {
          // fallback to create if edit fails
          await cubit.createExpense(
            date: parsedDate,
            description: description,
            amount: parsedAmount,
            group: parsedGroup,
          );
          created++;
        }
      } else {
        // Create new expense
        await cubit.createExpense(
          date: parsedDate,
          description: description,
          amount: parsedAmount,
          group: parsedGroup,
        );
        created++;
      }
    }

    // Refresh
    await cubit.loadExpenses();

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Import complete — created: $created, updated: $updated, deleted: $deleted, skipped: $skipped')),
    );
  } catch (e, st) {
    debugPrint('Import error: $e\n$st');
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import failed: ${e.toString()}')));
  }
}

/// Generate and offer a header-only template XLSX for users to download or share.
///
/// Template columns (canonical names): id, date, description, amount, group, created_at, updated_at, delete
///
/// Notes:
///  - Uses getSaveLocation where desktop/desktop-like environments are available,
///    otherwise falls back to saving to application documents and triggering a share.
Future<String?> downloadExpensesTemplate(BuildContext context) async {
  final excel = Excel.createExcel();
  final sheetName = excel.getDefaultSheet() ?? 'Sheet1';
  final Sheet sheet = excel[sheetName];

  // header
  final header = <CellValue?>[
    TextCellValue('id'),
    TextCellValue('date'),
    TextCellValue('description'),
    TextCellValue('amount'),
    TextCellValue('group'),
    TextCellValue('created_at'),
    TextCellValue('updated_at'),
    TextCellValue('delete'), // Column for bulk deletion (use "Yes", "Y", "1", or "True" to mark for deletion)
  ];
  sheet.appendRow(header);

  // Add second sheet listing available groups
  final String listSheetName = 'ExpenseGroups';
  final Sheet listSheet = excel[listSheetName];
  listSheet.appendRow(<CellValue?>[TextCellValue('Available Expense Groups')]);
  for (final group in ExpenseGroup.values) {
    listSheet.appendRow(<CellValue?>[TextCellValue('${group.name} (${group.displayName})')]);
  }

  final List<int>? bytes = excel.encode();
  if (bytes == null) throw Exception('Failed to encode Excel template');

  final Uint8List fileData = Uint8List.fromList(bytes);
  final String fileName = 'expenses_template.xlsx';

  // Try desktop save dialog
  try {
    final FileSaveLocation? saveLocation = await getSaveLocation(
      acceptedTypeGroups: <XTypeGroup>[
        const XTypeGroup(
          label: 'excel',
          extensions: <String>['xlsx'],
          uniformTypeIdentifiers: <String>[
            'org.openxmlformats.spreadsheetml.sheet', // .xlsx
            'public.data', // fallback for iOS
          ],
        )
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
    await Share.shareXFiles([XFile(fallbackPath)], text: 'Expenses import template');
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

