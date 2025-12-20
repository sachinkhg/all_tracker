import 'package:flutter/material.dart';
import '../../domain/usecases/book/get_book_stats.dart';

class BookStatsCard extends StatelessWidget {
  final BookStats stats;

  const BookStatsCard({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistics',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _StatRow(
              label: 'Completed Books',
              value: stats.completedBooks.toString(),
              icon: Icons.check_circle,
            ),
            const SizedBox(height: 8),
            _StatRow(
              label: 'Total Reads',
              value: stats.totalReads.toString(),
              icon: Icons.repeat,
            ),
            const SizedBox(height: 8),
            _StatRow(
              label: 'Total Pages Read',
              value: stats.totalPagesRead.toString(),
              icon: Icons.menu_book,
            ),
            const SizedBox(height: 8),
            _StatRow(
              label: 'Average Rating',
              value: stats.averageRating != null
                  ? stats.averageRating!.toStringAsFixed(1)
                  : 'N/A',
              icon: Icons.star,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}

