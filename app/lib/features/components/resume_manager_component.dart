import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/theme/app_theme.dart';
import '../common/providers/toast_provider.dart';
import '../common/widgets/glass_card.dart';
import '../common/widgets/gradient_button.dart';
import '../common/widgets/loading_widget.dart';
import '../services/resume_service.dart';

class ResumeManagerComponent extends ConsumerStatefulWidget {
  const ResumeManagerComponent({super.key});

  @override
  ConsumerState<ResumeManagerComponent> createState() => _ResumeManagerComponentState();
}

class _ResumeManagerComponentState extends ConsumerState<ResumeManagerComponent>
    with SingleTickerProviderStateMixin {
  final ResumeService _resumeService = ResumeService();
  
  List<dynamic> _resumes = [];
  Map<String, dynamic>? _currentResume;
  bool _uploading = false;
  bool _loading = true;
  String _activeTab = 'manage';
  Map<String, dynamic>? _selectedResumeForATS;
  bool _atsAnalyzing = false;
  bool _showATSResults = false;
  
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadResumes();
    _loadCurrentResume();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadResumes() async {
    try {
      final response = await _resumeService.getMyResumes();
      setState(() => _resumes = response);
    } catch (error) {
      ref.read(toastProvider.notifier).showToast(
        'Failed to load resumes',
        ToastType.error,
      );
    }
  }

  Future<void> _loadCurrentResume() async {
    try {
      final response = await _resumeService.getCurrentResume();
      setState(() {
        _currentResume = response;
        _loading = false;
      });
    } catch (error) {
      setState(() => _loading = false);
    }
  }

  Future<void> _uploadResume() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.first.path!);
        
        // Validate file size (10MB limit)
        final fileSize = await file.length();
        if (fileSize > 10 * 1024 * 1024) {
          ref.read(toastProvider.notifier).showToast(
            'File size must be less than 10MB',
            ToastType.error,
          );
          return;
        }

        setState(() => _uploading = true);
        
        try {
          await _resumeService.uploadResume(file);
          
          ref.read(toastProvider.notifier).showToast(
            'Resume uploaded successfully!',
            ToastType.success,
          );
          
          _loadResumes();
          _loadCurrentResume();
        } catch (error) {
          ref.read(toastProvider.notifier).showToast(
            error.toString().replaceFirst('Exception: ', ''),
            ToastType.error,
          );
        } finally {
          setState(() => _uploading = false);
        }
      }
    } catch (error) {
      ref.read(toastProvider.notifier).showToast(
        'Failed to pick file',
        ToastType.error,
      );
    }
  }

  Future<void> _activateResume(String resumeId) async {
    try {
      await _resumeService.activateResume(resumeId);
      ref.read(toastProvider.notifier).showToast(
        'Resume activated successfully!',
        ToastType.success,
      );
      _loadResumes();
      _loadCurrentResume();
    } catch (error) {
      ref.read(toastProvider.notifier).showToast(
        'Failed to activate resume',
        ToastType.error,
      );
    }
  }

  Future<void> _deleteResume(String resumeId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        title: const Text(
          'Delete Resume',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: const Text(
          'Are you sure you want to delete this resume?',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _resumeService.deleteResume(resumeId);
        ref.read(toastProvider.notifier).showToast(
          'Resume deleted successfully!',
          ToastType.success,
        );
        _loadResumes();
        _loadCurrentResume();
      } catch (error) {
        ref.read(toastProvider.notifier).showToast(
          'Failed to delete resume',
          ToastType.error,
        );
      }
    }
  }

  Future<void> _analyzeResumeWithATS(Map<String, dynamic> resume) async {
    setState(() {
      _selectedResumeForATS = resume;
      _atsAnalyzing = true;
    });
    
    try {
      final updatedResume = await _resumeService.analyzeResumeATS(resume['id']);
      
      setState(() {
        _selectedResumeForATS = updatedResume;
        _showATSResults = true;
      });
      
      ref.read(toastProvider.notifier).showToast(
        'ATS analysis completed!',
        ToastType.success,
      );
      
      _loadResumes();
    } catch (error) {
      ref.read(toastProvider.notifier).showToast(
        error.toString().replaceFirst('Exception: ', ''),
        ToastType.error,
      );
    } finally {
      setState(() => _atsAnalyzing = false);
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes == 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    final i = (bytes.bitLength - 1) ~/ 10;
    return '${(bytes / (1 << (i * 10))).toStringAsFixed(2)} ${sizes[i]}';
  }

  Color _getATSScoreColor(double score) {
    if (score >= 80) return AppTheme.successColor;
    if (score >= 60) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: LoadingWidget(message: 'Loading resumes...'),
      );
    }

    return Column(
      children: [
        // Header with tabs
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(
                Icons.description,
                color: AppTheme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Resume Manager',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_activeTab == 'manage')
                GradientButton(
                  onPressed: _uploading ? null : _uploadResume,
                  isLoading: _uploading,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.upload, size: 16),
                      const SizedBox(width: 4),
                      Text(_uploading ? 'Uploading...' : 'Upload'),
                    ],
                  ),
                ),
            ],
          ),
        ),
        
        // Tab bar
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppTheme.glassBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.glassBorder),
          ),
          child: TabBar(
            controller: _tabController,
            onTap: (index) {
              setState(() {
                _activeTab = index == 0 ? 'manage' : 'ats';
              });
            },
            indicator: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            labelColor: Colors.white,
            unselectedLabelColor: AppTheme.textMuted,
            tabs: const [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.folder, size: 16),
                    SizedBox(width: 8),
                    Text('Manage Resumes'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.analytics, size: 16),
                    SizedBox(width: 8),
                    Text('ATS Checker'),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Tab content
        Expanded(
          child: _activeTab == 'manage' ? _buildManageTab() : _buildATSTab(),
        ),
      ],
    );
  }

  Widget _buildManageTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Current resume
          if (_currentResume != null) ...[
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Active Resume',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.successColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.successColor.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: AppTheme.successColor,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'Active',
                                  style: TextStyle(
                                    color: AppTheme.successColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_currentResume!['atsScore'] != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getATSScoreColor(_currentResume!['atsScore'].toDouble()).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _getATSScoreColor(_currentResume!['atsScore'].toDouble()).withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                'ATS: ${_currentResume!['atsScore']}%',
                                style: TextStyle(
                                  color: _getATSScoreColor(_currentResume!['atsScore'].toDouble()),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      const Icon(
                        Icons.description,
                        color: AppTheme.primaryColor,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currentResume!['fileName'] ?? 'Unknown',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  'Uploaded ${DateTime.parse(_currentResume!['uploadedAt']).toLocal().toString().split(' ')[0]}',
                                  style: const TextStyle(
                                    color: AppTheme.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                                if (_currentResume!['fileSize'] != null) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    _formatFileSize(_currentResume!['fileSize']),
                                    style: const TextStyle(
                                      color: AppTheme.textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _downloadResume(_currentResume!),
                        icon: const Icon(
                          Icons.download,
                          color: AppTheme.successColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // All resumes
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'All Resumes (${_resumes.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                if (_resumes.isEmpty)
                  Column(
                    children: [
                      const Icon(
                        Icons.description,
                        size: 64,
                        color: AppTheme.textMuted,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Resumes Uploaded',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Upload your first resume to get started!',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  )
                else
                  ...(_resumes.map((resume) => _buildResumeItem(resume)).toList()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildATSTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // ATS Header
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppTheme.glowShadow,
                      ),
                      child: const Icon(
                        Icons.analytics,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI-Powered ATS Score Checker',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Get detailed feedback on your resume\'s ATS compatibility',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildFeatureItem(
                        Icons.check_circle,
                        'Comprehensive Analysis',
                      ),
                    ),
                    Expanded(
                      child: _buildFeatureItem(
                        Icons.psychology,
                        'AI-Powered Recommendations',
                      ),
                    ),
                    Expanded(
                      child: _buildFeatureItem(
                        Icons.send,
                        'Send to Management',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Resume selection
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Resume for ATS Analysis',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                if (_resumes.isEmpty)
                  Column(
                    children: [
                      const Icon(
                        Icons.description,
                        size: 64,
                        color: AppTheme.textMuted,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Resumes Available',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Upload a resume first to analyze its ATS score.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  )
                else
                  ...(_resumes.map((resume) => _buildATSResumeItem(resume)).toList()),
                
                if (_selectedResumeForATS != null) ...[
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: GradientButton(
                          onPressed: _atsAnalyzing ? null : () => _analyzeResumeWithATS(_selectedResumeForATS!),
                          isLoading: _atsAnalyzing,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.analytics, size: 16),
                              const SizedBox(width: 8),
                              Text(_atsAnalyzing ? 'Analyzing...' : 'Analyze with AI'),
                            ],
                          ),
                        ),
                      ),
                      if (_selectedResumeForATS!['atsAnalysis'] != null) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: GradientButton(
                            onPressed: () {
                              setState(() => _showATSResults = true);
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.visibility, size: 16),
                                const SizedBox(width: 8),
                                const Text('View Results'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumeItem(Map<String, dynamic> resume) {
    final isActive = resume['isActive'] ?? false;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive 
            ? AppTheme.successColor.withOpacity(0.1)
            : AppTheme.glassBackground,
        border: Border.all(
          color: isActive 
              ? AppTheme.successColor.withOpacity(0.3)
              : AppTheme.glassBorder,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.description,
            color: AppTheme.primaryColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  resume['fileName'] ?? 'Unknown',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Uploaded ${DateTime.parse(resume['uploadedAt']).toLocal().toString().split(' ')[0]}',
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    if (resume['fileSize'] != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        _formatFileSize(resume['fileSize']),
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.successColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star,
                        color: AppTheme.successColor,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Active',
                        style: TextStyle(
                          color: AppTheme.successColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              if (resume['atsScore'] != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getATSScoreColor(resume['atsScore'].toDouble()).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getATSScoreColor(resume['atsScore'].toDouble()).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    'ATS: ${resume['atsScore']}%',
                    style: TextStyle(
                      color: _getATSScoreColor(resume['atsScore'].toDouble()),
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 8),
              if (!isActive)
                IconButton(
                  onPressed: () => _activateResume(resume['id']),
                  icon: const Icon(
                    Icons.star_border,
                    color: AppTheme.warningColor,
                    size: 20,
                  ),
                ),
              IconButton(
                onPressed: () => _deleteResume(resume['id']),
                icon: const Icon(
                  Icons.delete,
                  color: AppTheme.errorColor,
                  size: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildATSResumeItem(Map<String, dynamic> resume) {
    final isSelected = _selectedResumeForATS?['id'] == resume['id'];
    
    return GestureDetector(
      onTap: () {
        setState(() => _selectedResumeForATS = resume);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppTheme.primaryColor.withOpacity(0.1)
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
            const Icon(
              Icons.description,
              color: AppTheme.primaryColor,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          resume['fileName'] ?? 'Unknown',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (resume['isActive'] == true)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.successColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Active',
                            style: TextStyle(
                              color: AppTheme.successColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        DateTime.parse(resume['uploadedAt']).toLocal().toString().split(' ')[0],
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 12,
                        ),
                      ),
                      if (resume['atsScore'] != null) ...[
                        const SizedBox(width: 12),
                        Text(
                          'ATS: ${resume['atsScore']}%',
                          style: TextStyle(
                            color: _getATSScoreColor(resume['atsScore'].toDouble()),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (resume['atsAnalysis'] != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Last analyzed: ${DateTime.parse(resume['atsAnalysis']['analyzedAt']).toLocal().toString().split(' ')[0]}',
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _downloadResume(Map<String, dynamic> resume) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/${resume['fileName']}';
      
      await _resumeService.downloadResume(resume['id'], filePath);
      
      ref.read(toastProvider.notifier).showToast(
        'Resume downloaded successfully!',
        ToastType.success,
      );
    } catch (error) {
      ref.read(toastProvider.notifier).showToast(
        'Failed to download resume',
        ToastType.error,
      );
    }
  }
}