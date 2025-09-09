import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../common/widgets/glass_card.dart';

class DashboardTab {
  final String id;
  final String name;
  final IconData icon;
  final Color color;

  DashboardTab({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });
}

class DashboardTabBar extends StatelessWidget {
  final List<DashboardTab> tabs;
  final String activeTab;
  final ValueChanged<String> onTabChanged;

  const DashboardTabBar({
    super.key,
    required this.tabs,
    required this.activeTab,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: tabs.map((tab) {
            final isActive = activeTab == tab.id;
            
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: AnimatedContainer(
                duration: AppConstants.mediumAnimation,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onTabChanged(tab.id),
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: AppConstants.mediumAnimation,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        gradient: isActive
                            ? LinearGradient(
                                colors: [tab.color, tab.color.withOpacity(0.8)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: isActive ? null : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: isActive ? AppTheme.softShadow : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            tab.icon,
                            size: 20,
                            color: isActive ? Colors.white : AppTheme.textMuted,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            tab.name,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: isActive ? Colors.white : AppTheme.textMuted,
                              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}