import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../common/widgets/glass_card.dart';
import '../widgets/dashboard_layout.dart';
import '../widgets/dashboard_tab_bar.dart';

class ManagementDashboardPage extends ConsumerStatefulWidget {
  const ManagementDashboardPage({super.key});

  @override
  ConsumerState<ManagementDashboardPage> createState() => _ManagementDashboardPageState();
}

class _ManagementDashboardPageState extends ConsumerState<ManagementDashboardPage> {
  String _activeTab = 'dashboard-stats';

  final List<DashboardTab> _tabs = [
    DashboardTab(
      id: 'dashboard-stats',
      name: 'Dashboard Overview',
      icon: Icons.dashboard_outlined,
      color: Colors.blue,
    ),
    DashboardTab(
      id: 'student-heatmap',
      name: 'Student Activity',
      icon: Icons.analytics_outlined,
      color: Colors.green,
    ),
    DashboardTab(
      id: 'ai-analysis',
      name: 'AI Student Analysis',
      icon: Icons.psychology_outlined,
      color: Colors.purple,
    ),
    DashboardTab(
      id: 'alumni-verification',
      name: 'Alumni Verification',
      icon: Icons.verified_user_outlined,
      color: Colors.orange,
    ),
    DashboardTab(
      id: 'event-management',
      name: 'Event Management',
      icon: Icons.event_outlined,
      color: Colors.teal,
    ),
    DashboardTab(
      id: 'password',
      name: 'Change Password',
      icon: Icons.lock_outline,
      color: Colors.red,
    ),
    DashboardTab(
      id: 'alumni-network',
      name: 'Alumni Network',
      icon: Icons.people_outline,
      color: Colors.indigo,
    ),
    DashboardTab(
      id: 'job-portal',
      name: 'Job Portal',
      icon: Icons.work_outline,
      color: Colors.amber,
    ),
    DashboardTab(
      id: 'chat',
      name: 'Communication',
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
              gradient: const LinearGradient(
                colors: [Colors.purple, Colors.pink],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppTheme.glowShadow,
            ),
            child: const Icon(
              Icons.admin_panel_settings,
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
                  'Welcome back, Management!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Monitor student performance, verify alumni, and oversee the entire assessment system.',
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
      title: 'Management Dashboard',
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
          Expanded(
            child: _renderActiveComponent(),
          ),
        ],
      ),
    );
  }
}