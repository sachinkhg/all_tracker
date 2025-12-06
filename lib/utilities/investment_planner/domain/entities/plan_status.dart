/// Status of an Investment Plan
enum PlanStatus {
  draft,
  approved,
  executed;

  /// Display name for UI
  String get displayName {
    switch (this) {
      case PlanStatus.draft:
        return 'Draft';
      case PlanStatus.approved:
        return 'Approved';
      case PlanStatus.executed:
        return 'Executed';
    }
  }

  /// Convert to string for Hive storage
  String toJson() => name;

  /// Parse from string (for Hive storage)
  static PlanStatus fromJson(String? value) {
    if (value == null) return PlanStatus.draft;
    try {
      return PlanStatus.values.firstWhere(
        (e) => e.name == value,
        orElse: () => PlanStatus.draft,
      );
    } catch (e) {
      return PlanStatus.draft;
    }
  }
}

