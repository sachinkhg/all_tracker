/*
 * File: investment_component_repository_impl.dart
 *
 * Purpose:
 *  - Repository implementation that bridges the domain layer (InvestmentComponent entity)
 *    with the data layer (InvestmentComponentModel / Hive-backed datasource).
 */

import '../../domain/entities/investment_component.dart';
import '../../domain/repositories/investment_component_repository.dart';
import '../datasources/investment_component_local_data_source.dart';
import '../models/investment_component_model.dart';

/// Concrete implementation of InvestmentComponentRepository.
class InvestmentComponentRepositoryImpl
    implements InvestmentComponentRepository {
  final InvestmentComponentLocalDataSource local;

  InvestmentComponentRepositoryImpl(this.local);

  @override
  Future<InvestmentComponent> createComponent(
      InvestmentComponent component) async {
    final model = InvestmentComponentModel.fromEntity(component);
    await local.createComponent(model);
    return component;
  }

  @override
  Future<bool> deleteComponent(String id) async {
    await local.deleteComponent(id);
    return true;
  }

  @override
  Future<List<InvestmentComponent>> getAllComponents() async {
    final models = await local.getAllComponents();
    final components = models.map((m) => m.toEntity()).toList();
    // Sort by priority (ascending - lower number = higher priority)
    components.sort((a, b) => a.priority.compareTo(b.priority));
    return components;
  }

  @override
  Future<InvestmentComponent?> getComponentById(String id) async {
    final model = await local.getComponentById(id);
    return model?.toEntity();
  }

  @override
  Future<InvestmentComponent> updateComponent(
      InvestmentComponent component) async {
    final model = InvestmentComponentModel.fromEntity(component);
    await local.updateComponent(model);
    return component;
  }
}

