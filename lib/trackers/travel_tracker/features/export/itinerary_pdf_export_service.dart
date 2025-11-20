import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../domain/entities/trip.dart';
import '../../domain/entities/itinerary_day.dart';
import '../../domain/entities/itinerary_item.dart';
import '../../core/constants.dart';

/// Service for exporting itinerary as PDF.
class ItineraryPdfExportService {
  /// Generate PDF from trip itinerary.
  Future<pw.Document> generateItineraryPdf({
    required Trip trip,
    required List<ItineraryDay> days,
    required Map<String, List<ItineraryItem>> itemsByDay,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text(
                trip.title,
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
            ),
            if (trip.destination != null)
              pw.Text(
                'Destination: ${trip.destination}',
                style: pw.TextStyle(fontSize: 14),
              ),
            if (trip.startDate != null || trip.endDate != null)
              pw.Text(
                _formatDateRange(trip.startDate, trip.endDate),
                style: pw.TextStyle(fontSize: 12),
              ),
            pw.SizedBox(height: 20),
            ...days.map((day) {
              final items = itemsByDay[day.id] ?? [];
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Header(
                    level: 1,
                    child: pw.Text(
                      _formatDate(day.date),
                      style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  if (day.notes != null && day.notes!.isNotEmpty)
                    pw.Text(
                      day.notes!,
                      style: pw.TextStyle(fontSize: 12, fontStyle: pw.FontStyle.italic),
                    ),
                  pw.SizedBox(height: 10),
                  ...items.map((item) {
                    return pw.Container(
                      margin: const pw.EdgeInsets.only(bottom: 8),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            _formatTime(item.time),
                            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                          ),
                          pw.SizedBox(width: 10),
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  item.title,
                                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                                ),
                                pw.Text(
                                  itineraryItemTypeLabels[item.type]!,
                                  style: pw.TextStyle(fontSize: 10),
                                ),
                                if (item.location != null)
                                  pw.Text(
                                    'Location: ${item.location}',
                                    style: pw.TextStyle(fontSize: 10),
                                  ),
                                if (item.notes != null && item.notes!.isNotEmpty)
                                  pw.Text(
                                    item.notes!,
                                    style: pw.TextStyle(fontSize: 10),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  pw.SizedBox(height: 20),
                ],
              );
            }),
          ];
        },
      ),
    );

    return pdf;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateRange(DateTime? start, DateTime? end) {
    if (start == null && end == null) return '';
    if (start != null && end != null) {
      return '${_formatDate(start)} - ${_formatDate(end)}';
    }
    if (start != null) {
      return 'From ${_formatDate(start)}';
    }
    return 'Until ${_formatDate(end!)}';
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

