// lib/trackers/book_tracker/features/book_import_export.dart
/* 
  purpose:
    - Helpers for importing/exporting Book data to/from XLSX files.
    - Acts as a thin DTO layer for spreadsheet I/O: maps spreadsheet columns
      to the domain Book entity fields.
    - NOT a Hive model file — however these helpers must remain compatible with
      the domain entity shape used by the rest of the app.

  serialization rules:
    - id: optional in import. When present, used to update an existing book; when absent, a new book is created.
    - title: required for import rows. Empty/blank titles will cause the row to be skipped.
    - primaryAuthor: required for import rows.
    - pageCount: required for import rows. Must be > 0.
    - avgRating: optional in import. Must be 0-5 if present.
    - datePublished: optional in import. Accepts various date formats.
    - dateStarted: optional in import. Accepts various date formats.
    - dateRead: optional in import. Accepts various date formats.
    - created_at: optional in import. If missing, defaults to current timestamp.
    - updated_at: optional in import. If missing, defaults to current timestamp.
    - delete: optional in import. When set to "Yes", "Y", "1", "True", or any truthy value, and id is present,
      the book with that id will be deleted. If delete is marked but id is missing, the row is skipped.

  compatibility guidance:
    - Spreadsheet column order is flexible: headers are mapped case-insensitively and normalized (underscores/spaces removed).
    - Do NOT reuse or rename existing header tokens without updating any documentation and migration notes.
    - If you add new exported/imported columns, update migration_notes.md and README/ARCHITECTURE where import/export is referenced.
    - Keep column canonical names stable: id, title, primaryAuthor, pageCount, avgRating, datePublished, dateStarted, dateRead, created_at, updated_at, delete.
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

import '../domain/entities/book.dart';
import '../presentation/bloc/book_cubit.dart';

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

/// Parse a cell into a double for rating column.
/// Accepts:
///  - numeric values (int, double)
///  - strings that can be parsed as numbers
///
/// Returns null when the cell is empty/blank or cannot be parsed.
double? _parseRating(dynamic raw) {
  if (raw == null) return null;
  if (raw is num) {
    final value = raw.toDouble();
    if (value >= 0 && value <= 5) return value;
    return null; // Out of range
  }
  final s = raw.toString().trim();
  if (s.isEmpty) return null;
  try {
    final value = double.parse(s);
    if (value >= 0 && value <= 5) return value;
    return null; // Out of range
  } catch (_) {
    return null;
  }
}

/// Parse a cell into an int for pageCount column.
/// Accepts:
///  - numeric values (int, double)
///  - strings that can be parsed as numbers
///
/// Returns null when the cell is empty/blank or cannot be parsed.
int? _parsePageCount(dynamic raw) {
  if (raw == null) return null;
  if (raw is num) {
    final value = raw.toInt();
    if (value > 0) return value;
    return null; // Must be > 0
  }
  final s = raw.toString().trim();
  if (s.isEmpty) return null;
  try {
    final value = int.parse(s);
    if (value > 0) return value;
    return null; // Must be > 0
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
  if (s == 'yes' || s == 'y' || s == 'true' || s == '1') return true;
  if (s == 'no' || s == 'n' || s == 'false' || s == '0') return false;
  return null;
}

/// Export books to an XLSX file.
///
/// Creates a file with columns: id, title, primaryAuthor, pageCount, avgRating,
/// datePublished, dateStarted, dateRead, created_at, updated_at.
///
/// Returns the path to the exported file, or null on failure.
Future<String?> exportBooksToXlsx(BuildContext context, List<Book> books) async {
  final excel = Excel.createExcel();
  excel.delete('Sheet1');
  final Sheet sheet = excel['Books'];

  // Headers
  sheet.appendRow([
    TextCellValue('id'),
    TextCellValue('title'),
    TextCellValue('primaryAuthor'),
    TextCellValue('pageCount'),
    TextCellValue('avgRating'),
    TextCellValue('datePublished'),
    TextCellValue('dateStarted'),
    TextCellValue('dateRead'),
    TextCellValue('created_at'),
    TextCellValue('updated_at'),
  ]);

  // Data rows
  for (final book in books) {
    final row = [
      TextCellValue(book.id),
      TextCellValue(book.title),
      TextCellValue(book.primaryAuthor),
      TextCellValue(book.pageCount.toString()),
      book.avgRating != null
          ? TextCellValue(book.avgRating!.toString())
          : null,
      book.datePublished != null
          ? TextCellValue(_formatDateDdMmYyyy(book.datePublished!))
          : null,
      book.dateStarted != null
          ? TextCellValue(_formatDateDdMmYyyy(book.dateStarted!))
          : null,
      book.dateRead != null
          ? TextCellValue(_formatDateDdMmYyyy(book.dateRead!))
          : null,
      TextCellValue(_formatDateDdMmYyyy(book.createdAt)),
      TextCellValue(_formatDateDdMmYyyy(book.updatedAt)),
    ];
    sheet.appendRow(row);
  }

  // Encode
  final List<int>? bytes = excel.encode();
  if (bytes == null) throw Exception('Failed to encode Excel file');

  final Uint8List fileData = Uint8List.fromList(bytes);
  final String fileName = 'books_export_${DateTime.now().toIso8601String()}.xlsx';

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
      await Share.shareXFiles([XFile(destPath)], text: 'Books export');
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

/// Import books from an XLSX file selected by the user using file_selector.
///
/// Behaviour summary:
///  - Reads the first sheet.
///  - First row is treated as header and is normalized (lowercased, spaces/underscores removed).
///  - Required columns: 'title', 'primaryAuthor', 'pageCount'. Optional: id, avgRating, datePublished, dateStarted, dateRead, created_at, updated_at.
///  - When 'id' is present and non-empty, attempts to edit existing book; on failure falls back to create.
///  - When 'id' is absent, creates a new book.
///  - If multiple reads exist in imported data, only the latest read populates active dates.
///
/// Shows user-facing SnackBars for common error states.
Future<void> importBooksFromXlsx(BuildContext context) async {
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
    final titleIdx = headerNormalized.indexOf('title');
    final authorIdx = headerNormalized.indexOf('primaryauthor');
    final pageCountIdx = headerNormalized.indexOf('pagecount');
    final ratingIdx = headerNormalized.indexOf('avgrating');
    final datePublishedIdx = headerNormalized.indexOf('datepublished');
    final dateStartedIdx = headerNormalized.indexOf('datestarted');
    final dateReadIdx = headerNormalized.indexOf('dateread');
    final createdAtIdx = headerNormalized.indexOf('createdat');
    final updatedAtIdx = headerNormalized.indexOf('updatedat');
    final deleteIdx = headerNormalized.indexOf('delete');

    // Validate required columns
    if (titleIdx == -1) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Template invalid: "title" column is required.')),
      );
      return;
    }
    if (authorIdx == -1) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Template invalid: "primaryAuthor" column is required.')),
      );
      return;
    }
    if (pageCountIdx == -1) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Template invalid: "pageCount" column is required.')),
      );
      return;
    }

    if (!context.mounted) return;
    final cubit = context.read<BookCubit>();
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

      // If delete is marked and id is present, delete the book
      if (shouldDelete && id != null && id.isNotEmpty) {
        try {
          await cubit.deleteBook(id);
          deleted++;
          continue;
        } catch (e) {
          debugPrint('Failed to delete book $id: $e');
          skipped++;
          continue;
        }
      }

      // If delete is marked but no id, skip this row
      if (shouldDelete) {
        skipped++;
        continue;
      }

      // Parse title (required)
      final String? title =
          (titleIdx < row.length) ? (row[titleIdx]?.value?.toString() ?? '').trim() : null;
      if (title == null || title.isEmpty) {
        skipped++;
        continue;
      }

      // Parse author (required)
      final String? author =
          (authorIdx < row.length) ? (row[authorIdx]?.value?.toString() ?? '').trim() : null;
      if (author == null || author.isEmpty) {
        skipped++;
        continue;
      }

      // Parse pageCount (required)
      int? pageCount;
      if (pageCountIdx < row.length) {
        final dynamic raw = row[pageCountIdx]?.value;
        pageCount = _parsePageCount(raw);
      }
      if (pageCount == null || pageCount <= 0) {
        skipped++;
        continue;
      }

      // Parse optional fields
      double? rating;
      if (ratingIdx != -1 && ratingIdx < row.length) {
        final dynamic raw = row[ratingIdx]?.value;
        rating = _parseRating(raw);
      }

      DateTime? datePublished;
      if (datePublishedIdx != -1 && datePublishedIdx < row.length) {
        final dynamic raw = row[datePublishedIdx]?.value;
        datePublished = _parseExcelDate(raw);
      }

      DateTime? dateStarted;
      if (dateStartedIdx != -1 && dateStartedIdx < row.length) {
        final dynamic raw = row[dateStartedIdx]?.value;
        dateStarted = _parseExcelDate(raw);
      }

      DateTime? dateRead;
      if (dateReadIdx != -1 && dateReadIdx < row.length) {
        final dynamic raw = row[dateReadIdx]?.value;
        dateRead = _parseExcelDate(raw);
      }

      // Validate: dateRead >= dateStarted
      if (dateStarted != null && dateRead != null && dateRead.isBefore(dateStarted)) {
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
          // Try to update existing book
          final existing = await cubit.getBookById(id);
          if (existing != null) {
            final updatedBook = existing.copyWith(
              title: title,
              primaryAuthor: author,
              pageCount: pageCount,
              avgRating: rating,
              datePublished: datePublished,
              dateStarted: dateStarted,
              dateRead: dateRead,
              updatedAt: updatedAt,
            );
            await cubit.updateBook(updatedBook);
            updated++;
          } else {
            // Book not found, create new
            await cubit.createBook(
              title: title,
              primaryAuthor: author,
              pageCount: pageCount,
              avgRating: rating,
              datePublished: datePublished,
              dateStarted: dateStarted,
              dateRead: dateRead,
            );
            created++;
          }
        } else {
          // Create new book
          await cubit.createBook(
            title: title,
            primaryAuthor: author,
            pageCount: pageCount,
            avgRating: rating,
            datePublished: datePublished,
            dateStarted: dateStarted,
            dateRead: dateRead,
          );
          created++;
        }
      } catch (e) {
        debugPrint('Failed to import book row: $e');
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

/// Downloads a template XLSX file for book import.
///
/// Returns the path to the downloaded template file, or null on failure.
Future<String?> downloadBooksTemplate(BuildContext context) async {
  final excel = Excel.createExcel();
  excel.delete('Sheet1');
  final Sheet sheet = excel['Books'];

  // Headers only
  sheet.appendRow([
    TextCellValue('title'),
    TextCellValue('primaryAuthor'),
    TextCellValue('pageCount'),
    TextCellValue('avgRating'),
    TextCellValue('datePublished'),
    TextCellValue('dateStarted'),
    TextCellValue('dateRead'),
  ]);

  // Encode
  final List<int>? bytes = excel.encode();
  if (bytes == null) throw Exception('Failed to encode Excel file');

  final Uint8List fileData = Uint8List.fromList(bytes);
  final String fileName = 'books_template.xlsx';

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
      await Share.shareXFiles([XFile(destPath)], text: 'Books import template');
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

