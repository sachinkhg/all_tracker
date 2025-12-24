// lib/trackers/portfolio_tracker/features/investment_import_export.dart
/* 
  purpose:
    - Helpers for importing/exporting InvestmentMaster data to/from XLSX files.
    - Acts as a thin DTO layer for spreadsheet I/O: maps spreadsheet columns
      to the domain InvestmentMaster entity fields.
    - NOT a Hive model file — however these helpers must remain compatible with
      the domain entity shape used by the rest of the app.

  serialization rules:
    - id: optional in import. When present, used to update an existing investment; when absent, a new investment is created.
    - shortName: required for import rows. Empty/blank shortName will cause the row to be skipped.
    - name: required for import rows.
    - investmentCategory: required for import rows. Must match one of the enum values (case-insensitive).
    - investmentTrackingType: required for import rows. Must be "unit" or "amount" (case-insensitive).
    - investmentCurrency: required for import rows. Must be "inr" or "usd" (case-insensitive).
    - riskFactor: required for import rows. Must be "insane", "high", "medium", or "low" (case-insensitive).
    - created_at: optional in import. If missing, defaults to current timestamp.
    - updated_at: optional in import. If missing, defaults to current timestamp.
    - delete: optional in import. When set to "Yes", "Y", "1", "True", or any truthy value, and id is present,
      the investment with that id will be deleted. If delete is marked but id is missing, the row is skipped.

  compatibility guidance:
    - Spreadsheet column order is flexible: headers are mapped case-insensitively and normalized (underscores/spaces removed).
    - Do NOT reuse or rename existing header tokens without updating any documentation and migration notes.
    - If you add new exported/imported columns, update migration_notes.md and README/ARCHITECTURE where import/export is referenced.
    - Keep column canonical names stable: id, shortName, name, investmentCategory, investmentTrackingType, investmentCurrency, riskFactor, created_at, updated_at, delete.
    - Changing the date serialization format requires communicating the change to users and updating parsing helpers (_parseExcelDate).
*/

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:excel/excel.dart';
import 'package:file_selector/file_selector.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as p;

import '../domain/entities/investment_master.dart';
import '../domain/entities/investment_category.dart';
import '../domain/entities/investment_tracking_type.dart';
import '../domain/entities/investment_currency.dart';
import '../domain/entities/risk_factor.dart';
import '../presentation/bloc/investment_master_cubit.dart';

String _formatDateDdMmYyyy(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

/// Attempts to parse various representations of dates found in Excel cells.
/// Accepts:
///  - DateTime objects (some excel libs return DateTime directly)
///  - ISO-like strings (DateTime.parse)
///  - Common localized formats: dd/mm/yyyy, dd-mm-yyyy, dd.mm.yyyy
///
/// Returns null when parsing fails or input is empty.
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
  if (s == 'yes' || s == 'y' || s == 'true' || s == '1') return true;
  if (s == 'no' || s == 'n' || s == 'false' || s == '0') return false;
  return null;
}

/// Parse investment category from string (case-insensitive).
/// Accepts both enum name and display name.
InvestmentCategory? _parseInvestmentCategory(String? raw) {
  if (raw == null) return null;
  final s = raw.trim().toLowerCase();
  try {
    return InvestmentCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == s || 
             e.displayName.toLowerCase() == s ||
             e.displayName.toLowerCase().replaceAll(' ', '').replaceAll('-', '') == s,
    );
  } catch (_) {
    return null;
  }
}

/// Parse investment tracking type from string (case-insensitive).
/// Accepts both enum name and display name.
InvestmentTrackingType? _parseInvestmentTrackingType(String? raw) {
  if (raw == null) return null;
  final s = raw.trim().toLowerCase();
  try {
    return InvestmentTrackingType.values.firstWhere(
      (e) => e.name.toLowerCase() == s || e.displayName.toLowerCase() == s,
    );
  } catch (_) {
    return null;
  }
}

/// Parse investment currency from string (case-insensitive).
/// Accepts both enum name and display name.
InvestmentCurrency? _parseInvestmentCurrency(String? raw) {
  if (raw == null) return null;
  final s = raw.trim().toLowerCase();
  try {
    return InvestmentCurrency.values.firstWhere(
      (e) => e.name.toLowerCase() == s || e.displayName.toLowerCase() == s,
    );
  } catch (_) {
    return null;
  }
}

