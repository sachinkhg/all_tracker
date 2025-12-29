import 'package:hive/hive.dart';
import '../../domain/entities/redemption_log.dart';

part 'redemption_log_model.g.dart'; // Generated via build_runner

/// ---------------------------------------------------------------------------
/// RedemptionLogModel – Data Transfer Object (DTO) / Hive Persistence Model
/// ---------------------------------------------------------------------------
///
/// Purpose:
/// - Represents a persisted `RedemptionLog` entity within Hive.
/// - Acts as a bridge between domain-layer entities and Hive storage.
///
/// Schema & Migration Guidelines:
/// - Each `@HiveField` index is permanent once written to storage.
/// - Never reuse or reorder field numbers — doing so will corrupt persisted data.
/// - Add new fields only at the end with new, unique field numbers.
/// - Document any changes in `migration_notes.md`.
///
/// TypeId: 36 (as documented in migration_notes.md)
/// ---------------------------------------------------------------------------

@HiveType(typeId: 36)
class RedemptionLogModel extends HiveObject {
  /// Unique identifier for the redemption log.
  ///
  /// Hive field number **0** — stable ID, never change or reuse.
  @HiveField(0)
  String id;

  /// Reference to the investment master this log belongs to.
  ///
  /// Hive field number **1** — required.
  @HiveField(1)
  String investmentId;

  /// Date when the redemption was made.
  ///
  /// Hive field number **2** — required.
  @HiveField(2)
  DateTime redemptionDate;

  /// Quantity of units redeemed (nullable).
  ///
  /// Hive field number **3** — nullable.
  @HiveField(3)
  double? quantity;

  /// Average sell price per unit (nullable).
  ///
  /// Hive field number **4** — nullable.
  @HiveField(4)
  double? averageSellPrice;

  /// Cost to sell or withdraw (fees, charges, etc.) (nullable).
  ///
  /// Hive field number **5** — nullable.
  @HiveField(5)
  double? costToSellOrWithdraw;

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

  RedemptionLogModel({
    required this.id,
    required this.investmentId,
    required this.redemptionDate,
    this.quantity,
    this.averageSellPrice,
    this.costToSellOrWithdraw,
    this.currencyConversionAmount,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a RedemptionLogModel from a domain entity.
  factory RedemptionLogModel.fromEntity(RedemptionLog entity) {
    return RedemptionLogModel(
      id: entity.id,
      investmentId: entity.investmentId,
      redemptionDate: entity.redemptionDate,
      quantity: entity.quantity,
      averageSellPrice: entity.averageSellPrice,
      costToSellOrWithdraw: entity.costToSellOrWithdraw,
      currencyConversionAmount: entity.currencyConversionAmount,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// Converts this model to a domain entity.
  RedemptionLog toEntity() {
    return RedemptionLog(
      id: id,
      investmentId: investmentId,
      redemptionDate: redemptionDate,
      quantity: quantity,
      averageSellPrice: averageSellPrice,
      costToSellOrWithdraw: costToSellOrWithdraw,
      currencyConversionAmount: currencyConversionAmount,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

