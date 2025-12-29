import 'package:flutter/material.dart';
import '../../../domain/usecases/book/get_top_authors_data.dart';

class TopAuthorsChart extends StatelessWidget {
  final List<TopAuthorDataPoint> dataPoints;

  const TopAuthorsChart({
    super.key,
    required this.dataPoints,
  });

  @override
  Widget build(BuildContext context) {
    if (dataPoints.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('No author data available'),
        ),
      );
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Limit to top 5
    final top5Authors = dataPoints.take(5).toList();

    return Table(
      border: TableBorder.all(
        color: colorScheme.outline.withValues(alpha: 0.2),
        width: 1,
      ),
      columnWidths: const {
        0: FlexColumnWidth(3),
        1: FlexColumnWidth(1),
      },
      children: [
        // Header row
        TableRow(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
          ),
          children: [
            TableCell(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  'Author Name',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            TableCell(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  'Count',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
        // Data rows
        ...top5Authors.map((dataPoint) {
          return TableRow(
            children: [
              TableCell(
                verticalAlignment: TableCellVerticalAlignment.middle,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    dataPoint.author,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ),
              TableCell(
                verticalAlignment: TableCellVerticalAlignment.middle,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    dataPoint.bookCount.toString(),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ],
    );
  }
}

