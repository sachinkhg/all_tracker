import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../domain/usecases/book/get_reading_activity_data.dart';

class ReadingActivityChart extends StatelessWidget {
  final List<ReadingActivityDataPoint> dataPoints;

  const ReadingActivityChart({
    super.key,
    required this.dataPoints,
  });

  @override
  Widget build(BuildContext context) {
    if (dataPoints.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('No reading activity data available'),
        ),
      );
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      height: 300,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: _calculateInterval(dataPoints),
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: colorScheme.outline.withValues(alpha: 0.2),
                strokeWidth: 1,
              );
            },
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
                interval: _calculateBottomInterval(dataPoints),
                getTitlesWidget: (value, meta) {
                  if (dataPoints.isEmpty) return const Text('');
                  final index = value.toInt();
                  if (index < 0 || index >= dataPoints.length) {
                    return const Text('');
                  }
                  final date = dataPoints[index].month;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Center(
                      child: Transform.rotate(
                        angle: -1.5708, // -90 degrees in radians
                        alignment: Alignment.center,
                        child: Text(
                          DateFormat('MMM yyyy').format(date),
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
                interval: _calculateInterval(dataPoints),
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
          borderData: FlBorderData(
            show: true,
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          minX: 0,
          maxX: (dataPoints.length - 1).toDouble(),
          minY: 0,
          maxY: _calculateMaxY(dataPoints).ceilToDouble(),
          lineBarsData: [
            LineChartBarData(
              spots: dataPoints.asMap().entries.map((entry) {
                return FlSpot(entry.key.toDouble(), entry.value.bookCount.toDouble());
              }).toList(),
              isCurved: true,
              color: colorScheme.primary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: colorScheme.primary.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateMaxY(List<ReadingActivityDataPoint> dataPoints) {
    if (dataPoints.isEmpty) return 10.0;
    final maxCount = dataPoints.map((p) => p.bookCount).reduce((a, b) => a > b ? a : b);
    return (maxCount * 1.2).ceil().toDouble();
  }

  double _calculateInterval(List<ReadingActivityDataPoint> dataPoints) {
    final maxY = _calculateMaxY(dataPoints);
    if (maxY <= 5) return 1;
    if (maxY <= 10) return 2;
    if (maxY <= 20) return 5;
    return 10;
  }

  double _calculateBottomInterval(List<ReadingActivityDataPoint> dataPoints) {
    if (dataPoints.length <= 6) return 1;
    if (dataPoints.length <= 12) return 2;
    return (dataPoints.length / 6).ceilToDouble();
  }
}

