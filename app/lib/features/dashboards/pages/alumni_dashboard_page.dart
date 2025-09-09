import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../common/widgets/glass_card.dart';
import '../widgets/dashboard_layout.dart';
import '../widgets/dashboard_stats_card.dart';
import '../widgets/dashboard_tab_bar.dart';

class AlumniDashboardPage extends ConsumerStatefulWidget {
  const AlumniDashboardPage({super.key});

  @override
  ConsumerState<AlumniDashboardPage> createState() => _AlumniDashboardPageState();
}

class _AlumniDashboardPageState extends ConsumerState<AlumniDashboardPage> {
  String _activeTab = 'profile';

  final List<DashboardTab> _tabs = [
    DashboardTab(
      id: 'profile',
      name: 'My Profile',
      icon: Icons.person_outline,
      color: Colors.blue,
    ),
    DashboardTab(
      id: 'directory',
      name: 'Alumni Directory',
      icon: Icons.people_outline,
      color: Colors.green,
    ),
    DashboardTab(
      id: 'connections',
      name: 'Connection Requests',
      icon: Icons.connect_without_contact_outlined,
      color: Colors.purple,
    ),
    DashboardTab(
      id: 'password',
      name: 'Change Password',
      icon: Icons.lock_outline,
      color: Colors.red,
    ),
    DashboardTab(
      id: 'jobs',
      name: 'Job Board',
      icon: Icons.work_outline,
      color: Colors.orange,
    ),
    DashboardTab(
      id: 'events',
      name: 'Events',
      icon: Icons.event_outlined,
      color: Colors.teal,
    ),
    DashboardTab(
      id: 'request-event',
      name: 'Request Event',
      icon: Icons.add_circle_outline,
      color: Colors.indigo,
    ),
    DashboardTab(
      id: 'alumni-management-requests',
      name: 'Alumni Management Requests',
      icon: Icons.admin_panel_settings_outlined,
      color: Colors.amber,
    ),
    DashboardTab(
      id: 'chat',
      name: 'Chat',
      icon: Icons.message_outlined,
      color: Colors.pink,
    ),
  ];

  Widget _buildWelcomeSection() {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppTheme.glowShadow,
            ),
            child: const Icon(
              Icons.school,
              size: 30,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, Alumni!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage your professional network, share career opportunities, and mentor the next generation.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Row(
      children: [
        Expanded(
          child: DashboardStatsCard(
            title: 'Network Connections',
            value: '0',
            subtitle: 'Connections',
            icon: Icons.people_outline,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: DashboardStatsCard(
            title: 'Event Participation',
            value: '0',
            subtitle: 'Events',
            icon: Icons.event_outlined,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: DashboardStatsCard(
            title: 'Career Opportunities',
            value: '0',
            subtitle: 'Jobs Posted',
            icon: Icons.work_outline,
            color: Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _renderActiveComponent() {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _tabs.firstWhere((tab) => tab.id == _activeTab).icon,
              size: 64,
              color: AppTheme.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              _tabs.firstWhere((tab) => tab.id == _activeTab).name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Component implementation coming soon...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      title: 'Alumni Dashboard',
      child: Column(
        children: [
          _buildWelcomeSection(),
          const SizedBox(height: 24),
          DashboardTabBar(
            tabs: _tabs,
            activeTab: _activeTab,
            onTabChanged: (tabId) {
              setState(() {
                _activeTab = tabId;
              });
            },
          ),
          const SizedBox(height: 24),
          if (_activeTab == 'profile') ...[
            _buildStatsSection(),
            const SizedBox(height: 24),
          ],
          Expanded(
            child: _renderActiveComponent(),
          ),
        ],
      ),
    );
  }
}