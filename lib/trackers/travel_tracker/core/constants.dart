import 'package:flutter/material.dart';

/// ---------------------------------------------------------------------------
/// Travel Tracker Constants
/// ---------------------------------------------------------------------------
///
/// Purpose:
/// - Defines box names, activity types, expense categories, and other constants
///   specific to the travel tracker module.
/// - Keeps module-level constants separate from app-wide constants.

/// Hive box names for travel tracker persistence.
const String tripBoxName = 'trips_box';
const String tripProfileBoxName = 'trip_profiles_box';
const String travelerBoxName = 'travelers_box';
const String itineraryDayBoxName = 'itinerary_days_box';
const String itineraryItemBoxName = 'itinerary_items_box';
const String journalEntryBoxName = 'journal_entries_box';
const String photoBoxName = 'photos_box';
const String expenseBoxName = 'expenses_box';

/// Activity types for itinerary items.
enum ItineraryItemType {
  travel,
  stay,
  meal,
  sightseeing,
}

/// Activity type labels for display.
const Map<ItineraryItemType, String> itineraryItemTypeLabels = {
  ItineraryItemType.travel: 'Travel',
  ItineraryItemType.stay: 'Stay',
  ItineraryItemType.meal: 'Meal',
  ItineraryItemType.sightseeing: 'Sightseeing',
};

/// Activity type icons for display.
final Map<ItineraryItemType, IconData> itineraryItemTypeIcons = {
  ItineraryItemType.travel: Icons.directions_transit,
  ItineraryItemType.stay: Icons.hotel,
  ItineraryItemType.meal: Icons.restaurant,
  ItineraryItemType.sightseeing: Icons.camera_alt,
};

/// Expense categories.
enum ExpenseCategory {
  food,
  travel,
  stay,
  other,
}

/// Expense category labels for display.
const Map<ExpenseCategory, String> expenseCategoryLabels = {
  ExpenseCategory.food: 'Food',
  ExpenseCategory.travel: 'Travel',
  ExpenseCategory.stay: 'Stay',
  ExpenseCategory.other: 'Other',
};

/// Common currency codes.
const List<String> commonCurrencies = [
  'USD',
  'EUR',
  'GBP',
  'JPY',
  'INR',
  'AUD',
  'CAD',
  'CHF',
  'CNY',
  'NZD',
];

/// Default currency code.
const String defaultCurrency = 'USD';

/// Trip types.
enum TripType {
  work,
  leisure,
}

/// Trip type labels for display.
const Map<TripType, String> tripTypeLabels = {
  TripType.work: 'Work',
  TripType.leisure: 'Leisure',
};

/// Trip type icons for display.
final Map<TripType, IconData> tripTypeIcons = {
  TripType.work: Icons.business,
  TripType.leisure: Icons.beach_access,
};

