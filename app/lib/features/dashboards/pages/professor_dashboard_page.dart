import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../common/widgets/glass_card.dart';
import '../widgets/dashboard_layout.dart';
import '../widgets/dashboard_tab_bar.dart';

class ProfessorDashboardPage extends ConsumerStatefulWidget {
  const ProfessorDashboardPage({super.key});

  @override
  ConsumerState<ProfessorDashboardPage> createState() => _ProfessorDashboardPageState();
}

class _ProfessorDashboardPageState extends ConsumerState<ProfessorDashboardPage> {
  String _activeTab = 'assessments';

  final List<DashboardTab> _tabs = [
    DashboardTab(
      id: 'assessments',
      name: 'My Assessments',
      icon: Icons.description_outlined,
      color: Colors.blue,
    ),
    DashboardTab(
      id: 'create-assessment',
      name: 'Create Assessment',
      icon: Icons.add_circle_outline,
      color: Colors.green,
    ),
    DashboardTab(
      id: 'attendance',
      name: 'Attendance Management',
      icon: Icons.people_outline,
      color: Colors.purple,
    ),
    DashboardTab(
      id: 'assessment-insights',
      name: 'Assessment Insights',
      icon: Icons.analytics_outlined,
      color: Colors.orange,
    ),
    DashboardTab(
      id: 'student-activity',
      name: 'Student Activity',
      icon: Icons.trending_up_outlined,
      color: Colors.teal,
    ),
    DashboardTab(
      id: 'password',
      name: 'Change Password',
      icon: Icons.lock_outline,
      color: Colors.red,
    ),
    DashboardTab(
      id: 'events',
      name: 'Events',
      icon: Icons.event_outlined,
      color: Colors.indigo,
    ),
    DashboardTab(
      id: 'chat',
      name: 'Chat with Students',
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
                colors: [Colors.green, Colors.teal],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
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
                  'Welcome back, Professor!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Create assessments, monitor student performance, and engage with your students.',
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
      title: 'Professor Dashboard',
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