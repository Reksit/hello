import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/app_theme.dart';
import '../common/providers/toast_provider.dart';
import '../common/widgets/glass_card.dart';
import '../common/widgets/gradient_button.dart';
import '../common/widgets/loading_widget.dart';
import '../services/activity_service.dart';
import '../services/assessment_service.dart';

class ClassAssessmentsComponent extends ConsumerStatefulWidget {
  const ClassAssessmentsComponent({super.key});

  @override
  ConsumerState<ClassAssessmentsComponent> createState() => _ClassAssessmentsComponentState();
}

class _ClassAssessmentsComponentState extends ConsumerState<ClassAssessmentsComponent> {
  final AssessmentService _assessmentService = AssessmentService();
  final ActivityService _activityService = ActivityService();
  
  List<dynamic> _assessments = [];
  Map<String, dynamic>? _activeAssessment;
  int _currentQuestion = 0;
  List<int> _answers = [];
  int _timeLeft = 0;
  bool _isActive = false;
  String _startedAt = '';
  bool _showResults = false;
  Map<String, dynamic>? _results;
  bool _loading = true;
  bool _isSubmitting = false;
  Set<String> _submittedAssessments = {};

  @override
  void initState() {
    super.initState();
    _loadAssessments();
    _loadSubmissionStatus();
  }

  void _loadSubmissionStatus() {
    final submitted = StorageService.getSubmittedAssessments();
    setState(() {
      _submittedAssessments = submitted;
    });
  }

  void _saveSubmissionStatus(String assessmentId) {
    StorageService.saveSubmittedAssessment(assessmentId);
    setState(() {
      _submittedAssessments.add(assessmentId);
    });
  }

