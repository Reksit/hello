import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../common/widgets/glass_card.dart';
import '../widgets/dashboard_layout.dart';
import '../widgets/dashboard_stats_card.dart';
import '../widgets/dashboard_tab_bar.dart';

class StudentDashboardPage extends ConsumerStatefulWidget {
  const StudentDashboardPage({super.key});

  @override
  ConsumerState<StudentDashboardPage> createState() => _StudentDashboardPageState();
}

class _StudentDashboardPageState extends ConsumerState<StudentDashboardPage>
    with TickerProviderStateMixin {
  String _activeTab = 'profile';
  late AnimationController _animationController;

  final List<DashboardTab> _tabs = [
    DashboardTab(
      id: 'profile',
      name: 'My Profile',
      icon: Icons.person_outline,
      color: Colors.blue,
    ),
    DashboardTab(
      id: 'activity',
      name: 'My Activity',
      icon: Icons.analytics_outlined,
      color: Colors.green,
    ),
    DashboardTab(
      id: 'attendance',
      name: 'My Attendance',
      icon: Icons.calendar_today_outlined,
      color: Colors.purple,
    ),
    DashboardTab(
      id: 'resume',
      name: 'Resume Manager',
      icon: Icons.description_outlined,
      color: Colors.orange,
    ),
    DashboardTab(
      id: 'password',
      name: 'Change Password',
      icon: Icons.lock_outline,
      color: Colors.red,
    ),
    DashboardTab(
      id: 'ai-assessment',
      name: 'Practice with AI',
      icon: Icons.psychology_outlined,
      color: Colors.indigo,
    ),
    DashboardTab(
      id: 'class-assessments',
      name: 'Class Assessments',
      icon: Icons.quiz_outlined,
      color: Colors.cyan,
    ),
    DashboardTab(
      id: 'task-management',
      name: 'Task Management',
      icon: Icons.task_outlined,
      color: Colors.pink,
    ),
    DashboardTab(
      id: 'events',
      name: 'Events',
      icon: Icons.event_outlined,
      color: Colors.teal,
    ),
    DashboardTab(
      id: 'job-board',
      name: 'Job Board',
      icon: Icons.work_outline,
      color: Colors.amber,
    ),
    DashboardTab(
      id: 'alumni-directory',
      name: 'Alumni Network',
      icon: Icons.school_outlined,
      color: Colors.deepPurple,
    ),
    DashboardTab(
      id: 'ai-chat',
      name: 'AI Chatbot',
      icon: Icons.smart_toy_outlined,
      color: Colors.emerald,
    ),
    DashboardTab(
      id: 'user-chat',
      name: 'Messages',
      icon: Icons.message_outlined,
      color: Colors.rose,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildWelcomeSection() {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                      'Welcome back, Student!',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ready to enhance your learning journey with AI-powered assessments and connect with industry professionals.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.successColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.successColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Online',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.successColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
            title: 'AI Assessments',
            value: '0',
            subtitle: 'Completed',
            icon: Icons.psychology_outlined,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: DashboardStatsCard(
            title: 'Class Tests',
            value: '0',
            subtitle: 'This Semester',
            icon: Icons.quiz_outlined,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: DashboardStatsCard(
            title: 'Tasks',
            value: '0',
            subtitle: 'Active Goals',
            icon: Icons.task_outlined,
            color: Colors.purple,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: DashboardStatsCard(
            title: 'Connections',
            value: '0',
            subtitle: 'Connected',
            icon: Icons.people_outline,
            color: Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _renderActiveComponent() {
    // This would contain the actual component implementations
    // For now, returning a placeholder
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
      title: 'Student Dashboard',
      child: Column(
        children: [
          // Welcome section
          _buildWelcomeSection(),
          
          const SizedBox(height: 24),
          
          // Tab navigation
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
          
          // Stats section (only show on profile tab)
          if (_activeTab == 'profile') ...[
            _buildStatsSection(),
            const SizedBox(height: 24),
          ],
          
          // Active component
          Expanded(
            child: _renderActiveComponent(),
          ),
        ],
      ),
    );
  }
}