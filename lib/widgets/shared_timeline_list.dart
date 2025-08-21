import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

typedef ItemWidgetBuilder<T> = Widget Function(BuildContext context, T item);

class TimelineEntryList<T> extends StatelessWidget {
  final List<T> items;
  final ItemWidgetBuilder<T> itemBuilder;
  final double cardHeight;

  const TimelineEntryList({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.cardHeight = 96, // Default height per card
  });

  @override
  Widget build(BuildContext context) {
    const cardBottomPadding = 12.0;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: cardBottomPadding),
          child: itemBuilder(context, item),
        );
      },
    );
  }
}

class YearTimelineList<T> extends StatelessWidget {
  final List<int> yearKeys;
  final Map<int, List<T>> itemsByYear;
  final Widget Function(BuildContext, T) itemBuilder;
  final double cardHeight;

  const YearTimelineList({
    super.key,
    required this.yearKeys,
    required this.itemsByYear,
    required this.itemBuilder,
    this.cardHeight = 96,
  });

  @override
  Widget build(BuildContext context) {
    //const cardBottomPadding = 12.0;

    return Column(
      children: [
        for (final year in yearKeys)
          Builder(builder: (context) {
            final items = itemsByYear[year]!;
            //final lineHeight = (cardHeight * items.length) + (cardBottomPadding * items.length);

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Year and vertical line column
                Column(
                  children: [
                    Text(
                      year.toString(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      width: 2,
                      height: cardHeight - 10,
                      color: Colors.grey[300],
                      margin: const EdgeInsets.symmetric(vertical: 6),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                // The timeline list for this year
                Expanded(
                  child: TimelineEntryList<T>(
                    items: items,
                    itemBuilder: itemBuilder,
                    cardHeight: cardHeight,
                  ),
                ),
              ],
            );
          }),
      ],
    );
  }
}

class MonthTimelineList<T> extends StatelessWidget {
  final List<String> monthKeys; // Now using yyyy-MM strings
  final Map<String, List<T>> itemsByMonth;
  final Widget Function(BuildContext, T) itemBuilder;
  final double cardHeight;

  const MonthTimelineList({
    super.key,
    required this.monthKeys,
    required this.itemsByMonth,
    required this.itemBuilder,
    this.cardHeight = 96,
  });

  /// Convert "yyyy-MM" into "MonthName YYYY"
  String _formatMonthYear(String key) {
    final parts = key.split('-'); // ["2025", "08"]
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    return DateFormat.yMMM().format(DateTime(year, month));
    // Example → "August 2025"
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final monthKey in monthKeys)
          Builder(builder: (context) {
            final items = itemsByMonth[monthKey]!;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Month-Year name and vertical line column
                Column(
                  children: [
                    Text(
                      _formatMonthYear(monthKey),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      width: 2,
                      height: cardHeight - 10,
                      color: Colors.grey[300],
                      margin: const EdgeInsets.symmetric(vertical: 6),
                    ),
                  ],
                ),
                const SizedBox(width: 16),

                // The timeline list for this month
                Expanded(
                  child: TimelineEntryList<T>(
                    items: items,
                    itemBuilder: itemBuilder,
                    cardHeight: cardHeight,
                  ),
                ),
              ],
            );
          }),
      ],
    );
  }
}

