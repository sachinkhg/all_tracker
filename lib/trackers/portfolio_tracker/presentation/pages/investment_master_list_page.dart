// lib/trackers/portfolio_tracker/presentation/pages/investment_master_list_page.dart
// Main page for investment master list

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/investment_master.dart';
import '../../domain/entities/investment_log.dart';
import '../../domain/entities/redemption_log.dart';
import '../../features/calculations/investment_calculations.dart';
import '../bloc/investment_master_cubit.dart';
import '../bloc/investment_master_state.dart';
import '../bloc/investment_log_cubit.dart';
import '../bloc/investment_log_state.dart';
import '../bloc/redemption_log_cubit.dart';
import '../bloc/redemption_log_state.dart';
import '../../core/injection.dart';
import '../../../../widgets/primary_app_bar.dart';
import '../../../../widgets/loading_view.dart';
import '../../../../widgets/error_view.dart';
import '../../../../widgets/app_drawer.dart';
import '../../../../pages/app_home_page.dart';
import '../../../../core/organization_notifier.dart';
import '../widgets/investment_master_list_item.dart';
import '../widgets/investment_master_form_bottom_sheet.dart';
import '../widgets/investment_totals_card.dart';
import '../../domain/entities/investment_category.dart';
import '../../domain/entities/investment_tracking_type.dart';
import '../../domain/entities/investment_currency.dart';
import '../../domain/entities/risk_factor.dart';
import '../../features/investment_import_export.dart';

class InvestmentMasterListPage extends StatelessWidget {
  const InvestmentMasterListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) {
            final cubit = createInvestmentMasterCubit();
            cubit.loadInvestmentMasters();
            return cubit;
          },
        ),
        BlocProvider(create: (_) => createInvestmentLogCubit()),
        BlocProvider(create: (_) => createRedemptionLogCubit()),
      ],
      child: const InvestmentMasterListPageView(),
    );
  }
}

class InvestmentMasterListPageView extends StatefulWidget {
  const InvestmentMasterListPageView({super.key});

  @override
  State<InvestmentMasterListPageView> createState() => _InvestmentMasterListPageViewState();
}

class _InvestmentMasterListPageViewState extends State<InvestmentMasterListPageView> {
  @override
  Widget build(BuildContext context) {
    final masterCubit = context.read<InvestmentMasterCubit>();
    final logCubit = context.read<InvestmentLogCubit>();
    final redemptionCubit = context.read<RedemptionLogCubit>();

    return Scaffold(
      drawer: const AppDrawer(currentPage: AppPage.portfolioTracker),
      appBar: PrimaryAppBar(
        title: 'Investment Tracker',
        actions: [
          Consumer<OrganizationNotifier>(
            builder: (context, orgNotifier, _) {
              if (orgNotifier.defaultHomePage == 'app_home') {
                return IconButton(
                  tooltip: 'Home Page',
                  icon: const Icon(Icons.home),
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const AppHomePage()),
                      (route) => false,
                    );
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: BlocBuilder<InvestmentMasterCubit, InvestmentMasterState>(
          builder: (context, state) {
            if (state is InvestmentMastersLoading) {
              return const LoadingView();
            }

            if (state is InvestmentMastersLoaded) {
              final masters = state.investmentMasters;

              return masters.isEmpty
                  ? const Center(
                      child: Text('No investments found. Tap + to add one.'),
                    )
                  : FutureBuilder<Map<String, InvestmentTotals>>(
                      future: _calculateTotalsForAllMasters(masters, logCubit, redemptionCubit),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const LoadingView();
                        }

                        final totalsMap = snapshot.data ?? {};

                        return ListView.builder(
                          itemCount: masters.length,
                          itemBuilder: (context, index) {
                            final master = masters[index];
                            final totals = totalsMap[master.id] ?? InvestmentTotals.empty();
                            return InvestmentMasterListItem(
                              investmentMaster: master,
                              totals: totals,
                              onTap: () {
                                _showInvestmentMasterForm(context, masterCubit, master: master);
                              },
                            );
                          },
                        );
                      },
                    );
            }

            if (state is InvestmentMastersError) {
              return ErrorView(
                message: state.message,
                onRetry: () => masterCubit.loadInvestmentMasters(),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
      floatingActionButton: _ActionsFab(
        onAdd: () => _showInvestmentMasterForm(context, masterCubit),
        onMore: () => _showActionsSheet(context, masterCubit),
      ),
    );
  }

  Future<Map<String, InvestmentTotals>> _calculateTotalsForAllMasters(
    List<InvestmentMaster> masters,
    InvestmentLogCubit logCubit,
    RedemptionLogCubit redemptionCubit,
  ) async {
    final Map<String, InvestmentTotals> totalsMap = {};

    for (final master in masters) {
      try {
        // Load logs for this master
        await logCubit.loadInvestmentLogs(master.id);
        await redemptionCubit.loadRedemptionLogs(master.id);

        // Get the logs from state
        final logState = logCubit.state;
        final redemptionState = redemptionCubit.state;

        List<InvestmentLog> investmentLogs = [];
        List<RedemptionLog> redemptionLogs = [];

        if (logState is InvestmentLogsLoaded) {
          investmentLogs = logState.investmentLogs;
        }
        if (redemptionState is RedemptionLogsLoaded) {
          redemptionLogs = redemptionState.redemptionLogs;
        }

        // Calculate totals
        final totals = InvestmentCalculations.calculateInvestmentTotals(
          investmentMaster: master,
          investmentLogs: investmentLogs,
          redemptionLogs: redemptionLogs,
        );

        totalsMap[master.id] = InvestmentTotals(
          totalInvested: totals['totalInvested']!,
          totalRedeemed: totals['totalRedeemed']!,
          activeAmount: totals['activeAmount']!,
          isActive: InvestmentCalculations.calculateIsActive(totals['activeAmount']!),
        );
      } catch (e) {
        totalsMap[master.id] = InvestmentTotals.empty();
      }
    }

    return totalsMap;
  }

  void _showInvestmentMasterForm(
    BuildContext context,
    InvestmentMasterCubit cubit, {
    InvestmentMaster? master,
  }) {
    InvestmentMasterFormBottomSheet.show(
      context,
      investmentMaster: master,
      onSubmit: ({
        required String shortName,
        required String name,
        required InvestmentCategory investmentCategory,
        required InvestmentTrackingType investmentTrackingType,
        required InvestmentCurrency investmentCurrency,
        required RiskFactor riskFactor,
      }) async {
        if (master != null) {
          // Update existing
          final updated = master.copyWith(
            shortName: shortName,
            name: name,
            investmentCategory: investmentCategory,
            investmentTrackingType: investmentTrackingType,
            investmentCurrency: investmentCurrency,
            riskFactor: riskFactor,
            updatedAt: DateTime.now(),
          );
          await cubit.updateInvestmentMaster(updated);
        } else {
          // Create new
          await cubit.createInvestmentMaster(
            shortName: shortName,
            name: name,
            investmentCategory: investmentCategory,
            investmentTrackingType: investmentTrackingType,
            investmentCurrency: investmentCurrency,
            riskFactor: riskFactor,
          );
        }
      },
      onDelete: master != null
          ? () async {
              await cubit.deleteInvestmentMaster(master.id);
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            }
          : null,
      title: master != null ? 'Edit Investment' : 'Create Investment',
    );
  }

  void _showValidValuesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Valid Values Reference'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSection(
                context,
                'Investment Category',
                InvestmentCategory.values.map((e) => e.displayName).toList(),
              ),
              const SizedBox(height: 16),
              _buildSection(
                context,
                'Tracking Type',
                InvestmentTrackingType.values.map((e) => e.displayName).toList(),
              ),
              const SizedBox(height: 16),
              _buildSection(
                context,
                'Currency',
                InvestmentCurrency.values.map((e) => e.displayName).toList(),
              ),
              const SizedBox(height: 16),
              _buildSection(
                context,
                'Risk Factor',
                RiskFactor.values.map((e) => e.displayName).toList(),
              ),
              const SizedBox(height: 16),
              Text(
                'Note: These are the values used in exports. When importing, you can use either the display name or enum name (case-insensitive).',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<String> values) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        ...values.map((value) => Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 4),
              child: Text('• $value', style: Theme.of(context).textTheme.bodyMedium),
            )),
      ],
    );
  }

