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
    final amountFormat = NumberFormat('#,##0.00');
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
              children: [
                Icon(icon, color: textColor, size: 20),
                const SizedBox(width: AppSpacing.s),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: textColor,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s),
            Text(
              amountFormat.format(value),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

