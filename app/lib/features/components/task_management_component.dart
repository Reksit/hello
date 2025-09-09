import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../common/providers/toast_provider.dart';
import '../common/widgets/glass_card.dart';
import '../common/widgets/gradient_button.dart';
import '../common/widgets/loading_widget.dart';
import '../common/widgets/professional_input.dart';
import '../services/activity_service.dart';
import '../services/task_service.dart';

class TaskManagementComponent extends ConsumerStatefulWidget {
  const TaskManagementComponent({super.key});

  @override
  ConsumerState<TaskManagementComponent> createState() => _TaskManagementComponentState();
}

class _TaskManagementComponentState extends ConsumerState<TaskManagementComponent> {
  final TaskService _taskService = TaskService();
  final ActivityService _activityService = ActivityService();
  
  List<dynamic> _tasks = [];
  bool _loading = true;
  bool _showCreateForm = false;
  Set<String> _expandedTasks = {};
  String? _generatingRoadmap;
  
  final _taskNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dueDateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  @override
  void dispose() {
    _taskNameController.dispose();
    _descriptionController.dispose();
    _dueDateController.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    try {
      final response = await _taskService.getUserTasks();
      setState(() {
        _tasks = response;
        _loading = false;
      });
    } catch (error) {
      setState(() => _loading = false);
      if (!error.toString().contains('404')) {
        ref.read(toastProvider.notifier).showToast(
          error.toString().replaceFirst('Exception: ', ''),
          ToastType.error,
        );
      }
    }
  }

  Future<void> _createTask() async {
    if (_taskNameController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty ||
        _dueDateController.text.trim().isEmpty) {
      ref.read(toastProvider.notifier).showToast(
        'Please fill in all fields',
        ToastType.error,
      );
      return;
    }

    try {
      final taskData = {
        'taskName': _taskNameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'dueDate': _dueDateController.text.trim(),
      };

      final response = await _taskService.createTask(taskData);
      
      setState(() {
        _tasks.insert(0, response);
        _showCreateForm = false;
      });
      
      _taskNameController.clear();
      _descriptionController.clear();
      _dueDateController.clear();
      
      // Log activity
      try {
        await _activityService.logActivity(
          'TASK_MANAGEMENT',
          'Created task: ${taskData['taskName']}',
        );
      } catch (e) {
        print('Failed to log activity: $e');
      }
      
      ref.read(toastProvider.notifier).showToast(
        'Task created successfully!',
        ToastType.success,
      );
    } catch (error) {
      ref.read(toastProvider.notifier).showToast(
        error.toString().replaceFirst('Exception: ', ''),
        ToastType.error,
      );
    }
  }

  Future<void> _generateRoadmap(String taskId) async {
    try {
      setState(() => _generatingRoadmap = taskId);
      
      ref.read(toastProvider.notifier).showToast(
        'Generating roadmap...',
        ToastType.info,
      );
      
      final response = await _taskService.generateRoadmap(taskId);
      
      setState(() {
        _tasks = _tasks.map((task) {
          if (task['id'] == taskId) {
            return response;
          }
          return task;
        }).toList();
        _expandedTasks.add(taskId);
      });
      
      // Log activity
      try {
        await _activityService.logActivity(
          'TASK_MANAGEMENT',
          'Generated AI roadmap for task',
        );
      } catch (e) {
        print('Failed to log activity: $e');
      }
      
      ref.read(toastProvider.notifier).showToast(
        'Roadmap generated successfully!',
        ToastType.success,
      );
    } catch (error) {
      ref.read(toastProvider.notifier).showToast(
        error.toString().replaceFirst('Exception: ', ''),
        ToastType.error,
      );
    } finally {
      setState(() => _generatingRoadmap = null);
    }
  }

  Future<void> _updateTaskStatus(String taskId, String status) async {
    try {
      final response = await _taskService.updateTaskStatus(taskId, status);
      
      setState(() {
        _tasks = _tasks.map((task) {
          if (task['id'] == taskId) {
            return response;
          }
          return task;
        }).toList();
      });
      
      ref.read(toastProvider.notifier).showToast(
        'Task status updated!',
        ToastType.success,
      );
    } catch (error) {
      ref.read(toastProvider.notifier).showToast(
        error.toString().replaceFirst('Exception: ', ''),
        ToastType.error,
      );
    }
  }

  void _toggleTaskExpansion(String taskId) {
    setState(() {
      if (_expandedTasks.contains(taskId)) {
        _expandedTasks.remove(taskId);
      } else {
        _expandedTasks.add(taskId);
      }
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING':
        return AppTheme.warningColor;
      case 'IN_PROGRESS':
        return AppTheme.primaryColor;
      case 'COMPLETED':
        return AppTheme.successColor;
      case 'OVERDUE':
        return AppTheme.errorColor;
      default:
        return AppTheme.textMuted;
    }
  }

  bool _isOverdue(String dueDate) {
    try {
      final due = DateTime.parse(dueDate);
      return due.isBefore(DateTime.now());
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: LoadingWidget(message: 'Loading tasks...'),
      );
    }

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.task_alt,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Task Management',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              GradientButton(
                onPressed: () {
                  setState(() => _showCreateForm = true);
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add, size: 20),
                    const SizedBox(width: 4),
                    const Text('Create Task'),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Create task form
        if (_showCreateForm) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create New Task',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  ProfessionalInput(
                    controller: _taskNameController,
                    label: 'Task Name',
                    hintText: 'Enter task name',
                  ),
                  
