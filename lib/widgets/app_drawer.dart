import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/design_tokens.dart';
import '../core/organization_notifier.dart';
import '../pages/app_home_page.dart';
import '../trackers/goal_tracker/presentation/pages/goal_tracker_home_page.dart';
import '../trackers/goal_tracker/core/app_icons.dart';
import '../trackers/goal_tracker/presentation/pages/standalone_task_list_page.dart';
import '../trackers/travel_tracker/presentation/pages/travel_tracker_home_page.dart';
import '../trackers/travel_tracker/core/app_icons.dart';
import '../trackers/password_tracker/presentation/pages/password_list_page.dart';
import '../trackers/password_tracker/core/app_icons.dart' as password_tracker;
import '../trackers/expense_tracker/presentation/pages/expense_list_page.dart';
import '../trackers/expense_tracker/core/app_icons.dart' as expense_tracker;
import '../trackers/file_tracker/presentation/pages/file_tracker_home_page.dart';
import '../trackers/file_tracker/core/app_icons.dart' as file_tracker;
import '../trackers/book_tracker/presentation/pages/book_list_page.dart';
import '../trackers/book_tracker/core/app_icons.dart' as book_tracker;
import '../utilities/investment_planner/presentation/pages/plan_list_page.dart';
import '../utilities/retirement_planner/presentation/pages/retirement_planner_home_page.dart';
import '../pages/settings_page.dart';

/// Enum to identify the current page for drawer navigation
enum AppPage {
  appHome,
  goalTracker,
  travelTracker,
  taskTracker,
  passwordTracker,
  expenseTracker,
  fileTracker,
  bookTracker,
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
                        color: cs.onPrimary.withValues(alpha: 0.9),
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
                
                // Always add App Home at the top
                final homeItem = _DrawerTile(
                  icon: Icons.home,
                  title: 'Home',
                  isSelected: currentPage == AppPage.appHome,
                  onTap: () {
                    Navigator.of(context).pop(); // Close drawer
                    if (currentPage != AppPage.appHome) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => const AppHomePage(),
                        ),
                        (route) => false,
                      );
                    }
                  },
                );
                
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
                
                // Task Tracker is always available
                trackerItems.add(
                  _DrawerTile(
                    icon: AppIcons.task,
                    title: 'Task Tracker',
                    isSelected: currentPage == AppPage.taskTracker,
                    onTap: () {
                      Navigator.of(context).pop(); // Close drawer
                      if (currentPage != AppPage.taskTracker) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const StandaloneTaskListPage(),
                          ),
                        );
                      }
                    },
                  ),
                );
                
                // Password Tracker is always available
                trackerItems.add(
                  _DrawerTile(
                    icon: password_tracker.PasswordTrackerIcons.password,
                    title: 'Password Tracker',
                    isSelected: currentPage == AppPage.passwordTracker,
                    onTap: () {
                      Navigator.of(context).pop(); // Close drawer
                      if (currentPage != AppPage.passwordTracker) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const PasswordListPage(),
                          ),
                        );
                      }
                    },
                  ),
                );
                
                // Expense Tracker is always available
                trackerItems.add(
                  _DrawerTile(
                    icon: expense_tracker.ExpenseTrackerIcons.expense,
                    title: 'Expense Tracker',
                    isSelected: currentPage == AppPage.expenseTracker,
                    onTap: () {
                      Navigator.of(context).pop(); // Close drawer
                      if (currentPage != AppPage.expenseTracker) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ExpenseListPage(),
                          ),
                        );
                      }
                    },
                  ),
                );
                
                // File Tracker is always available
                trackerItems.add(
                  _DrawerTile(
                    icon: file_tracker.FileTrackerIcons.file,
                    title: 'File Tracker',
                    isSelected: currentPage == AppPage.fileTracker,
                    onTap: () {
                      Navigator.of(context).pop(); // Close drawer
                      if (currentPage != AppPage.fileTracker) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const FileTrackerHomePage(),
                          ),
                        );
                      }
                    },
                  ),
                );
                
                // Book Tracker is always available
                trackerItems.add(
                  _DrawerTile(
                    icon: book_tracker.BookTrackerIcons.book,
                    title: 'Book Tracker',
                    isSelected: currentPage == AppPage.bookTracker,
                    onTap: () {
                      Navigator.of(context).pop(); // Close drawer
                      if (currentPage != AppPage.bookTracker) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const BookListPage(),
                          ),
                        );
                      }
                    },
                  ),
                );
                
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
                              builder: (_) => const PlanListPage(),
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
                    // Home item at the top
                    homeItem,
                    const Divider(height: 1),
                    
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
      selectedTileColor: cs.primaryContainer.withValues(alpha: 0.3),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.button),
      ),
    );
  }
}