/// Parse risk factor from string (case-insensitive).
/// Accepts both enum name and display name.
RiskFactor? _parseRiskFactor(String? raw) {
  if (raw == null) return null;
  final s = raw.trim().toLowerCase();
  try {
    return RiskFactor.values.firstWhere(
      (e) => e.name.toLowerCase() == s || e.displayName.toLowerCase() == s,
    );
  } catch (_) {
    return null;
  }
}

/// Export investment masters to an XLSX file.
///
/// Creates a file with columns: id, shortName, name, investmentCategory,
/// investmentTrackingType, investmentCurrency, riskFactor, created_at, updated_at.
/// Also includes a Reference sheet with all valid enum values.
///
/// Returns the path to the exported file, or null on failure.
Future<String?> exportInvestmentMastersToXlsx(
    BuildContext context, List<InvestmentMaster> investments) async {
  final excel = Excel.createExcel();
  excel.delete('Sheet1');
  final Sheet investmentsSheet = excel['Investments'];
  final Sheet referenceSheet = excel['Reference'];

  // Headers for Investments sheet
  investmentsSheet.appendRow([
    TextCellValue('id'),
    TextCellValue('shortName'),
    TextCellValue('name'),
    TextCellValue('investmentCategory'),
    TextCellValue('investmentTrackingType'),
    TextCellValue('investmentCurrency'),
    TextCellValue('riskFactor'),
    TextCellValue('created_at'),
    TextCellValue('updated_at'),
  ]);

  // Data rows
  for (final investment in investments) {
    final row = [
      TextCellValue(investment.id),
      TextCellValue(investment.shortName),
      TextCellValue(investment.name),
      TextCellValue(investment.investmentCategory.displayName),
      TextCellValue(investment.investmentTrackingType.displayName),
      TextCellValue(investment.investmentCurrency.displayName),
      TextCellValue(investment.riskFactor.displayName),
      TextCellValue(_formatDateDdMmYyyy(investment.createdAt)),
      TextCellValue(_formatDateDdMmYyyy(investment.updatedAt)),
    ];
    investmentsSheet.appendRow(row);
  }

  // Reference sheet with all valid enum values
  referenceSheet.appendRow([
    TextCellValue('Field'),
    TextCellValue('Valid Values'),
    TextCellValue('Description'),
  ]);

  // Investment Category options
  referenceSheet.appendRow([
    TextCellValue('investmentCategory'),
    TextCellValue(InvestmentCategory.values.map((e) => e.name).join(', ')),
    TextCellValue('Category of the investment'),
  ]);
  for (final category in InvestmentCategory.values) {
    referenceSheet.appendRow([
      TextCellValue(''),
      TextCellValue('  - ${category.name}'),
      TextCellValue('(${category.displayName})'),
    ]);
  }

  referenceSheet.appendRow([null, null, null]); // Empty row

  // Investment Tracking Type options
  referenceSheet.appendRow([
    TextCellValue('investmentTrackingType'),
    TextCellValue(InvestmentTrackingType.values.map((e) => e.name).join(', ')),
    TextCellValue('Type of tracking (unit or amount)'),
  ]);
  for (final type in InvestmentTrackingType.values) {
    referenceSheet.appendRow([
      TextCellValue(''),
      TextCellValue('  - ${type.name}'),
      TextCellValue('(${type.displayName})'),
    ]);
  }

  referenceSheet.appendRow([null, null, null]); // Empty row

  // Investment Currency options
  referenceSheet.appendRow([
    TextCellValue('investmentCurrency'),
    TextCellValue(InvestmentCurrency.values.map((e) => e.name).join(', ')),
    TextCellValue('Currency of the investment'),
  ]);
  for (final currency in InvestmentCurrency.values) {
    referenceSheet.appendRow([
      TextCellValue(''),
      TextCellValue('  - ${currency.name}'),
      TextCellValue('(${currency.displayName})'),
    ]);
  }

  referenceSheet.appendRow([null, null, null]); // Empty row

  // Risk Factor options
  referenceSheet.appendRow([
    TextCellValue('riskFactor'),
    TextCellValue(RiskFactor.values.map((e) => e.name).join(', ')),
    TextCellValue('Risk level of the investment'),
  ]);
  for (final risk in RiskFactor.values) {
    referenceSheet.appendRow([
      TextCellValue(''),
      TextCellValue('  - ${risk.name}'),
      TextCellValue('(${risk.displayName})'),
    ]);
  }

  // Encode
  final List<int>? bytes = excel.encode();
  if (bytes == null) throw Exception('Failed to encode Excel file');

  final Uint8List fileData = Uint8List.fromList(bytes);
  final String fileName =
      'investments_export_${DateTime.now().toIso8601String()}.xlsx';

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
      await Share.shareXFiles([XFile(destPath)], text: 'Investments export');
    } catch (shareError) {
      debugPrint('Share failed: $shareError');
    }

    return destPath;
  } catch (e, st) {
    debugPrint('Export failed: $e\n$st');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Export failed')),
      );
    }
    return null;
  }
}

