import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../auth/providers/auth_provider.dart';
import '../common/providers/toast_provider.dart';
import '../common/widgets/glass_card.dart';
import '../common/widgets/loading_widget.dart';
import '../services/activity_service.dart';

class ActivityHeatmapComponent extends ConsumerStatefulWidget {
  final String? userId;
  final String? userName;
  final bool showTitle;
  
  const ActivityHeatmapComponent({
    super.key,
    this.userId,
    this.userName,
    this.showTitle = true,
  });

  @override
  ConsumerState<ActivityHeatmapComponent> createState() => _ActivityHeatmapComponentState();
}

class _ActivityHeatmapComponentState extends ConsumerState<ActivityHeatmapComponent> {
  final ActivityService _activityService = ActivityService();
  
  Map<String, dynamic>? _heatmapData;
  bool _loading = true;
  String? _hoveredDate;

  @override
  void initState() {
    super.initState();
    _loadHeatmapData();
  }

  Future<void> _loadHeatmapData() async {
    final user = ref.read(authProvider).user;
    final targetUserId = widget.userId ?? user?.id;
    
    if (targetUserId == null) return;
    
    try {
      final response = await _activityService.getHeatmapData(targetUserId);
      setState(() {
        _heatmapData = response;
        _loading = false;
      });
    } catch (error) {
      setState(() => _loading = false);
      ref.read(toastProvider.notifier).showToast(
        'Failed to load activity data',
        ToastType.error,
      );
    }
  }

  List<List<String?>> _generateCalendarGrid() {
    final weeks = <List<String?>>[];
    final today = DateTime.now();
    final startDate = DateTime(today.year, today.month, today.day).subtract(const Duration(days: 364));
    
    // Start from Sunday of the week containing startDate
    final startDay = startDate.weekday % 7;
    final adjustedStartDate = startDate.subtract(Duration(days: startDay));
    
    for (int week = 0; week < 53; week++) {
      final weekDays = <String?>[];
      for (int day = 0; day < 7; day++) {
        final currentDate = adjustedStartDate.add(Duration(days: (week * 7) + day));
        
        if (currentDate.isBefore(today.add(const Duration(days: 1)))) {
          weekDays.add(currentDate.toIso8601String().split('T')[0]);
        } else {
          weekDays.add(null);
        }
      }
      weeks.add(weekDays);
    }
    
    return weeks;
  }

  Color _getIntensityColor(int count) {
    if (count == 0) return Colors.grey.shade200;
    if (count <= 2) return Colors.green.shade200;
    if (count <= 4) return Colors.green.shade400;
    if (count <= 6) return Colors.green.shade600;
    return Colors.green.shade800;
  }

  Map<String, dynamic>? _getActivityBreakdown(String date) {
    if (_heatmapData == null || _heatmapData!['heatmap'][date] == null) return null;
    
    final activities = _heatmapData!['heatmap'][date] as Map<String, dynamic>;
    final total = _heatmapData!['dailyTotals'][date] ?? 0;
    
    return {
      'total': total,
      'breakdown': activities.entries.map((entry) => {
        'name': entry.key.replaceAll('_', ' ').toLowerCase().split(' ').map((word) => 
          word.isEmpty ? word : word[0].toUpperCase() + word.substring(1)).join(' '),
        'count': entry.value,
      }).toList(),
    };
  }

