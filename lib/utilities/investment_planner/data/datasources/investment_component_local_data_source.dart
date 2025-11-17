/*
 * File: investment_component_local_data_source.dart
 *
 * Purpose:
 *   Hive-backed local data source for Investment Component objects.
 */

import 'package:hive/hive.dart';
import '../models/investment_component_model.dart';

/// Abstract data source for local (Hive) investment component storage.
abstract class InvestmentComponentLocalDataSource {
  Future<List<InvestmentComponentModel>> getAllComponents();
  Future<InvestmentComponentModel?> getComponentById(String id);
  Future<void> createComponent(InvestmentComponentModel component);
  Future<void> updateComponent(InvestmentComponentModel component);
  Future<void> deleteComponent(String id);
}

/// Hive implementation of InvestmentComponentLocalDataSource.
class InvestmentComponentLocalDataSourceImpl
    implements InvestmentComponentLocalDataSource {
  final Box<InvestmentComponentModel> box;

  InvestmentComponentLocalDataSourceImpl(this.box);

  @override
  Future<void> createComponent(InvestmentComponentModel component) async {
    await box.put(component.id, component);
  }

  @override
  Future<void> deleteComponent(String id) async {
    await box.delete(id);
  }

  @override
  Future<InvestmentComponentModel?> getComponentById(String id) async {
    return box.get(id);
  }

  @override
  Future<List<InvestmentComponentModel>> getAllComponents() async {
    return box.values.toList();
  }

  @override
  Future<void> updateComponent(InvestmentComponentModel component) async {
    await box.put(component.id, component);
  }
}