/// Import investment masters from an XLSX file selected by the user using file_selector.
///
/// Behaviour summary:
///  - Reads the first sheet.
///  - First row is treated as header and is normalized (lowercased, spaces/underscores removed).
///  - Required columns: 'shortName', 'name', 'investmentCategory', 'investmentTrackingType', 'investmentCurrency', 'riskFactor'.
///  - Optional: id, created_at, updated_at.
///  - When 'id' is present and non-empty, attempts to edit existing investment; on failure falls back to create.
///  - When 'id' is absent, creates a new investment.
///
/// Shows user-facing SnackBars for common error states.
Future<void> importInvestmentMastersFromXlsx(BuildContext context) async {
  try {
    final XTypeGroup excelGroup = const XTypeGroup(
      label: 'excel',
      extensions: <String>['xlsx', 'xls'],
      uniformTypeIdentifiers: <String>[
        'org.openxmlformats.spreadsheetml.sheet',
        'com.microsoft.excel.xls',
        'public.data',
      ],
    );

    final XFile? picked = await openFile(acceptedTypeGroups: <XTypeGroup>[excelGroup]);

    if (picked == null) {
      return;
    }

    final Uint8List bytes = await picked.readAsBytes();
    final excel = Excel.decodeBytes(bytes);

    if (excel.tables.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No sheets found in Excel file.')),
      );
      return;
    }

    final String firstSheet = excel.tables.keys.first;
    final Sheet? sheet = excel.tables[firstSheet];
    if (sheet == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sheet parsing failed.')),
      );
      return;
    }

    final rows = sheet.rows;
    if (rows.isEmpty || rows.length == 1) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Excel file contains no data rows.')),
      );
      return;
    }

    // Map header (case-insensitive), and normalize (remove spaces/underscores)
    final headerRaw = rows.first
        .map((cell) => (cell?.value ?? '').toString().trim().toLowerCase())
        .toList();
    final headerNormalized =
        headerRaw.map((h) => h.replaceAll(RegExp(r'[_\s]'), '')).toList();

    final idIdx = headerNormalized.indexOf('id');
    final shortNameIdx = headerNormalized.indexOf('shortname');
    final nameIdx = headerNormalized.indexOf('name');
    final categoryIdx = headerNormalized.indexOf('investmentcategory');
    final trackingTypeIdx = headerNormalized.indexOf('investmenttrackingtype');
    final currencyIdx = headerNormalized.indexOf('investmentcurrency');
    final riskFactorIdx = headerNormalized.indexOf('riskfactor');
    final createdAtIdx = headerNormalized.indexOf('createdat');
    final updatedAtIdx = headerNormalized.indexOf('updatedat');
    final deleteIdx = headerNormalized.indexOf('delete');

    // Validate required columns
    if (shortNameIdx == -1) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Template invalid: "shortName" column is required.')),
      );
      return;
    }
    if (nameIdx == -1) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Template invalid: "name" column is required.')),
      );
      return;
    }
    if (categoryIdx == -1) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Template invalid: "investmentCategory" column is required.')),
      );
      return;
    }
    if (trackingTypeIdx == -1) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Template invalid: "investmentTrackingType" column is required.')),
      );
      return;
    }
    if (currencyIdx == -1) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Template invalid: "investmentCurrency" column is required.')),
      );
      return;
    }
    if (riskFactorIdx == -1) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Template invalid: "riskFactor" column is required.')),
      );
      return;
    }

    if (!context.mounted) return;
    final cubit = context.read<InvestmentMasterCubit>();
    int created = 0;
    int updated = 0;
    int skipped = 0;
    int deleted = 0;

    for (var r = 1; r < rows.length; r++) {
      final row = rows[r];

      String? id = (idIdx != -1 && idIdx < row.length)
          ? (row[idIdx]?.value?.toString() ?? '').trim()
          : null;

      // Check if delete column is marked
      bool shouldDelete = false;
      if (deleteIdx != -1 && deleteIdx < row.length) {
        final dynamic deleteRaw = row[deleteIdx]?.value;
        final bool? deleteValue = _parseYesNo(deleteRaw);
        shouldDelete = deleteValue == true;
      }

      // If delete is marked and id is present, delete the investment
      if (shouldDelete && id != null && id.isNotEmpty) {
        try {
          await cubit.deleteInvestmentMaster(id);
          deleted++;
          continue;
        } catch (e) {
          debugPrint('Failed to delete investment $id: $e');
          skipped++;
          continue;
        }
      }

      // If delete is marked but no id, skip this row
      if (shouldDelete) {
        skipped++;
        continue;
      }

      // Parse shortName (required)
      final String? shortName = (shortNameIdx < row.length)
          ? (row[shortNameIdx]?.value?.toString() ?? '').trim()
          : null;
      if (shortName == null || shortName.isEmpty) {
        skipped++;
        continue;
      }

      // Parse name (required)
      final String? name =
          (nameIdx < row.length) ? (row[nameIdx]?.value?.toString() ?? '').trim() : null;
      if (name == null || name.isEmpty) {
        skipped++;
        continue;
      }

      // Parse investmentCategory (required)
      final String? categoryRaw = (categoryIdx < row.length)
          ? (row[categoryIdx]?.value?.toString() ?? '').trim()
          : null;
      final InvestmentCategory? category = _parseInvestmentCategory(categoryRaw);
      if (category == null) {
        skipped++;
        continue;
      }

      // Parse investmentTrackingType (required)
      final String? trackingTypeRaw = (trackingTypeIdx < row.length)
          ? (row[trackingTypeIdx]?.value?.toString() ?? '').trim()
          : null;
      final InvestmentTrackingType? trackingType = _parseInvestmentTrackingType(trackingTypeRaw);
      if (trackingType == null) {
        skipped++;
        continue;
      }

      // Parse investmentCurrency (required)
      final String? currencyRaw = (currencyIdx < row.length)
          ? (row[currencyIdx]?.value?.toString() ?? '').trim()
          : null;
      final InvestmentCurrency? currency = _parseInvestmentCurrency(currencyRaw);
      if (currency == null) {
        skipped++;
        continue;
      }

      // Parse riskFactor (required)
      final String? riskFactorRaw = (riskFactorIdx < row.length)
          ? (row[riskFactorIdx]?.value?.toString() ?? '').trim()
          : null;
      final RiskFactor? riskFactor = _parseRiskFactor(riskFactorRaw);
      if (riskFactor == null) {
        skipped++;
        continue;
      }

      DateTime? createdAt;
      if (createdAtIdx != -1 && createdAtIdx < row.length) {
        final dynamic raw = row[createdAtIdx]?.value;
        createdAt = _parseExcelDate(raw);
      }
      createdAt ??= DateTime.now();

      DateTime? updatedAt;
      if (updatedAtIdx != -1 && updatedAtIdx < row.length) {
        final dynamic raw = row[updatedAtIdx]?.value;
        updatedAt = _parseExcelDate(raw);
      }
      updatedAt ??= DateTime.now();

      try {
        if (id != null && id.isNotEmpty) {
          // Try to update existing investment
          final existing = await cubit.getInvestmentMasterById(id);
          if (existing != null) {
            final updatedInvestment = existing.copyWith(
              shortName: shortName,
              name: name,
              investmentCategory: category,
              investmentTrackingType: trackingType,
              investmentCurrency: currency,
              riskFactor: riskFactor,
              updatedAt: updatedAt,
            );
            await cubit.updateInvestmentMaster(updatedInvestment);
            updated++;
          } else {
            // Investment not found, create new
            await cubit.createInvestmentMaster(
              shortName: shortName,
              name: name,
              investmentCategory: category,
              investmentTrackingType: trackingType,
              investmentCurrency: currency,
              riskFactor: riskFactor,
            );
            created++;
          }
        } else {
          // Create new investment
          await cubit.createInvestmentMaster(
            shortName: shortName,
            name: name,
            investmentCategory: category,
            investmentTrackingType: trackingType,
            investmentCurrency: currency,
            riskFactor: riskFactor,
          );
          created++;
        }
      } catch (e) {
        debugPrint('Failed to import investment row: $e');
        skipped++;
      }
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Import complete: $created created, $updated updated, $deleted deleted, $skipped skipped',
        ),
      ),
    );
  } catch (e, st) {
    debugPrint('Import failed: $e\n$st');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Import failed')),
      );
    }
  }
}

