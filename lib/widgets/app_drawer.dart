import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/design_tokens.dart';
import '../core/organization_notifier.dart';
import '../trackers/goal_tracker/presentation/pages/goal_tracker_home_page.dart';
import '../trackers/goal_tracker/core/app_icons.dart';
import '../trackers/travel_tracker/presentation/pages/travel_tracker_home_page.dart';
import '../trackers/travel_tracker/core/app_icons.dart';
import '../utilities/investment_planner/presentation/pages/investment_planner_home_page.dart';
import '../utilities/retirement_planner/presentation/pages/retirement_planner_home_page.dart';
import '../pages/settings_page.dart';

/// Enum to identify the current page for drawer navigation
enum AppPage {
  appHome,
  goalTracker,
  travelTracker,
  investmentPlanner,
  retirementPlanner,
  settings,
}

/// Shared app drawer widget used across all pages
class AppDrawer extends StatelessWidget {
  const AppDrawer({
    super.key,
    this.currentPage,
  });

  /// Current page identifier to handle navigation appropriately
  final AppPage? currentPage;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Drawer(
      child: Column(
        children: [
          // Drawer header
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: AppGradients.appBar(cs),
            ),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + AppSpacing.m,
              bottom: AppSpacing.l,
              left: AppSpacing.m,
              right: AppSpacing.m,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'All Tracker',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: cs.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Your productivity hub',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onPrimary.withOpacity(0.9),
                      ),
                ),
              ],
            ),
          ),

          // Drawer content
          Expanded(
            child: Consumer<OrganizationNotifier>(
              builder: (context, orgNotifier, _) {
                final trackerItems = <Widget>[];
                final utilityItems = <Widget>[];
                
                // Build tracker items based on toggle states
                if (orgNotifier.goalTrackerEnabled) {
                  trackerItems.add(
                    _DrawerTile(
                      icon: AppIcons.goal,
                      title: 'Goal Tracker',
                      isSelected: currentPage == AppPage.goalTracker,
                      onTap: () {
                        Navigator.of(context).pop(); // Close drawer
                        if (currentPage != AppPage.goalTracker) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const HomePage(),
                            ),
                          );
                        }
                      },
                    ),
                  );
                }
                
                if (orgNotifier.travelTrackerEnabled) {
                  trackerItems.add(
                    _DrawerTile(
                      icon: TravelTrackerIcons.trip,
                      title: 'Travel Tracker',
                      isSelected: currentPage == AppPage.travelTracker,
                      onTap: () {
                        Navigator.of(context).pop(); // Close drawer
                        if (currentPage != AppPage.travelTracker) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const TravelTrackerHomePage(),
                            ),
                          );
                        }
                      },
                    ),
                  );
                }
                
                // Build utility items based on toggle states
                if (orgNotifier.investmentPlannerEnabled) {
                  utilityItems.add(
                    _DrawerTile(
                      icon: Icons.account_balance,
                      title: 'Investment Planner',
                      isSelected: currentPage == AppPage.investmentPlanner,
                      onTap: () {
                        Navigator.of(context).pop(); // Close drawer
                        if (currentPage != AppPage.investmentPlanner) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const InvestmentPlannerHomePage(),
                            ),
                          );
                        }
                      },
                    ),
                  );
                }
                
                if (orgNotifier.retirementPlannerEnabled) {
                  utilityItems.add(
                    _DrawerTile(
                      icon: Icons.account_balance_wallet,
                      title: 'Retirement Planner',
                      isSelected: currentPage == AppPage.retirementPlanner,
                      onTap: () {
                        Navigator.of(context).pop(); // Close drawer
                        if (currentPage != AppPage.retirementPlanner) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const RetirementPlannerHomePage(),
                            ),
                          );
                        }
                      },
                    ),
                  );
                }
                
                return ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    // Tracker Section (only show if there are enabled trackers)
                    if (trackerItems.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.m,
                          AppSpacing.l,
                          AppSpacing.m,
                          AppSpacing.s,
                        ),
                        child: Text(
                          'TRACKER',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                        ),
                      ),
                      ...trackerItems,
                      const Divider(height: 1),
                    ],

                    // Utility Section (only show if there are enabled utilities)
                    if (utilityItems.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.m,
                          AppSpacing.l,
                          AppSpacing.m,
                          AppSpacing.s,
                        ),
                        child: Text(
                          'UTILITY',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                        ),
                      ),
                      ...utilityItems,
                      const Divider(height: 1),
                    ],

                // Settings Section
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.m,
                    AppSpacing.l,
                    AppSpacing.m,
                    AppSpacing.s,
                  ),
                  child: Text(
                    'SETTINGS',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                  ),
                ),
                _DrawerTile(
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  isSelected: currentPage == AppPage.settings,
                  onTap: () {
                    Navigator.of(context).pop(); // Close drawer
                    if (currentPage != AppPage.settings) {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SettingsPage()),
                      );
                    }
                  },
                ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual drawer menu item
class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isSelected = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListTile(
      leading: Icon(icon, color: cs.onSurface),
      title: Text(title),
      selected: isSelected,
      selectedTileColor: cs.primaryContainer.withOpacity(0.3),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.button),
      ),
    );
  }
}

