import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../common/providers/toast_provider.dart';
import '../common/widgets/glass_card.dart';
import '../common/widgets/gradient_button.dart';
import '../common/widgets/loading_widget.dart';
import '../common/widgets/professional_input.dart';
import '../services/assessment_service.dart';
import '../services/activity_service.dart';

class AIAssessmentComponent extends ConsumerStatefulWidget {
  const AIAssessmentComponent({super.key});

  @override
  ConsumerState<AIAssessmentComponent> createState() => _AIAssessmentComponentState();
}

class _AIAssessmentComponentState extends ConsumerState<AIAssessmentComponent> {
  final AssessmentService _assessmentService = AssessmentService();
  final ActivityService _activityService = ActivityService();
  
  Map<String, dynamic>? _assessment;
  bool _loading = false;
  int _currentQuestion = 0;
  List<int> _answers = [];
  bool _isActive = false;
  int _timeLeft = 0;
  bool _showResults = false;
  Map<String, dynamic>? _results;

  final Map<String, dynamic> _assessmentConfig = {
    'domain': '',
    'difficulty': '',
    'numberOfQuestions': 5,
  };

  final List<String> _domains = [
    'Computer Science',
    'Mathematics',
    'Physics',
    'Chemistry',
    'Biology',
    'English',
    'History',
    'Geography',
  ];

  final List<String> _difficulties = ['Easy', 'Medium', 'Hard'];

