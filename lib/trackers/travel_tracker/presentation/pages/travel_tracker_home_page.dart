import 'package:flutter/material.dart';
import 'trip_list_page.dart';

/// Home page for Travel Tracker module.
/// Entry point that navigates to the trip list.
class TravelTrackerHomePage extends StatelessWidget {
  const TravelTrackerHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const TripListPage();
  }
}

