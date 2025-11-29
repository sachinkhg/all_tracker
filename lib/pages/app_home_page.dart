import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../core/design_tokens.dart';
import '../core/organization_notifier.dart';
import '../trackers/goal_tracker/presentation/pages/goal_tracker_home_page.dart';
import '../trackers/goal_tracker/core/app_icons.dart';
import '../trackers/goal_tracker/presentation/pages/standalone_task_list_page.dart';
import '../trackers/travel_tracker/presentation/pages/travel_tracker_home_page.dart';
import '../trackers/travel_tracker/core/app_icons.dart';
import '../utilities/investment_planner/presentation/pages/investment_planner_home_page.dart';
import '../utilities/retirement_planner/presentation/pages/retirement_planner_home_page.dart';
import '../widgets/app_drawer.dart';

/// Main landing page for the All Tracker app
/// Displays all available sections (Trackers, Utilities) as navigable cards
class AppHomePage extends StatelessWidget {
  const AppHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final orgNotifier = context.watch<OrganizationNotifier>();

    // Define tracker items (filtered based on toggle states)
    final trackerItems = <_SectionItem>[];
    
    if (orgNotifier.goalTrackerEnabled) {
      trackerItems.add(
        _SectionItem(
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
        ),
      );
    }
    
    if (orgNotifier.travelTrackerEnabled) {
      trackerItems.add(
        _SectionItem(
          title: 'Travel Tracker',
          subtitle: 'Plan trips, manage itineraries, and journal your travels',
          icon: TravelTrackerIcons.trip,
          gradient: AppGradients.primary(cs),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const TravelTrackerHomePage(),
              ),
            );
          },
        ),
      );
    }
    
    // Task Tracker is always available (standalone tasks)
    trackerItems.add(
      _SectionItem(
        title: 'Task Tracker',
        subtitle: 'Manage your tasks without milestones',
        icon: AppIcons.task,
        gradient: AppGradients.tertiary(cs),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const StandaloneTaskListPage(),
            ),
          );
        },
      ),
    );

    // Define utility items (filtered based on toggle states)
    final utilityItems = <_SectionItem>[];
    
    if (orgNotifier.investmentPlannerEnabled) {
      utilityItems.add(
        _SectionItem(
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
        ),
      );
    }
    
    if (orgNotifier.retirementPlannerEnabled) {
      utilityItems.add(
        _SectionItem(
          title: 'Retirement Planner',
          subtitle: 'Calculate your retirement corpus and investment needs',
          icon: Icons.account_balance_wallet,
          gradient: AppGradients.secondary(cs),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const RetirementPlannerHomePage(),
              ),
            );
          },
        ),
      );
    }

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
        iconTheme: IconThemeData(
          color: cs.brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.95)
              : Colors.black87,
          opacity: 1.0,
        ),
        actionsIconTheme: IconThemeData(
          color: cs.brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.95)
              : Colors.black87,
          opacity: 1.0,
        ),
        elevation: 0,
      ),
      drawer: const AppDrawer(currentPage: AppPage.appHome),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.s),
            // Welcome section
            // _WelcomeSection()
            //     .animate()
            //     .fade(duration: AppAnimations.short, curve: AppAnimations.ease),
            // const SizedBox(height: AppSpacing.l),

            // Tracker Section (only show if there are enabled trackers)
            if (trackerItems.isNotEmpty) ...[
              _SectionHeader(
                title: 'TRACKER',
                icon: Icons.track_changes,
              )
                  .animate()
                  .fade(duration: AppAnimations.short, curve: AppAnimations.ease),
              const SizedBox(height: AppSpacing.m),
              _SectionGrid(
                items: trackerItems,
                crossAxisCount: 3,
              ),
              const SizedBox(height: AppSpacing.s),
            ],

            // Utility Section (only show if there are enabled utilities)
            if (utilityItems.isNotEmpty) ...[
              _SectionHeader(
                title: 'UTILITY',
                icon: Icons.build,
              )
                  .animate()
                  .fade(duration: AppAnimations.short, curve: AppAnimations.ease),
              const SizedBox(height: AppSpacing.m),
              _SectionGrid(
                items: utilityItems,
                crossAxisCount: 3,
              ),
            ],

            const SizedBox(height: AppSpacing.l),
          ],
        ),
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

/// Data class for section items
class _SectionItem {
  const _SectionItem({
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
}

/// Grid widget for displaying section items
class _SectionGrid extends StatelessWidget {
  const _SectionGrid({
    required this.items,
    required this.crossAxisCount,
  });

  final List<_SectionItem> items;
  final int crossAxisCount;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: AppSpacing.m,
        mainAxisSpacing: AppSpacing.m,
        childAspectRatio: 0.65,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _SectionCard(
          title: item.title,
          subtitle: item.subtitle,
          icon: item.icon,
          gradient: item.gradient,
          onTap: item.onTap,
        )
            .animate()
            .fade(duration: AppAnimations.short, curve: AppAnimations.ease)
            .moveY(begin: 8, end: 0, duration: AppAnimations.short, curve: AppAnimations.ease);
      },
    );
  }
}

/// Section card widget for navigation (optimized for grid layout)
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Card(
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
              padding: const EdgeInsets.all(AppSpacing.m),
              child: Icon(
                icon,
                size: 32,
                color: cs.onPrimary,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: cs.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontSize: 9,
              ),
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}


