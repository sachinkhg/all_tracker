import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/design_tokens.dart';
import '../../core/injection.dart';
import '../bloc/investment_component_cubit.dart';
import '../bloc/investment_component_state.dart';
import '../widgets/component_form_bottom_sheet.dart';
import '../../domain/entities/investment_component.dart';

/// Page for managing investment component configurations
class ComponentConfigPage extends StatelessWidget {
  const ComponentConfigPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => createInvestmentComponentCubit(),
      child: const ComponentConfigPageView(),
    );
  }
}

class ComponentConfigPageView extends StatelessWidget {
  const ComponentConfigPageView({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Investment Components'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: AppGradients.appBar(cs),
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: cs.onPrimary,
        elevation: 0,
      ),
      body: BlocBuilder<InvestmentComponentCubit, InvestmentComponentState>(
        builder: (context, state) {
          if (state is ComponentsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ComponentsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${state.message}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<InvestmentComponentCubit>().loadComponents();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is ComponentsLoaded) {
            final components = state.components;
            if (components.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('No components configured'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _showAddComponentForm(context),
                      child: const Text('Add Component'),
                    ),
                  ],
                ),
              );
            }

            return ReorderableListView(
              padding: const EdgeInsets.all(16),
              onReorder: (oldIndex, newIndex) {
                if (oldIndex < newIndex) {
                  newIndex -= 1;
                }
                final cubit = context.read<InvestmentComponentCubit>();
                cubit.reorderComponents(oldIndex, newIndex);
              },
              children: components.map((component) {
                return Card(
                  key: ValueKey(component.id),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(component.name),
                    subtitle: Text(
                      'Priority: ${component.priority} | ${component.percentage}%',
                    ),
                    leading: Icon(
                      Icons.drag_handle,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    onTap: () => _showEditComponentForm(context, component),
                  ),
                );
              }).toList(),
            );
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: Builder(
        builder: (context) {
          final cs = Theme.of(context).colorScheme;
          return FloatingActionButton.small(
            heroTag: 'addComponentFab',
            tooltip: 'Add Component',
            backgroundColor: cs.surface.withOpacity(0.85),
            onPressed: () => _showAddComponentForm(context),
            child: const Icon(Icons.add),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  void _showAddComponentForm(BuildContext context) {
    ComponentFormBottomSheet.show(
      context,
      onSubmit: (name, percentage, priority, minLimit, maxLimit) async {
        await context.read<InvestmentComponentCubit>().addComponent(
              name,
              percentage,
              priority,
              minLimit: minLimit,
              maxLimit: maxLimit,
            );
      },
    );
  }

  void _showEditComponentForm(BuildContext context, InvestmentComponent component) {
    final cubit = context.read<InvestmentComponentCubit>();
    ComponentFormBottomSheet.show(
      context,
      component: component,
      onSubmit: (name, percentage, priority, minLimit, maxLimit) async {
        final updated = component.copyWith(
          name: name,
          percentage: percentage,
          priority: priority,
          minLimit: minLimit,
          maxLimit: maxLimit,
        );
        await cubit.updateComponent(updated);
      },
      onDelete: () async {
        await cubit.deleteComponent(component.id);
      },
    );
  }
}

