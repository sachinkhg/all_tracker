import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/design_tokens.dart';
import '../../core/injection.dart';
import '../../domain/entities/plan_status.dart';
import '../bloc/investment_plan_cubit.dart';
import '../bloc/investment_plan_state.dart';
import 'plan_create_edit_page.dart';
import 'plan_detail_page.dart';
import 'component_config_page.dart';
import 'category_config_page.dart';

/// Page for listing all saved investment plans
class PlanListPage extends StatelessWidget {
  const PlanListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => createInvestmentPlanCubit(),
      child: const PlanListPageView(),
    );
  }
}

class PlanListPageView extends StatelessWidget {
  const PlanListPageView({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Investment Plans'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: AppGradients.appBar(cs),
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: cs.onPrimary,
        iconTheme: IconThemeData(
          color: cs.brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.95)
              : Colors.black87,
          opacity: 1.0,
        ),
        actionsIconTheme: IconThemeData(
          color: cs.brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.95)
              : Colors.black87,
          opacity: 1.0,
        ),
        elevation: 0,
      ),
      body: BlocBuilder<InvestmentPlanCubit, InvestmentPlanState>(
        builder: (context, state) {
          if (state is PlansLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is PlansError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${state.message}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<InvestmentPlanCubit>().loadPlans();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is PlansLoaded) {
            final plans = state.plans;
            if (plans.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('No plans saved yet'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PlanCreateEditPage(),
                          ),
                        );
                        // Reload plans when returning from create/edit page
                        if (context.mounted) {
                          context.read<InvestmentPlanCubit>().loadPlans();
                        }
                      },
                      child: const Text('Create Plan'),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: plans.length,
              itemBuilder: (context, index) {
                final plan = plans[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(plan.name),
                    trailing: _buildStatusChip(plan.status),
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PlanDetailPage(plan: plan),
                        ),
                      );
                      // Reload plans when returning from detail page if plan was updated/deleted
                      if (result == true && context.mounted) {
                        context.read<InvestmentPlanCubit>().loadPlans();
                      }
                    },
                  ),
                );
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'configFab',
            tooltip: 'Configuration',
            backgroundColor: cs.surface.withValues(alpha: 0.85),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.account_balance),
                        title: const Text('Configure Components'),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ComponentConfigPage(),
                            ),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.category),
                        title: const Text('Manage Categories'),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CategoryConfigPage(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.tune), // Configuration icon
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: cs.onSurface, width: 1),
                    ),
                    child: Icon(
                      Icons.settings,
                      size: 10,
                      color: cs.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'addPlanFab',
            tooltip: 'Add Plan',
            backgroundColor: cs.surface.withValues(alpha: 0.85),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PlanCreateEditPage(),
                ),
              );
              // Reload plans when returning from create page
              if (context.mounted) {
                context.read<InvestmentPlanCubit>().loadPlans();
              }
            },
            child: const Icon(Icons.add),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildStatusChip(PlanStatus status) {
    Color backgroundColor;
    Color textColor;
    
    switch (status) {
      case PlanStatus.draft:
        backgroundColor = Colors.grey.shade300;
        textColor = Colors.grey.shade800;
        break;
      case PlanStatus.approved:
        backgroundColor = Colors.orange.shade200;
        textColor = Colors.orange.shade900;
        break;
      case PlanStatus.executed:
        backgroundColor = Colors.green.shade200;
        textColor = Colors.green.shade900;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }
}

