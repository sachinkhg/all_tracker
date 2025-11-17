import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/design_tokens.dart';
import '../trackers/goal_tracker/presentation/pages/home_page.dart';
import '../trackers/goal_tracker/core/app_icons.dart';
import '../utilities/investment_planner/presentation/pages/investment_planner_home_page.dart';
import 'settings_page.dart';

/// Main landing page for the All Tracker app
/// Displays all available sections (Trackers, Utilities, Settings) as navigable cards
class AppHomePage extends StatelessWidget {
  const AppHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Tracker'),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.s),
            // Welcome section
            _WelcomeSection()
                .animate()
                .fade(duration: AppAnimations.short, curve: AppAnimations.ease),
            const SizedBox(height: AppSpacing.l),

            // Tracker Section
            _SectionHeader(
              title: 'TRACKER',
              icon: Icons.track_changes,
            )
                .animate()
                .fade(duration: AppAnimations.short, curve: AppAnimations.ease),
            const SizedBox(height: AppSpacing.m),
            _SectionCard(
              title: 'Goal Tracker',
              subtitle: 'Track your goals, milestones, tasks, and habits',
              icon: AppIcons.goal,
              gradient: AppGradients.primary(cs),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const HomePage(),
                  ),
                );
              },
            )
                .animate()
                .fade(duration: AppAnimations.short, curve: AppAnimations.ease)
                .moveY(begin: 8, end: 0, duration: AppAnimations.short, curve: AppAnimations.ease),

            const SizedBox(height: AppSpacing.l),

            // Utility Section
            _SectionHeader(
              title: 'UTILITY',
              icon: Icons.build,
            )
                .animate()
                .fade(duration: AppAnimations.short, curve: AppAnimations.ease),
            const SizedBox(height: AppSpacing.m),
            _SectionCard(
              title: 'Investment Planner',
              subtitle: 'Plan your investments based on income and expenses',
              icon: Icons.account_balance,
              gradient: AppGradients.secondary(cs),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const InvestmentPlannerHomePage(),
                  ),
                );
              },
            )
                .animate()
                .fade(duration: AppAnimations.short, curve: AppAnimations.ease)
                .moveY(begin: 8, end: 0, duration: AppAnimations.short, curve: AppAnimations.ease),

            const SizedBox(height: AppSpacing.l),

            // Settings Section
            _SectionHeader(
              title: 'SETTINGS',
              icon: Icons.settings,
            )
                .animate()
                .fade(duration: AppAnimations.short, curve: AppAnimations.ease),
            const SizedBox(height: AppSpacing.m),
            _SectionCard(
              title: 'Settings',
              subtitle: 'Configure app preferences and manage your data',
              icon: Icons.settings_outlined,
              gradient: AppGradients.tertiary(cs),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const SettingsPage(),
                  ),
                );
              },
            )
                .animate()
                .fade(duration: AppAnimations.short, curve: AppAnimations.ease)
                .moveY(begin: 8, end: 0, duration: AppAnimations.short, curve: AppAnimations.ease),

            const SizedBox(height: AppSpacing.l),
          ],
        ),
      ),
    );
  }
}

/// Welcome section at the top of the landing page
class _WelcomeSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        gradient: AppGradients.appBar(cs),
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome to All Tracker',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: cs.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            'Your productivity hub',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.onPrimary.withOpacity(0.9),
                ),
          ),
        ],
      ),
    );
  }
}

/// Section header widget
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.icon,
  });

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: cs.onSurfaceVariant,
        ),
        const SizedBox(width: AppSpacing.s),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
        ),
      ],
    );
  }
}

/// Section card widget for navigation
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      elevation: AppElevations.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: Container(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(AppRadii.card),
          ),
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.m),
                decoration: BoxDecoration(
                  color: cs.onPrimary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppRadii.button),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: cs.onPrimary,
                ),
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: cs.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: cs.onPrimary.withOpacity(0.9),
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: cs.onPrimary,
                size: 28,
              ),
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
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const InvestmentPlannerHomePage(),
                      ),
                    );
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

