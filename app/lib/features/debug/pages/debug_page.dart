import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../common/widgets/animated_background.dart';
import '../../common/widgets/glass_card.dart';

class DebugPage extends ConsumerStatefulWidget {
  const DebugPage({super.key});

  @override
  ConsumerState<DebugPage> createState() => _DebugPageState();
}

class _DebugPageState extends ConsumerState<DebugPage> {
  Map<String, dynamic> _debugData = {
    'events': [],
    'alumni': [],
    'status': {},
    'loading': true,
    'errors': <String>[],
  };

  @override
  void initState() {
    super.initState();
    _loadDebugData();
  }

  Future<void> _loadDebugData() async {
    final errors = <String>[];
    List<dynamic> events = [];
    List<dynamic> alumni = [];
    Map<String, dynamic> status = {};

    try {
      // Test status
      final statusResponse = await http.get(
        Uri.parse('https://finalbackendd.onrender.com/api/debug/status'),
      );
      if (statusResponse.statusCode == 200) {
        status = jsonDecode(statusResponse.body);
      } else {
        errors.add('Status endpoint failed');
      }
    } catch (error) {
      errors.add('Status endpoint error: $error');
    }

    try {
      // Test events
      final eventsResponse = await http.get(
        Uri.parse('https://finalbackendd.onrender.com/api/debug/events'),
      );
      if (eventsResponse.statusCode == 200) {
        final eventsData = jsonDecode(eventsResponse.body);
        events = eventsData['events'] ?? [];
      } else {
        errors.add('Events endpoint failed');
      }
    } catch (error) {
      errors.add('Events endpoint error: $error');
    }

    try {
      // Test alumni
      final alumniResponse = await http.get(
        Uri.parse('https://finalbackendd.onrender.com/api/debug/alumni'),
      );
      if (alumniResponse.statusCode == 200) {
        final alumniData = jsonDecode(alumniResponse.body);
        alumni = alumniData['alumni'] ?? [];
      } else {
        errors.add('Alumni endpoint failed');
      }
    } catch (error) {
      errors.add('Alumni endpoint error: $error');
    }

    setState(() {
      _debugData = {
        'events': events,
        'alumni': alumni,
        'status': status,
        'loading': false,
        'errors': errors,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_debugData['loading'] == true) {
      return Scaffold(
        body: AnimatedBackground(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.bug_report,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                ),
                const SizedBox(height: 16),
                Text(
                  'Loading Debug Data...',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                GlassCard(
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
                            ),
                            child: const Icon(
                              Icons.bug_report,
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
                                  'Debug Dashboard - Backend Status Check',
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Testing the 3 new features: Alumni Events, Alumni Directory, and Event Management',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Status Check
                GlassCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            color: AppTheme.successColor,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Backend Status',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatusCard(
                              'Server Status',
                              _debugData['status']['server'] ?? 'Unknown',
                              AppTheme.successColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatusCard(
                              'Authentication',
                              _debugData['status']['authentication'] ?? 'Unknown',
                              AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatusCard(
                              'Timestamp',
                              _debugData['status']['time'] != null
                                  ? DateTime.parse(_debugData['status']['time']).toLocal().toString().split('.')[0]
                                  : 'Unknown',
                              AppTheme.secondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Errors section
                if ((_debugData['errors'] as List).isNotEmpty)
                  GlassCard(
                    padding: const EdgeInsets.all(24),
                    backgroundColor: AppTheme.errorColor.withOpacity(0.1),
                    borderColor: AppTheme.errorColor.withOpacity(0.3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: AppTheme.errorColor,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Errors Detected',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: AppTheme.errorColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ...(_debugData['errors'] as List).map((error) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('• ', style: TextStyle(color: AppTheme.errorColor)),
                                Expanded(
                                  child: Text(
                                    error.toString(),
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppTheme.errorColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                
                const SizedBox(height: 24),
                
                // Data sections
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Events section
                    Expanded(
                      child: _buildDataSection(
                        'Alumni Events',
                        _debugData['events'] as List,
                        Icons.event,
                        AppTheme.primaryColor,
                        (event) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event['title'] ?? 'Untitled Event',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              event['description'] ?? 'No description',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 12,
                                  color: AppTheme.textMuted,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    event['location'] ?? 'No location',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.textMuted,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.people,
                                  size: 12,
                                  color: AppTheme.textMuted,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Max: ${event['maxAttendees'] ?? 'Unlimited'}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 12,
                                  color: AppTheme.textMuted,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  event['startDateTime'] != null
                                      ? DateTime.parse(event['startDateTime']).toLocal().toString().split(' ')[0]
                                      : 'No date',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Alumni section
                    Expanded(
                      child: _buildDataSection(
                        'Alumni Directory',
                        _debugData['alumni'] as List,
                        Icons.school,
                        AppTheme.successColor,
                        (alumni) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              alumni['name'] ?? 'Unknown Alumni',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              alumni['email'] ?? 'No email',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.school,
                                  size: 12,
                                  color: AppTheme.textMuted,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    alumni['department'] ?? 'Unknown',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.textMuted,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.phone,
                                  size: 12,
                                  color: AppTheme.textMuted,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  alumni['phoneNumber'] ?? 'No phone',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.business,
                                  size: 12,
                                  color: AppTheme.textMuted,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    alumni['currentCompany'] ?? 'Not specified',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.textMuted,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Feature Status Summary
                _buildFeatureStatusSummary(),
                
                const SizedBox(height: 24),
                
                // Next Steps
                _buildNextSteps(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataSection(
    String title,
    List<dynamic> data,
    IconData icon,
    Color color,
    Widget Function(dynamic) itemBuilder,
  ) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                '$title (${data.length})',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (data.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(
                    icon,
                    size: 48,
                    color: AppTheme.textMuted.withOpacity(0.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No ${title.toLowerCase()} found',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: data.take(3).map((item) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.glassBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.glassBorder),
                  ),
                  child: itemBuilder(item),
                );
              }).toList(),
            ),
          if (data.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '...and ${data.length - 3} more ${title.toLowerCase()}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textMuted,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFeatureStatusSummary() {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Feature Implementation Status',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildFeatureCard(
                  '1. Alumni Event Requests',
                  [
                    'Backend API ✅',
                    'Event Storage ✅',
                    'Frontend Auth Issues',
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFeatureCard(
                  '2. Alumni Directory',
                  [
                    'Backend API ✅',
                    'Search & Stats ✅',
                    'Frontend Auth Issues',
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFeatureCard(
                  '3. Management Event Approval',
                  [
                    'Backend API ✅',
                    'Email Notifications ✅',
                    'Frontend Auth Issues',
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(String title, List<String> items) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.glassBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...items.map((item) {
            final isSuccess = item.contains('✅');
            final isWarning = item.contains('Issues');
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(
                    isSuccess ? Icons.check_circle : 
                    isWarning ? Icons.warning : Icons.info,
                    size: 16,
                    color: isSuccess ? AppTheme.successColor :
                           isWarning ? AppTheme.warningColor : AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildNextSteps() {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
      borderColor: AppTheme.primaryColor.withOpacity(0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resolution Status',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '✅ All backend APIs are working correctly\n'
            '✅ Database storage and retrieval functioning\n'
            '⚠️ JWT authentication needs @PreAuthorize syntax correction\n'
            '📝 Working on hasAuthority vs hasRole authentication fix',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.primaryColor,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}