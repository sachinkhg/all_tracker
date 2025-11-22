import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/design_tokens.dart';
import '../../../../core/organization_notifier.dart';
import '../../../../pages/app_home_page.dart';
import 'retirement_plan_list_page.dart';
import 'retirement_advance_settings_page.dart';
import '../../../../widgets/app_drawer.dart';

/// Main landing page for Retirement Planner
class RetirementPlannerHomePage extends StatelessWidget {
  const RetirementPlannerHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Retirement Planner'),
        actions: [
          Consumer<OrganizationNotifier>(
            builder: (context, orgNotifier, _) {
              // Only show home icon if default home page is app_home
              if (orgNotifier.defaultHomePage == 'app_home') {
                return IconButton(
                  icon: const Icon(Icons.home),
                  tooltip: 'Home',
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const AppHomePage()),
                      (route) => false,
                    );
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: AppGradients.appBar(cs),
          ),
        ),
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(
          color: cs.brightness == Brightness.dark
              ? Colors.white.withOpacity(0.95)
              : Colors.black87,
          opacity: 1.0,
        ),
        actionsIconTheme: IconThemeData(
          color: cs.brightness == Brightness.dark
              ? Colors.white.withOpacity(0.95)
              : Colors.black87,
          opacity: 1.0,
        ),
        foregroundColor: cs.onPrimary,
        elevation: 0,
      ),
      drawer: const AppDrawer(currentPage: AppPage.retirementPlanner),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            const Text(
              'Retirement Planner',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Plan your retirement with comprehensive calculations',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            _QuickActionCard(
              title: 'View Plans',
              subtitle: 'View and manage your retirement plans',
              icon: Icons.list,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RetirementPlanListPage(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _QuickActionCard(
              title: 'Advanced Settings',
              subtitle: 'Configure default retirement calculation parameters',
              icon: Icons.settings,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RetirementAdvanceSettingsPage(),
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