  String _getActivityIcon(String activityName) {
    final name = activityName.toLowerCase();
    if (name.contains('assessment')) return '📝';
    if (name.contains('chat')) return '💬';
    if (name.contains('task')) return '✅';
    if (name.contains('login')) return '🔐';
    if (name.contains('event')) return '📅';
    return '📊';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: LoadingWidget(message: 'Loading activity data...'),
      );
    }

    if (_heatmapData == null) {
      return GlassCard(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.analytics,
              size: 64,
              color: AppTheme.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              'No Activity Data Available',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    final totalActivities = (_heatmapData!['dailyTotals'] as Map<String, dynamic>)
        .values
        .fold<int>(0, (sum, value) => sum + (value as int));
    final activeDays = (_heatmapData!['dailyTotals'] as Map<String, dynamic>)
        .entries
        .where((entry) => entry.value > 0)
        .length;
    final maxDaily = (_heatmapData!['dailyTotals'] as Map<String, dynamic>)
        .values
        .fold<int>(0, (max, value) => value > max ? value : max);
    final avgDaily = totalActivities / 365;

    return Column(
      children: [
        if (widget.showTitle) ...[
          Row(
            children: [
              const Icon(
                Icons.analytics,
                color: AppTheme.successColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Activity Heatmap',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (widget.userName != null) ...[
                const Text(
                  ' - ',
                  style: TextStyle(color: AppTheme.textMuted),
                ),
                Text(
                  widget.userName!,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Daily activity over the past year',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        // Statistics
        Row(
          children: [
            Expanded(
              child: _buildStatCard('Total Activities', totalActivities.toString(), AppTheme.primaryColor),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard('Active Days', activeDays.toString(), AppTheme.successColor),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard('Max Daily', maxDaily.toString(), AppTheme.secondaryColor),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard('Daily Average', avgDaily.toStringAsFixed(1), AppTheme.warningColor),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Heatmap
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$totalActivities activities in the last year',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  Row(
                    children: [
                      const Text(
                        'Less',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Row(
                        children: [
                          Container(width: 10, height: 10, color: Colors.grey.shade200),
                          const SizedBox(width: 2),
                          Container(width: 10, height: 10, color: Colors.green.shade200),
                          const SizedBox(width: 2),
                          Container(width: 10, height: 10, color: Colors.green.shade400),
                          const SizedBox(width: 2),
                          Container(width: 10, height: 10, color: Colors.green.shade600),
                          const SizedBox(width: 2),
                          Container(width: 10, height: 10, color: Colors.green.shade800),
                        ],
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'More',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Calendar grid
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Column(
                  children: [
                    // Month labels
                    SizedBox(
                      height: 20,
                      child: Row(
                        children: _generateCalendarGrid().asMap().entries.map((entry) {
                          final weekIndex = entry.key;
                          final week = entry.value;
                          final firstDay = week.firstWhere((day) => day != null, orElse: () => null);
                          
                          if (firstDay == null) {
                            return const SizedBox(width: 12);
                          }
                          
                          final date = DateTime.parse(firstDay);
                          final isFirstWeekOfMonth = date.day <= 7;
                          
                          return SizedBox(
                            width: 12,
                            child: isFirstWeekOfMonth
                                ? Text(
                                    ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                                     'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][date.month - 1],
                                    style: const TextStyle(
                                      color: AppTheme.textMuted,
                                      fontSize: 9,
                                    ),
                                  )
                                : null,
                          );
                        }).toList(),
                      ),
                    ),
                    
                    // Day labels and heatmap
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Day labels
                        Column(
                          children: [
                            const SizedBox(height: 12),
                            ...['Mon', 'Wed', 'Fri'].map((day) {
                              return SizedBox(
                                height: 12,
                                child: Text(
                                  day,
                                  style: const TextStyle(
                                    color: AppTheme.textMuted,
                                    fontSize: 9,
                                  ),
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                        
                        const SizedBox(width: 8),
                        
                        // Heatmap grid
                        Row(
                          children: _generateCalendarGrid().map((week) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 2),
                              child: Column(
                                children: week.map((date) {
                                  if (date == null) {
                                    return const SizedBox(width: 10, height: 10);
                                  }
                                  
                                  final count = _heatmapData!['dailyTotals'][date] ?? 0;
                                  
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _hoveredDate = _hoveredDate == date ? null : date;
                                      });
                                    },
                                    child: Container(
                                      width: 10,
                                      height: 10,
                                      margin: const EdgeInsets.only(bottom: 2),
                                      decoration: BoxDecoration(
                                        color: _getIntensityColor(count),
                                        borderRadius: BorderRadius.circular(2),
                                        border: _hoveredDate == date
                                            ? Border.all(color: AppTheme.primaryColor, width: 1)
                                            : null,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Tooltip
              if (_hoveredDate != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.darkSurface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.glassBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateTime.parse(_hoveredDate!).toLocal().toString().split(' ')[0],
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Builder(
                        builder: (context) {
                          final breakdown = _getActivityBreakdown(_hoveredDate!);
                          if (breakdown == null || breakdown['total'] == 0) {
                            return const Text(
                              'No activities',
                              style: TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 10,
                              ),
                            );
                          }
                          
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${breakdown['total']} ${breakdown['total'] == 1 ? 'activity' : 'activities'}',
                                style: const TextStyle(
                                  color: AppTheme.successColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                ),
                              ),
                              const SizedBox(height: 4),
                              ...(breakdown['breakdown'] as List).map((activity) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 2),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _getActivityIcon(activity['name']),
                                        style: const TextStyle(fontSize: 8),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        activity['name'],
                                        style: const TextStyle(
                                          color: AppTheme.textMuted,
                                          fontSize: 9,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        activity['count'].toString(),
                                        style: const TextStyle(
                                          color: AppTheme.textPrimary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 9,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 9,
              color: AppTheme.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}