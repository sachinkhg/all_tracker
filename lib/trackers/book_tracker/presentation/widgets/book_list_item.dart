import 'package:flutter/material.dart';
import '../../domain/entities/book.dart';

class BookListItem extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;

  const BookListItem({
    super.key,
    required this.book,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: cs.primary.withOpacity(0.1),
          child: Icon(
            Icons.book,
            color: cs.primary,
            size: 20,
          ),
        ),
        title: Text(
          book.title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: cs.onSurface,
              ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              book.primaryAuthor,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                if (book.pageCount > 0)
                  Chip(
                    label: Text(
                      '${book.pageCount} pages',
                      style: const TextStyle(fontSize: 11),
                    ),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                const SizedBox(width: 4),
                Chip(
                  label: Text(
                    book.status.displayName,
                    style: const TextStyle(fontSize: 11),
                  ),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

