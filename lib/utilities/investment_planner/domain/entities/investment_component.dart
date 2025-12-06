/*
 * File: ./lib/utilities/investment_planner/domain/entities/investment_component.dart
 *
 * Purpose:
 *   Domain representation of an Investment Component used throughout the application's
 *   business logic. Each Investment Component represents a type of investment
 *   (e.g., NPS, PPF, Mutual Funds) with configuration for allocation.
 *
 *   This file defines the plain, immutable domain entity and documents how
 *   it maps to persistence DTOs / Hive models.
 *
 * Serialization rules (for implementers of DTO / Hive adapters):
 *   - `id` (String)           : non-nullable, globally unique identifier.
 *   - `name` (String)         : non-nullable, human-readable title.
 *   - `percentage` (double)   : non-nullable, percentage allocation (0-100).
 *   - `minLimit` (double?)    : nullable, minimum allocation amount.
 *   - `maxLimit` (double?)    : nullable, maximum allocation amount.
 *   - `priority` (int)        : non-nullable, priority order (lower = higher priority).
 *
 * Notes for implementers:
 *   - This file should remain persistence-agnostic. Keep storage annotations
 *     and logic in the data layer only.
 *   - The domain layer operates with immutable, type-safe entities.
 */

import 'package:equatable/equatable.dart';

/// Domain model for an Investment Component.
///
/// Represents a type of investment (e.g., NPS, PPF, Mutual Funds) with
/// configuration for how funds should be allocated to it.
class InvestmentComponent extends Equatable {
  /// Unique identifier for the component (GUID or UUID recommended).
  final String id;

  /// Human-readable component name (e.g., "NPS", "PPF", "Mutual Funds").
  final String name;

  /// Percentage allocation (0-100).
  ///
  /// Represents the target percentage of available funds to allocate to this component.
  final double percentage;

  /// Optional minimum allocation amount.
  ///
  /// If specified, ensures at least this amount is allocated to this component.
  final double? minLimit;

  /// Optional maximum allocation amount.
  ///
  /// If specified, caps the allocation at this amount.
  final double? maxLimit;

  /// Optional multiple of value for rounding.
  ///
  /// If specified, the allocated amount will be rounded to the nearest multiple of this value.
  final double? multipleOf;

  /// Priority order (lower number = higher priority).
  ///
  /// Components with lower priority numbers are allocated first.
  final int priority;

  /// Domain constructor.
  const InvestmentComponent({
    required this.id,
    required this.name,
    required this.percentage,
    this.minLimit,
    this.maxLimit,
    this.multipleOf,
    required this.priority,
  });

  /// Creates a copy of this InvestmentComponent with the given fields replaced.
  InvestmentComponent copyWith({
    String? id,
    String? name,
    double? percentage,
    double? minLimit,
    double? maxLimit,
    double? multipleOf,
    int? priority,
  }) {
    return InvestmentComponent(
      id: id ?? this.id,
      name: name ?? this.name,
      percentage: percentage ?? this.percentage,
      minLimit: minLimit ?? this.minLimit,
      maxLimit: maxLimit ?? this.maxLimit,
      multipleOf: multipleOf ?? this.multipleOf,
      priority: priority ?? this.priority,
    );
  }

  @override
  List<Object?> get props => [id, name, percentage, minLimit, maxLimit, multipleOf, priority];
}

