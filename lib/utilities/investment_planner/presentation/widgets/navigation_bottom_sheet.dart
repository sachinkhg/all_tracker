import 'package:flutter/material.dart';
import '../pages/category_config_page.dart';
import '../pages/component_config_page.dart';

/// Bottom sheet for navigating to category and component configuration pages
class NavigationBottomSheet {
  static void show(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Title
              Text(
                'Navigation',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              
              // Category Configuration Option
              ListTile(
                leading: const Icon(Icons.category),
                title: const Text('Categories'),
                subtitle: const Text('Manage Income & Expense Categories'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CategoryConfigPage(),
                    ),
                  );
                },
              ),
              
              // Component Configuration Option
              ListTile(
                leading: const Icon(Icons.account_balance),
                title: const Text('Components'),
                subtitle: const Text('Manage Investment Components'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ComponentConfigPage(),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