/// Downloads a template XLSX file for investment import.
///
/// Returns the path to the downloaded template file, or null on failure.
/// Includes a reference sheet with all valid enum values.
Future<String?> downloadInvestmentTemplate(BuildContext context) async {
  final excel = Excel.createExcel();
  excel.delete('Sheet1');
  final Sheet investmentsSheet = excel['Investments'];
  final Sheet referenceSheet = excel['Reference'];

  // Headers for Investments sheet
  investmentsSheet.appendRow([
    TextCellValue('shortName'),
    TextCellValue('name'),
    TextCellValue('investmentCategory'),
    TextCellValue('investmentTrackingType'),
    TextCellValue('investmentCurrency'),
    TextCellValue('riskFactor'),
  ]);

  // Add example row with valid enum values
  investmentsSheet.appendRow([
    TextCellValue('AAPL'),
    TextCellValue('Apple Inc.'),
    TextCellValue('usShare'),
    TextCellValue('unit'),
    TextCellValue('usd'),
    TextCellValue('high'),
  ]);

  // Reference sheet with all valid enum values
  referenceSheet.appendRow([
    TextCellValue('Field'),
    TextCellValue('Valid Values'),
    TextCellValue('Description'),
  ]);

  // Investment Category options
  referenceSheet.appendRow([
    TextCellValue('investmentCategory'),
    TextCellValue(InvestmentCategory.values.map((e) => e.name).join(', ')),
    TextCellValue('Category of the investment'),
  ]);
  for (final category in InvestmentCategory.values) {
    referenceSheet.appendRow([
      TextCellValue(''),
      TextCellValue('  - ${category.name}'),
      TextCellValue('(${category.displayName})'),
    ]);
  }

  referenceSheet.appendRow([null, null, null]); // Empty row

  // Investment Tracking Type options
  referenceSheet.appendRow([
    TextCellValue('investmentTrackingType'),
    TextCellValue(InvestmentTrackingType.values.map((e) => e.name).join(', ')),
    TextCellValue('Type of tracking (unit or amount)'),
  ]);
  for (final type in InvestmentTrackingType.values) {
    referenceSheet.appendRow([
      TextCellValue(''),
      TextCellValue('  - ${type.name}'),
      TextCellValue('(${type.displayName})'),
    ]);
  }

  referenceSheet.appendRow([null, null, null]); // Empty row

  // Investment Currency options
  referenceSheet.appendRow([
    TextCellValue('investmentCurrency'),
    TextCellValue(InvestmentCurrency.values.map((e) => e.name).join(', ')),
    TextCellValue('Currency of the investment'),
  ]);
  for (final currency in InvestmentCurrency.values) {
    referenceSheet.appendRow([
      TextCellValue(''),
      TextCellValue('  - ${currency.name}'),
      TextCellValue('(${currency.displayName})'),
    ]);
  }

  referenceSheet.appendRow([null, null, null]); // Empty row

  // Risk Factor options
  referenceSheet.appendRow([
    TextCellValue('riskFactor'),
    TextCellValue(RiskFactor.values.map((e) => e.name).join(', ')),
    TextCellValue('Risk level of the investment'),
  ]);
  for (final risk in RiskFactor.values) {
    referenceSheet.appendRow([
      TextCellValue(''),
      TextCellValue('  - ${risk.name}'),
      TextCellValue('(${risk.displayName})'),
    ]);
  }

  // Encode
  final List<int>? bytes = excel.encode();
  if (bytes == null) throw Exception('Failed to encode Excel file');

  final Uint8List fileData = Uint8List.fromList(bytes);
  final String fileName = 'investments_template.xlsx';

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
      await Share.shareXFiles([XFile(destPath)], text: 'Investments import template');
    } catch (shareError) {
      debugPrint('Share failed: $shareError');
    }

    return destPath;
  } catch (e, st) {
    debugPrint('Template download failed: $e\n$st');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Template download failed')),
      );
    }
    return null;
  }
}

