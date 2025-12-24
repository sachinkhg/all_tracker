// lib/trackers/portfolio_tracker/presentation/widgets/investment_master_list_item.dart
// List item widget for investment master

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/investment_master.dart';
import '../../core/app_icons.dart';
import 'investment_totals_card.dart';

class InvestmentMasterListItem extends StatelessWidget {
  final InvestmentMaster investmentMaster;
  final InvestmentTotals totals;
  final VoidCallback onTap;

  const InvestmentMasterListItem({
    super.key,
    required this.investmentMaster,
    required this.totals,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final currencySymbol = investmentMaster.investmentCurrency.symbol;
    final numberFormat = NumberFormat.currency(symbol: currencySymbol, decimalDigits: 2);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: cs.primary.withOpacity(0.1),
          child: Icon(
            PortfolioTrackerIcons.portfolio,
            color: cs.primary,
            size: 20,
          ),
        ),
        title: Text(
          investmentMaster.shortName,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              investmentMaster.name,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                Chip(
                  label: Text(
                    investmentMaster.investmentCategory.displayName,
                    style: const TextStyle(fontSize: 11),
                  ),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                Chip(
                  label: Text(
                    investmentMaster.investmentTrackingType.displayName,
                    style: const TextStyle(fontSize: 11),
                  ),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                Chip(
                  label: Text(
                    investmentMaster.riskFactor.displayName,
                    style: const TextStyle(fontSize: 11),
                  ),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                if (totals.isActive)
                  Chip(
                    label: const Text(
                      'Active',
                      style: TextStyle(fontSize: 11),
                    ),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    backgroundColor: Colors.green.withOpacity(0.2),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Active: ${numberFormat.format(totals.activeAmount)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              numberFormat.format(totals.totalInvested),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
            if (totals.totalRedeemed > 0)
              Text(
                '-${numberFormat.format(totals.totalRedeemed)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.error,
                    ),
              ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