  Future<void> _loadAssessments() async {
    try {
      final response = await _assessmentService.getStudentAssessments();
      setState(() {
        _assessments = response;
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

  void _startAssessment(Map<String, dynamic> assessment) {
    final now = DateTime.now();
    final startTime = DateTime.parse(assessment['startTime']);
    final endTime = DateTime.parse(assessment['endTime']);

    if (now.isBefore(startTime)) {
      ref.read(toastProvider.notifier).showToast(
        'Assessment has not started yet',
        ToastType.warning,
      );
      return;
    }

    if (now.isAfter(endTime)) {
      ref.read(toastProvider.notifier).showToast(
        'Assessment has ended',
        ToastType.error,
      );
      return;
    }

    if (_submittedAssessments.contains(assessment['id'])) {
      ref.read(toastProvider.notifier).showToast(
        'You have already submitted this assessment',
        ToastType.warning,
      );
      return;
    }

    setState(() {
      _activeAssessment = assessment;
      _answers = List.filled(assessment['questions'].length, -1);
      _currentQuestion = 0;
      _timeLeft = (assessment['duration'] ?? 60) * 60;
      _isActive = true;
      _startedAt = now.toIso8601String();
      _showResults = false;
      _results = null;
    });

    _startTimer();
    
    ref.read(toastProvider.notifier).showToast(
      'Assessment started! Good luck!',
      ToastType.info,
    );
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (_isActive && _timeLeft > 0) {
        setState(() => _timeLeft--);
        _startTimer();
      } else if (_timeLeft <= 0) {
        _submitAssessment();
      }
    });
  }

  Future<void> _submitAssessment() async {
    if (_activeAssessment == null || _isSubmitting) return;

    setState(() {
      _isActive = false;
      _isSubmitting = true;
    });

    try {
      final submission = {
        'answers': _answers.asMap().entries.map((entry) => {
          'questionIndex': entry.key,
          'selectedAnswer': entry.value,
        }).toList(),
        'startedAt': _startedAt,
      };

      final result = await _assessmentService.submitAssessment(
        _activeAssessment!['id'],
        submission,
      );

      if (result != null) {
        setState(() {
          _results = result;
          _showResults = true;
        });
        
        _saveSubmissionStatus(_activeAssessment!['id']);
        
        // Log activity
        try {
          await _activityService.logActivity(
            'ASSESSMENT_COMPLETED',
            'Completed assessment: ${_activeAssessment!['title']}',
          );
        } catch (e) {
          print('Failed to log activity: $e');
        }
        
        ref.read(toastProvider.notifier).showToast(
          'Assessment submitted successfully!',
          ToastType.success,
        );
        
        setState(() {
          _activeAssessment = null;
          _isActive = false;
        });
      }
    } catch (error) {
      ref.read(toastProvider.notifier).showToast(
        error.toString().replaceFirst('Exception: ', ''),
        ToastType.error,
      );
      setState(() => _isActive = true);
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  bool _isAssessmentActive(Map<String, dynamic> assessment) {
    final now = DateTime.now();
    final startTime = DateTime.parse(assessment['startTime']);
    final endTime = DateTime.parse(assessment['endTime']);
    return now.isAfter(startTime) && now.isBefore(endTime);
  }

  String _getAssessmentStatus(Map<String, dynamic> assessment) {
    if (_submittedAssessments.contains(assessment['id'])) {
      return 'completed';
    }

    final now = DateTime.now();
    final startTime = DateTime.parse(assessment['startTime']);
    final endTime = DateTime.parse(assessment['endTime']);

    if (now.isAfter(endTime)) {
      return 'missed';
    }
    if (now.isBefore(startTime)) return 'upcoming';
    return 'active';
  }

  @override
  Widget build(BuildContext context) {
    if (_showResults && _results != null) {
      return _buildResultsView();
    }

    if (_activeAssessment != null && _isActive) {
      return _buildActiveAssessmentView();
    }

    return _buildAssessmentsList();
  }

  Widget _buildResultsView() {
    final results = _results!;
    final feedback = results['feedback'] as List;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          GlassCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppTheme.successColor,
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  'Assessment Completed!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  'Here\'s your performance summary',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Results grid
                Row(
                  children: [
                    Expanded(
                      child: _buildResultCard(
                        'Correct',
                        results['score'].toString(),
                        AppTheme.successColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildResultCard(
                        'Wrong',
                        (results['totalMarks'] - results['score']).toString(),
                        AppTheme.errorColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildResultCard(
                        'Total',
                        results['totalMarks'].toString(),
                        AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildResultCard(
                        'Percentage',
                        '${results['percentage'].toStringAsFixed(1)}%',
                        AppTheme.secondaryColor,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                GradientButton(
                  onPressed: () {
                    setState(() {
                      _showResults = false;
                      _results = null;
                      _activeAssessment = null;
                    });
                    _loadAssessments();
                  },
                  child: const Text('Return to Dashboard'),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Detailed feedback
          GlassCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Detailed Feedback',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                ...feedback.map((item) => _buildFeedbackItem(item)).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveAssessmentView() {
    final questions = _activeAssessment!['questions'] as List;
    final currentQ = questions[_currentQuestion];
    
    return Column(
      children: [
        // Timer and progress
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.timer, color: AppTheme.errorColor),
                      const SizedBox(width: 8),
                      Text(
                        'Time Left: ${_formatTime(_timeLeft)}',
                        style: const TextStyle(
                          color: AppTheme.errorColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Question ${_currentQuestion + 1} of ${questions.length}',
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: (_currentQuestion + 1) / questions.length,
                backgroundColor: AppTheme.glassBorder,
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Question
        Expanded(
          child: GlassCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentQ['question'],
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                Expanded(
                  child: ListView.builder(
                    itemCount: currentQ['options'].length,
                    itemBuilder: (context, index) {
                      final option = currentQ['options'][index];
                      final isSelected = _answers[_currentQuestion] == index;
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _answers[_currentQuestion] = index;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? AppTheme.primaryColor.withOpacity(0.2)
                                  : AppTheme.glassBackground,
                              border: Border.all(
                                color: isSelected 
                                    ? AppTheme.primaryColor 
                                    : AppTheme.glassBorder,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  String.fromCharCode(65 + index),
                                  style: TextStyle(
                                    color: isSelected 
                                        ? AppTheme.primaryColor 
                                        : AppTheme.textMuted,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    option,
                                    style: TextStyle(
                                      color: isSelected 
                                          ? AppTheme.textPrimary 
                                          : AppTheme.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Navigation buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_currentQuestion > 0)
                      GradientButton(
                        onPressed: () {
                          setState(() {
                            _currentQuestion = _currentQuestion - 1;
                          });
                        },
                        child: const Text('Previous'),
                      )
                    else
                      const SizedBox(),
                    
                    if (_currentQuestion == questions.length - 1)
                      GradientButton(
                        onPressed: _isSubmitting ? null : _submitAssessment,
                        isLoading: _isSubmitting,
                        child: Text(_isSubmitting ? 'Submitting...' : 'Submit Assessment'),
                      )
                    else
                      GradientButton(
                        onPressed: () {
                          setState(() {
                            _currentQuestion = _currentQuestion + 1;
                          });
                        },
                        child: const Text('Next'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAssessmentsList() {
    if (_loading) {
      return const Center(
        child: LoadingWidget(message: 'Loading assessments...'),
      );
    }

    if (_assessments.isEmpty) {
      return GlassCard(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.quiz,
              size: 64,
              color: AppTheme.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              'No Assessments Available',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No assessments found for your courses.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _assessments.length,
      itemBuilder: (context, index) {
        final assessment = _assessments[index];
        return _buildAssessmentCard(assessment);
      },
    );
  }

  Widget _buildAssessmentCard(Map<String, dynamic> assessment) {
    final status = _getAssessmentStatus(assessment);
    final isActiveNow = _isAssessmentActive(assessment);
    final isSubmitted = _submittedAssessments.contains(assessment['id']);
    
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
                  child: Text(
                    assessment['title'] ?? 'Assessment',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildStatusChip(status),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Text(
              assessment['description'] ?? 'No description',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Assessment details
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildDetailChip(
                  Icons.calendar_today,
                  'Start: ${DateTime.parse(assessment['startTime']).toLocal().toString().split('.')[0]}',
                ),
                _buildDetailChip(
                  Icons.schedule,
                  'End: ${DateTime.parse(assessment['endTime']).toLocal().toString().split('.')[0]}',
                ),
                _buildDetailChip(
                  Icons.timer,
                  'Duration: ${assessment['duration'] ?? 60} min',
                ),
                _buildDetailChip(
                  Icons.quiz,
                  'Questions: ${assessment['questions']?.length ?? 0}',
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Action button
            if (isActiveNow && !isSubmitted && status != 'completed')
              GradientButton(
                onPressed: () => _startAssessment(assessment),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.play_arrow, size: 20),
                    const SizedBox(width: 8),
                    const Text('Start Assessment'),
                  ],
                ),
              )
            else if (status == 'completed' || isSubmitted)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.successColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: AppTheme.successColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Assessment Submitted Successfully',
                      style: TextStyle(
                        color: AppTheme.successColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
            else if (status == 'upcoming')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.warningColor.withOpacity(0.3)),
                ),
                child: const Text(
                  'Assessment will be available at the scheduled time',
                  style: TextStyle(
                    color: AppTheme.warningColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else if (status == 'missed' && !isSubmitted)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.errorColor.withOpacity(0.3)),
                ),
                child: const Text(
                  'Assessment Deadline Passed',
                  style: TextStyle(
                    color: AppTheme.errorColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String text;
    
    switch (status) {
      case 'completed':
        color = AppTheme.successColor;
        text = 'Submitted';
        break;
      case 'missed':
        color = AppTheme.errorColor;
        text = 'Ended';
        break;
      case 'upcoming':
        color = AppTheme.warningColor;
        text = 'Upcoming';
        break;
      case 'active':
        color = AppTheme.successColor;
        text = 'Active';
        break;
      default:
        color = AppTheme.textMuted;
        text = 'Unknown';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppTheme.textMuted, size: 16),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackItem(Map<String, dynamic> item) {
    final isCorrect = item['isCorrect'] as bool;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.glassBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCorrect ? AppTheme.successColor.withOpacity(0.3) : AppTheme.errorColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCorrect ? Icons.check_circle : Icons.cancel,
                color: isCorrect ? AppTheme.successColor : AppTheme.errorColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Question ${item['questionIndex'] + 1}',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Text(
            item['question'],
            style: const TextStyle(
              color: AppTheme.textSecondary,
            ),
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Answer:',
                      style: TextStyle(
                        color: AppTheme.errorColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      item['selectedOption'],
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Correct Answer:',
                      style: TextStyle(
                        color: AppTheme.successColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      item['correctOption'],
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Explanation:',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item['explanation'],
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}