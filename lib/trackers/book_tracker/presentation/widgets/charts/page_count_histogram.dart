import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../domain/usecases/book/get_page_count_distribution.dart';

class PageCountHistogram extends StatelessWidget {
  final List<PageCountRangeDataPoint> dataPoints;

  const PageCountHistogram({
    super.key,
    required this.dataPoints,
  });

  @override
  Widget build(BuildContext context) {
    if (dataPoints.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('No page count data available'),
        ),
      );
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final maxCount = dataPoints.isNotEmpty
        ? dataPoints.map((p) => p.bookCount).reduce((a, b) => a > b ? a : b)
        : 1;

    return SizedBox(
      height: 300,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: (maxCount * 1.2).ceil().toDouble(),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              tooltipRoundedRadius: 8,
              tooltipPadding: const EdgeInsets.all(8),
              tooltipBgColor: colorScheme.surfaceContainerHighest,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  rod.toY.toInt().toString(),
                  TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 60,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= dataPoints.length) {
                    return const Text('');
                  }
                  final range = dataPoints[index].rangeLabel;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Center(
                      child: Transform.rotate(
                        angle: -1.5708, // -90 degrees in radians
                        alignment: Alignment.center,
                        child: Text(
                          range,
                          style: TextStyle(
                            fontSize: 10,
                            color: colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: _calculateInterval(maxCount),
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      fontSize: 10,
                      color: colorScheme.onSurface,
                    ),
                  );
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: _calculateInterval(maxCount),
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: colorScheme.outline.withValues(alpha: 0.2),
                strokeWidth: 1,
              );
            },
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          barGroups: dataPoints.asMap().entries.map((entry) {
            final index = entry.key;
            final dataPoint = entry.value;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: dataPoint.bookCount.toDouble(),
                  color: colorScheme.primary,
                  width: 20,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  double _calculateInterval(int maxCount) {
    if (maxCount <= 5) return 1;
    if (maxCount <= 10) return 2;
    if (maxCount <= 20) return 5;
    return 10;
  }
}