                  const SizedBox(height: 16),
                  
                  ProfessionalInput(
                    controller: _descriptionController,
                    label: 'Description',
                    hintText: 'Describe your task in detail',
                    maxLines: 3,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  ProfessionalInput(
                    controller: _dueDateController,
                    label: 'Due Date',
                    hintText: 'YYYY-MM-DD',
                    keyboardType: TextInputType.datetime,
                  ),
                  
                  const SizedBox(height: 20),
                  
                  Row(
                    children: [
                      Expanded(
                        child: GradientButton(
                          onPressed: _createTask,
                          child: const Text('Create Task'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GradientButton(
                          onPressed: () {
                            setState(() => _showCreateForm = false);
                            _taskNameController.clear();
                            _descriptionController.clear();
                            _dueDateController.clear();
                          },
                          child: const Text('Cancel'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        // Tasks list
        Expanded(
          child: _tasks.isEmpty
              ? GlassCard(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.task_alt,
                        size: 64,
                        color: AppTheme.textMuted,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Tasks Yet',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create your first task to get started with AI-powered roadmaps.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _tasks.length,
                  itemBuilder: (context, index) {
                    final task = _tasks[index];
                    return _buildTaskCard(task);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    final taskId = task['id'];
    final status = task['status'] ?? 'PENDING';
    final isExpanded = _expandedTasks.contains(taskId);
    final isOverdue = _isOverdue(task['dueDate'] ?? '');
    final roadmapGenerated = task['roadmapGenerated'] ?? false;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              task['taskName'] ?? 'Untitled Task',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(status).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _getStatusColor(status).withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              status.replaceAll('_', ' '),
                              style: TextStyle(
                                color: _getStatusColor(status),
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          if (isOverdue && status != 'COMPLETED') ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.errorColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppTheme.errorColor.withOpacity(0.3),
                                ),
                              ),
                              child: const Text(
                                'OVERDUE',
                                style: TextStyle(
                                  color: AppTheme.errorColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      
                      Text(
                        task['description'] ?? 'No description',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: AppTheme.textMuted,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Due: ${task['dueDate'] != null ? DateTime.parse(task['dueDate']).toLocal().toString().split(' ')[0] : 'No due date'}',
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.access_time,
                            color: AppTheme.textMuted,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Created: ${task['createdAt'] != null ? DateTime.parse(task['createdAt']).toLocal().toString().split(' ')[0] : 'Unknown'}',
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                Column(
                  children: [
                    if (!roadmapGenerated)
                      GradientButton(
                        onPressed: _generatingRoadmap == taskId ? null : () => _generateRoadmap(taskId),
                        isLoading: _generatingRoadmap == taskId,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.map, size: 16),
                            const SizedBox(width: 4),
                            Text(_generatingRoadmap == taskId ? 'Generating...' : 'Generate Roadmap'),
                          ],
                        ),
                      ),
                    
                    if (roadmapGenerated) ...[
                      GradientButton(
                        onPressed: () => _toggleTaskExpansion(taskId),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.map, size: 16),
                            const SizedBox(width: 4),
                            const Text('View Roadmap'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    
                    // Status dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.glassBackground,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.glassBorder),
                      ),
                      child: DropdownButton<String>(
                        value: status,
                        underline: const SizedBox(),
                        dropdownColor: AppTheme.darkSurface,
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                        items: ['PENDING', 'IN_PROGRESS', 'COMPLETED'].map((s) {
                          return DropdownMenuItem(
                            value: s,
                            child: Text(
                              s.replaceAll('_', ' '),
                              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                            ),
                          );
                        }).toList(),
                        onChanged: (newStatus) {
                          if (newStatus != null) {
                            _updateTaskStatus(taskId, newStatus);
                          }
                        },
                      ),
                    ),
                    
                    if (roadmapGenerated) ...[
                      const SizedBox(height: 8),
                      IconButton(
                        onPressed: () => _toggleTaskExpansion(taskId),
                        icon: Icon(
                          isExpanded ? Icons.expand_less : Icons.expand_more,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            
            // Roadmap
            if (roadmapGenerated && isExpanded) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.successColor.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.map,
                          color: AppTheme.successColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'AI Generated Roadmap',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppTheme.successColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    ...((task['roadmap'] as List?) ?? []).asMap().entries.map((entry) {
                      final index = entry.key;
                      final step = entry.value;
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                step.toString(),
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 14,
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
            ],
          ],
        ),
      ),
    );
  }
}