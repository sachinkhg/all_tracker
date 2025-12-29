import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../domain/usecases/book/get_reread_statistics.dart';

class RereadPieChart extends StatelessWidget {
  final RereadStatistics statistics;

  const RereadPieChart({
    super.key,
    required this.statistics,
  });

  @override
  Widget build(BuildContext context) {
    if (statistics.total == 0) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('No reading data available'),
        ),
      );
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      height: 300,
      child: Row(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 60,
                sections: [
                  PieChartSectionData(
                    value: statistics.firstReads.toDouble(),
                    title: '${statistics.firstReads}',
                    color: colorScheme.primary,
                    radius: 50,
                    titleStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                  PieChartSectionData(
                    value: statistics.rereads.toDouble(),
                    title: '${statistics.rereads}',
                    color: colorScheme.secondary,
                    radius: 50,
                    titleStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LegendItem(
                color: colorScheme.primary,
                label: 'First Read',
                count: statistics.firstReads,
              ),
              const SizedBox(height: 8),
              _LegendItem(
                color: colorScheme.secondary,
                label: 'Re-read',
                count: statistics.rereads,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final int count;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: $count',
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }
}

