import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/design_tokens.dart';
import '../../core/injection.dart';
import '../bloc/retirement_plan_cubit.dart';
import '../bloc/retirement_plan_state.dart';
import 'retirement_plan_create_edit_page.dart';
import 'retirement_plan_detail_page.dart';

/// Page for listing all saved retirement plans
class RetirementPlanListPage extends StatelessWidget {
  const RetirementPlanListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => createRetirementPlanCubit(),
      child: const RetirementPlanListPageView(),
    );
  }
}

class RetirementPlanListPageView extends StatelessWidget {
  const RetirementPlanListPageView({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Retirement Plans'),
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
      body: BlocBuilder<RetirementPlanCubit, RetirementPlanState>(
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
                      context.read<RetirementPlanCubit>().loadPlans();
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
                            builder: (_) => const RetirementPlanCreateEditPage(),
                          ),
                        );
                        // Reload plans when returning from create/edit page
                        if (context.mounted) {
                          context.read<RetirementPlanCubit>().loadPlans();
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
                    subtitle: Text('Retirement Age: ${plan.retirementAge}'),
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RetirementPlanDetailPage(plan: plan),
                        ),
                      );
                      // Reload plans when returning from detail page if plan was updated/deleted
                      if (result == true && context.mounted) {
                        context.read<RetirementPlanCubit>().loadPlans();
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
      floatingActionButton: FloatingActionButton.small(
        heroTag: 'addRetirementPlanFab',
        tooltip: 'Add Plan',
        backgroundColor: cs.surface.withValues(alpha: 0.85),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const RetirementPlanCreateEditPage(),
            ),
          );
          // Reload plans when returning from create page
          if (context.mounted) {
            context.read<RetirementPlanCubit>().loadPlans();
          }
        },
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

