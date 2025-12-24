import 'package:hive/hive.dart';
import '../../domain/entities/investment_log.dart';

part 'investment_log_model.g.dart'; // Generated via build_runner

/// ---------------------------------------------------------------------------
/// InvestmentLogModel – Data Transfer Object (DTO) / Hive Persistence Model
/// ---------------------------------------------------------------------------
///
/// Purpose:
/// - Represents a persisted `InvestmentLog` entity within Hive.
/// - Acts as a bridge between domain-layer entities and Hive storage.
///
/// Schema & Migration Guidelines:
/// - Each `@HiveField` index is permanent once written to storage.
/// - Never reuse or reorder field numbers — doing so will corrupt persisted data.
/// - Add new fields only at the end with new, unique field numbers.
/// - Document any changes in `migration_notes.md`.
///
/// TypeId: 35 (as documented in migration_notes.md)
/// ---------------------------------------------------------------------------

@HiveType(typeId: 35)
class InvestmentLogModel extends HiveObject {
  /// Unique identifier for the investment log.
  ///
  /// Hive field number **0** — stable ID, never change or reuse.
  @HiveField(0)
  String id;

  /// Reference to the investment master this log belongs to.
  ///
  /// Hive field number **1** — required.
  @HiveField(1)
  String investmentId;

  /// Date when the investment was made.
  ///
  /// Hive field number **2** — required.
  @HiveField(2)
  DateTime purchaseDate;

  /// Quantity of units purchased (nullable, required if tracking type is Unit).
  ///
  /// Hive field number **3** — nullable.
  @HiveField(3)
  double? quantity;

  /// Average cost price per unit (nullable).
  ///
  /// Hive field number **4** — nullable.
  @HiveField(4)
  double? averageCostPrice;

  /// Additional cost to acquire (fees, charges, etc.) (nullable).
  ///
  /// Hive field number **5** — nullable.
  @HiveField(5)
  double? costToAcquire;

  /// Currency conversion amount (nullable, required if currency is not INR).
  ///
  /// Hive field number **6** — nullable.
  @HiveField(6)
  double? currencyConversionAmount;

  /// Timestamp of creation.
  ///
  /// Hive field number **7** — required.
  @HiveField(7)
  DateTime createdAt;

  /// Timestamp of last update.
  ///
  /// Hive field number **8** — required.
  @HiveField(8)
  DateTime updatedAt;

  InvestmentLogModel({
    required this.id,
    required this.investmentId,
    required this.purchaseDate,
    this.quantity,
    this.averageCostPrice,
    this.costToAcquire,
    this.currencyConversionAmount,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates an InvestmentLogModel from a domain entity.
  factory InvestmentLogModel.fromEntity(InvestmentLog entity) {
    return InvestmentLogModel(
      id: entity.id,
      investmentId: entity.investmentId,
      purchaseDate: entity.purchaseDate,
      quantity: entity.quantity,
      averageCostPrice: entity.averageCostPrice,
      costToAcquire: entity.costToAcquire,
      currencyConversionAmount: entity.currencyConversionAmount,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// Converts this model to a domain entity.
  InvestmentLog toEntity() {
    return InvestmentLog(
      id: id,
      investmentId: investmentId,
      purchaseDate: purchaseDate,
      quantity: quantity,
      averageCostPrice: averageCostPrice,
      costToAcquire: costToAcquire,
      currencyConversionAmount: currencyConversionAmount,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

