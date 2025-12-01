import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/design_tokens.dart';

class ExpenseInsightsCard extends StatelessWidget {
  final String title;
  final double value;
  final IconData icon;
  final Color? color;

  const ExpenseInsightsCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final amountFormat = NumberFormat('#,##0'); // No decimals
    final cardColor = color ?? cs.primaryContainer;
    final textColor = color != null 
        ? (color!.computeLuminance() > 0.5 ? Colors.black87 : Colors.white)
        : cs.onPrimaryContainer;

    return Card(
      elevation: AppElevations.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.m),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: textColor, size: 16),
                const SizedBox(width: AppSpacing.s),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: textColor,
                          fontSize: 11,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                amountFormat.format(value),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

