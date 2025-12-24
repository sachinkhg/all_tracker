// lib/trackers/portfolio_tracker/presentation/widgets/investment_totals_card.dart
// Card widget for displaying investment totals

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Helper class to hold calculated totals for display
class InvestmentTotals {
  final double totalInvested;
  final double totalRedeemed;
  final double activeAmount;
  final bool isActive;

  InvestmentTotals({
    required this.totalInvested,
    required this.totalRedeemed,
    required this.activeAmount,
    required this.isActive,
  });

  factory InvestmentTotals.empty() {
    return InvestmentTotals(
      totalInvested: 0.0,
      totalRedeemed: 0.0,
      activeAmount: 0.0,
      isActive: false,
    );
  }
}

/// Card widget for displaying investment totals
class InvestmentTotalsCard extends StatelessWidget {
  final InvestmentTotals totals;
  final String currencySymbol;

  const InvestmentTotalsCard({
    super.key,
    required this.totals,
    this.currencySymbol = '₹',
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final numberFormat = NumberFormat.currency(symbol: currencySymbol, decimalDigits: 2);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Investment Summary',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _TotalItem(
                  label: 'Total Invested',
                  value: numberFormat.format(totals.totalInvested),
                  color: cs.primary,
                ),
                _TotalItem(
                  label: 'Total Redeemed',
                  value: numberFormat.format(totals.totalRedeemed),
                  color: cs.error,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: cs.outline),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Active Amount',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  numberFormat.format(totals.activeAmount),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: totals.isActive ? cs.primary : cs.onSurfaceVariant,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  totals.isActive ? Icons.check_circle : Icons.cancel,
                  size: 16,
                  color: totals.isActive ? Colors.green : cs.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  totals.isActive ? 'Active' : 'Inactive',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: totals.isActive ? Colors.green : cs.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _TotalItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
      ],
    );
  }
}