  Future<void> _generateAssessment() async {
    if (_assessmentConfig['domain'].isEmpty || _assessmentConfig['difficulty'].isEmpty) {
      ref.read(toastProvider.notifier).showToast(
        'Please select domain and difficulty',
        ToastType.error,
      );
      return;
    }

    setState(() => _loading = true);
    
    try {
      final response = await _assessmentService.generateAIAssessment(_assessmentConfig);
      
      setState(() {
        _assessment = response;
        _answers = List.filled(response['questions'].length, -1);
        _currentQuestion = 0;
        _showResults = false;
        _results = null;
      });

      // Log activity
      try {
        await _activityService.logActivity('AI_ASSESSMENT', 'Generated AI assessment');
      } catch (e) {
        print('Failed to log activity: $e');
      }

      ref.read(toastProvider.notifier).showToast(
        'Assessment generated successfully!',
        ToastType.success,
      );
    } catch (error) {
      ref.read(toastProvider.notifier).showToast(
        error.toString().replaceFirst('Exception: ', ''),
        ToastType.error,
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  void _startAssessment() {
    if (_assessment == null) return;
    
    setState(() {
      _isActive = true;
      _timeLeft = (_assessment!['duration'] ?? 60) * 60; // Convert minutes to seconds
    });
    
    // Start timer
    _startTimer();
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
    if (_assessment == null) return;

    setState(() => _isActive = false);
    
    // Calculate results
    final questions = _assessment!['questions'] as List;
    int score = 0;
    final feedback = <Map<String, dynamic>>[];

    for (int i = 0; i < _answers.length; i++) {
      final question = questions[i];
      final isCorrect = _answers[i] == question['correctAnswer'];
      if (isCorrect) score++;

      feedback.add({
        'questionIndex': i,
        'question': question['question'],
        'selectedOption': _answers[i] >= 0 ? question['options'][_answers[i]] : 'Not answered',
        'correctOption': question['options'][question['correctAnswer']],
        'explanation': question['explanation'],
        'isCorrect': isCorrect,
      });
    }

    final percentage = (score / questions.length) * 100;

    setState(() {
      _results = {
        'score': score,
        'totalMarks': questions.length,
        'percentage': percentage,
        'feedback': feedback,
      };
      _showResults = true;
    });

    // Log activity
    try {
      await _activityService.logActivity(
        'AI_ASSESSMENT',
        'Completed AI assessment - Score: $score/${questions.length}',
      );
    } catch (e) {
      print('Failed to log activity: $e');
    }
    
    ref.read(toastProvider.notifier).showToast(
      'Assessment completed! Score: $score/${questions.length}',
      ToastType.success,
    );
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_showResults && _results != null) {
      return _buildResultsView();
    }

    if (_assessment != null && _isActive) {
      return _buildActiveAssessment();
    }

    return _buildConfigurationView();
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
                Text(
                  'Assessment Results',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Stats grid
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Correct',
                        results['score'].toString(),
                        AppTheme.successColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        'Total',
                        results['totalMarks'].toString(),
                        AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        'Percentage',
                        '${results['percentage'].toStringAsFixed(1)}%',
                        AppTheme.secondaryColor,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Feedback section
                Text(
                  'Detailed Feedback',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                ...feedback.map((item) => _buildFeedbackItem(item)).toList(),
                
                const SizedBox(height: 32),
                
                GradientButton(
                  onPressed: () {
                    setState(() {
                      _assessment = null;
                      _showResults = false;
                      _results = null;
                    });
                  },
                  child: const Text('Take Another Assessment'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveAssessment() {
    final questions = _assessment!['questions'] as List;
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
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: isSelected 
                                        ? AppTheme.primaryColor 
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: isSelected 
                                          ? AppTheme.primaryColor 
                                          : AppTheme.textMuted,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: isSelected
                                      ? const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 16,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 12),
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
                        onPressed: _submitAssessment,
                        child: const Text('Submit Assessment'),
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

  Widget _buildConfigurationView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          GlassCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.psychology,
                      color: AppTheme.primaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'AI Assessment Generator',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Domain selection
                Text(
                  'Domain',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _assessmentConfig['domain'].isEmpty ? null : _assessmentConfig['domain'],
                  decoration: const InputDecoration(
                    hintText: 'Select Domain',
                  ),
                  dropdownColor: AppTheme.darkSurface,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  items: _domains.map((domain) {
                    return DropdownMenuItem(
                      value: domain,
                      child: Text(
                        domain,
                        style: const TextStyle(color: AppTheme.textPrimary),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _assessmentConfig['domain'] = value ?? '';
                    });
                  },
                ),
                
                const SizedBox(height: 20),
                
                // Difficulty selection
                Text(
                  'Difficulty',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _assessmentConfig['difficulty'].isEmpty ? null : _assessmentConfig['difficulty'],
                  decoration: const InputDecoration(
                    hintText: 'Select Difficulty',
                  ),
                  dropdownColor: AppTheme.darkSurface,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  items: _difficulties.map((difficulty) {
                    return DropdownMenuItem(
                      value: difficulty,
                      child: Text(
                        difficulty,
                        style: const TextStyle(color: AppTheme.textPrimary),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _assessmentConfig['difficulty'] = value ?? '';
                    });
                  },
                ),
                
                const SizedBox(height: 20),
                
                // Number of questions
                Text(
                  'Number of Questions',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: _assessmentConfig['numberOfQuestions'],
                  decoration: const InputDecoration(
                    hintText: 'Select Number of Questions',
                  ),
                  dropdownColor: AppTheme.darkSurface,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  items: [5, 10, 15, 20].map((count) {
                    return DropdownMenuItem(
                      value: count,
                      child: Text(
                        '$count Questions',
                        style: const TextStyle(color: AppTheme.textPrimary),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _assessmentConfig['numberOfQuestions'] = value ?? 5;
                    });
                  },
                ),
                
                const SizedBox(height: 32),
                
                GradientButton(
                  onPressed: _loading ? null : _generateAssessment,
                  isLoading: _loading,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.psychology, size: 20),
                      const SizedBox(width: 8),
                      Text(_loading ? 'Generating...' : 'Generate Assessment'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Generated assessment preview
          if (_assessment != null && !_isActive) ...[
            const SizedBox(height: 16),
            GlassCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _assessment!['title'] ?? 'AI Assessment',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                        ),
                        child: Text(
                          _assessmentConfig['difficulty'],
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Text(
                    _assessment!['description'] ?? 'AI generated assessment',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Assessment stats
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          'Questions',
                          (_assessment!['questions'] as List).length.toString(),
                          Icons.quiz,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoCard(
                          'Duration',
                          '${_assessment!['duration'] ?? 60} min',
                          Icons.timer,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoCard(
                          'Total Marks',
                          (_assessment!['totalMarks'] ?? (_assessment!['questions'] as List).length).toString(),
                          Icons.grade,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  GradientButton(
                    onPressed: _startAssessment,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.play_arrow, size: 20),
                        const SizedBox(width: 8),
                        const Text('Start Assessment'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
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
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.glassBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.glassBorder),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 12,
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