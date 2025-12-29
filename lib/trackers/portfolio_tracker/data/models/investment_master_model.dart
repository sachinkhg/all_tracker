import 'package:hive/hive.dart';
import '../../domain/entities/investment_master.dart';
import '../../domain/entities/investment_category.dart';
import '../../domain/entities/investment_tracking_type.dart';
import '../../domain/entities/investment_currency.dart';
import '../../domain/entities/risk_factor.dart';

part 'investment_master_model.g.dart'; // Generated via build_runner

/// ---------------------------------------------------------------------------
/// InvestmentMasterModel – Data Transfer Object (DTO) / Hive Persistence Model
/// ---------------------------------------------------------------------------
///
/// Purpose:
/// - Represents a persisted `InvestmentMaster` entity within Hive.
/// - Acts as a bridge between domain-layer entities and Hive storage.
///
/// Schema & Migration Guidelines:
/// - Each `@HiveField` index is permanent once written to storage.
/// - Never reuse or reorder field numbers — doing so will corrupt persisted data.
/// - Add new fields only at the end with new, unique field numbers.
/// - Document any changes in `migration_notes.md`.
///
/// TypeId: 34 (as documented in migration_notes.md)
/// ---------------------------------------------------------------------------

@HiveType(typeId: 34)
class InvestmentMasterModel extends HiveObject {
  /// Unique identifier for the investment master.
  ///
  /// Hive field number **0** — stable ID, never change or reuse.
  @HiveField(0)
  String id;

  /// Short name or ticker symbol for the investment (unique).
  ///
  /// Hive field number **1** — required.
  @HiveField(1)
  String shortName;

  /// Full name or description of the investment.
  ///
  /// Hive field number **2** — required.
  @HiveField(2)
  String name;

  /// Category of the investment.
  ///
  /// Hive field number **3** — required, stored as string.
  @HiveField(3)
  String investmentCategory;

  /// Type of tracking (Unit or Amount).
  ///
  /// Hive field number **4** — required, stored as string.
  @HiveField(4)
  String investmentTrackingType;

  /// Currency of the investment.
  ///
  /// Hive field number **5** — required, stored as string.
  @HiveField(5)
  String investmentCurrency;

  /// Risk factor associated with the investment.
  ///
  /// Hive field number **6** — required, stored as string.
  @HiveField(6)
  String riskFactor;

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

  InvestmentMasterModel({
    required this.id,
    required this.shortName,
    required this.name,
    required this.investmentCategory,
    required this.investmentTrackingType,
    required this.investmentCurrency,
    required this.riskFactor,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates an InvestmentMasterModel from a domain entity.
  factory InvestmentMasterModel.fromEntity(InvestmentMaster entity) {
    return InvestmentMasterModel(
      id: entity.id,
      shortName: entity.shortName,
      name: entity.name,
      investmentCategory: entity.investmentCategory.name,
      investmentTrackingType: entity.investmentTrackingType.name,
      investmentCurrency: entity.investmentCurrency.name,
      riskFactor: entity.riskFactor.name,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// Converts this model to a domain entity.
  InvestmentMaster toEntity() {
    return InvestmentMaster(
      id: id,
      shortName: shortName,
      name: name,
      investmentCategory: InvestmentCategory.values.firstWhere(
        (e) => e.name == investmentCategory,
        orElse: () => InvestmentCategory.cryptocurrency,
      ),
      investmentTrackingType: InvestmentTrackingType.values.firstWhere(
        (e) => e.name == investmentTrackingType,
        orElse: () => InvestmentTrackingType.amount,
      ),
      investmentCurrency: InvestmentCurrency.values.firstWhere(
        (e) => e.name == investmentCurrency,
        orElse: () => InvestmentCurrency.inr,
      ),
      riskFactor: RiskFactor.values.firstWhere(
        (e) => e.name == riskFactor,
        orElse: () => RiskFactor.medium,
      ),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

