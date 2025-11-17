import 'package:flutter/material.dart';
import '../../../../core/design_tokens.dart';
import 'component_config_page.dart';
import 'category_config_page.dart';
import 'plan_list_page.dart';
import '../../../../pages/settings_page.dart';
import '../../../../trackers/goal_tracker/presentation/pages/home_page.dart';
import '../../../../trackers/goal_tracker/core/app_icons.dart';
import '../../../../pages/app_home_page.dart';

/// Main landing page for Investment Planner
class InvestmentPlannerHomePage extends StatelessWidget {
  const InvestmentPlannerHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Investment Planner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            tooltip: 'Home',
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const AppHomePage()),
                (route) => false,
              );
            },
          ),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: AppGradients.appBar(cs),
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: cs.onPrimary,
        elevation: 0,
      ),
      drawer: _AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            const Text(
              'Investment Planner',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Plan your investments based on income and expenses',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            _QuickActionCard(
              title: 'Configure Components',
              subtitle: 'Set up investment components (NPS, PPF, etc.)',
              icon: Icons.account_balance,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ComponentConfigPage(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _QuickActionCard(
              title: 'Manage Categories',
              subtitle: 'Configure income and expense categories',
              icon: Icons.category,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CategoryConfigPage(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _QuickActionCard(
              title: 'View Plans',
              subtitle: 'View and manage saved investment plans',
              icon: Icons.list,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PlanListPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(icon, size: 40, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

/// Side menu drawer providing navigation to different app sections
class _AppDrawer extends StatelessWidget {
  const _AppDrawer();

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
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Tracker Section
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
                _DrawerTile(
                  icon: AppIcons.goal,
                  title: 'Goal Tracker',
                  onTap: () {
                    Navigator.of(context).pop(); // Close drawer
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const HomePage(),
                      ),
                    );
                  },
                ),
                
                const Divider(height: 1),
                
                // Utility Section
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
                _DrawerTile(
                  icon: Icons.account_balance,
                  title: 'Investment Planner',
                  onTap: () {
                    Navigator.of(context).pop(); // Close drawer
                    // Already on Investment Planner home, so no navigation needed
                  },
                ),
                
                const Divider(height: 1),
                
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
                  onTap: () {
                    Navigator.of(context).pop(); // Close drawer
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsPage()),
                    );
                  },
                ),
              ],
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
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListTile(
      leading: Icon(icon, color: cs.onSurface),
      title: Text(title),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.button),
      ),
    );
  }
}