  void _showActionsSheet(BuildContext context, InvestmentMasterCubit cubit) {
    final sheet = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.4),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 12),
        ListTile(
          leading: const Icon(Icons.add),
          title: const Text('Add Investment'),
          onTap: () {
            Navigator.of(context).pop();
            _showInvestmentMasterForm(context, cubit);
          },
        ),
        ListTile(
          leading: const Icon(Icons.file_download),
          title: const Text('Export'),
          onTap: () async {
            Navigator.of(context).pop();
            final state = cubit.state;
            final investments = state is InvestmentMastersLoaded ? state.investmentMasters : <InvestmentMaster>[];
            final path = await exportInvestmentMastersToXlsx(context, investments);
            if (path != null && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('File exported')),
              );
            }
          },
        ),
        ListTile(
          leading: const Icon(Icons.file_upload),
          title: const Text('Import'),
          onTap: () {
            Navigator.of(context).pop();
            importInvestmentMastersFromXlsx(context);
          },
        ),
        ListTile(
          leading: const Icon(Icons.download),
          title: const Text('Download Template'),
          onTap: () async {
            Navigator.of(context).pop();
            final path = await downloadInvestmentTemplate(context);
            if (path != null && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Template downloaded')),
              );
            }
          },
        ),
        ListTile(
          leading: const Icon(Icons.help_outline),
          title: const Text('Valid Values'),
          onTap: () {
            Navigator.of(context).pop();
            _showValidValuesDialog(context);
          },
        ),
      ],
    );

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12.0)),
      ),
      builder: (context) => SafeArea(child: sheet),
    );
  }
}

class _ActionsFab extends StatelessWidget {
  const _ActionsFab({
    required this.onAdd,
    required this.onMore,
  });

  final VoidCallback onAdd;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton.small(
          heroTag: 'addInvestmentFab',
          tooltip: 'Add Investment',
          backgroundColor: cs.surface.withValues(alpha: 0.85),
          onPressed: onAdd,
          child: const Icon(Icons.add),
        ),
        const SizedBox(width: 12),
        FloatingActionButton.small(
          heroTag: 'moreFab',
          tooltip: 'More actions',
          backgroundColor: cs.surface.withValues(alpha: 0.85),
          onPressed: onMore,
          child: const Icon(Icons.more_vert),
        ),
      ],
    );
  }
}

