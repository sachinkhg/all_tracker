/// Domain enum for expense groups/categories.
///
/// This enum represents the different categories that expenses can be grouped into.
/// Each group can have a display name and optionally a color for UI purposes.
enum ExpenseGroup {
  food,
  shopping,
  subscription,
  health,
  utility,
  outings,
  service,
  petrol;

  /// Returns a human-readable display name for the expense group.
  String get displayName {
    switch (this) {
      case ExpenseGroup.food:
        return 'Food';
      case ExpenseGroup.shopping:
        return 'Shopping';
      case ExpenseGroup.subscription:
        return 'Subscription';
      case ExpenseGroup.health:
        return 'Health';
      case ExpenseGroup.utility:
        return 'Utility';
      case ExpenseGroup.outings:
        return 'Outings';
      case ExpenseGroup.service:
        return 'Service';
      case ExpenseGroup.petrol:
        return 'Petrol';
    }
  }

  /// Returns a color index for UI theming (can be used with ColorScheme).
  /// Returns 0-7 for different color variations.
  int get colorIndex {
    switch (this) {
      case ExpenseGroup.food:
        return 0;
      case ExpenseGroup.shopping:
        return 1;
      case ExpenseGroup.subscription:
        return 2;
      case ExpenseGroup.health:
        return 3;
      case ExpenseGroup.utility:
        return 4;
      case ExpenseGroup.outings:
        return 5;
      case ExpenseGroup.service:
        return 6;
      case ExpenseGroup.petrol:
        return 7;
    }
  }
}

