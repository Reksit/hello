import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../auth/providers/auth_provider.dart';
import '../common/providers/toast_provider.dart';
import '../common/widgets/glass_card.dart';
import '../common/widgets/gradient_button.dart';
import '../common/widgets/loading_widget.dart';
import '../common/widgets/professional_input.dart';
import '../services/job_service.dart';

class JobBoardComponent extends ConsumerStatefulWidget {
  const JobBoardComponent({super.key});

  @override
  ConsumerState<JobBoardComponent> createState() => _JobBoardComponentState();
}

class _JobBoardComponentState extends ConsumerState<JobBoardComponent> {
  final JobService _jobService = JobService();
  
  List<dynamic> _jobs = [];
  bool _loading = true;
  bool _showCreateForm = false;
  Map<String, dynamic>? _editingJob;
  
  final _titleController = TextEditingController();
  final _companyController = TextEditingController();
  final _locationController = TextEditingController();
  final _salaryController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contactEmailController = TextEditingController();
  final _applicationUrlController = TextEditingController();
  
  String _selectedType = 'FULL_TIME';
  List<String> _requirements = [''];

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _companyController.dispose();
    _locationController.dispose();
    _salaryController.dispose();
    _descriptionController.dispose();
    _contactEmailController.dispose();
    _applicationUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadJobs() async {
    try {
      final response = await _jobService.getAllJobs();
      setState(() {
        _jobs = response;
        _loading = false;
      });
    } catch (error) {
      setState(() => _loading = false);
      if (!error.toString().contains('404')) {
        ref.read(toastProvider.notifier).showToast(
          'Failed to load jobs',
          ToastType.error,
        );
      }
    }
  }

  Future<void> _createOrUpdateJob() async {
    if (_titleController.text.trim().isEmpty ||
        _companyController.text.trim().isEmpty ||
        _locationController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty ||
        _contactEmailController.text.trim().isEmpty) {
      ref.read(toastProvider.notifier).showToast(
        'Please fill in all required fields',
        ToastType.error,
      );
      return;
    }

    try {
      final jobData = {
        'title': _titleController.text.trim(),
        'company': _companyController.text.trim(),
        'location': _locationController.text.trim(),
        'type': _selectedType,
        'salary': _salaryController.text.trim(),
        'description': _descriptionController.text.trim(),
        'requirements': _requirements.where((req) => req.trim().isNotEmpty).toList(),
        'applicationUrl': _applicationUrlController.text.trim(),
        'contactEmail': _contactEmailController.text.trim(),
      };

      if (_editingJob != null) {
        await _jobService.updateJob(_editingJob!['id'], jobData);
        ref.read(toastProvider.notifier).showToast(
          'Job updated successfully!',
          ToastType.success,
        );
      } else {
        await _jobService.createJob(jobData);
        ref.read(toastProvider.notifier).showToast(
          'Job posted successfully!',
          ToastType.success,
        );
      }
      
      _resetForm();
      _loadJobs();
    } catch (error) {
      ref.read(toastProvider.notifier).showToast(
        error.toString().replaceFirst('Exception: ', ''),
        ToastType.error,
      );
    }
  }

  void _resetForm() {
    _titleController.clear();
    _companyController.clear();
    _locationController.clear();
    _salaryController.clear();
    _descriptionController.clear();
    _contactEmailController.clear();
    _applicationUrlController.clear();
    _selectedType = 'FULL_TIME';
    _requirements = [''];
    _editingJob = null;
    _showCreateForm = false;
  }

  void _editJob(Map<String, dynamic> job) {
    setState(() {
      _editingJob = job;
      _showCreateForm = true;
      _titleController.text = job['title'] ?? '';
      _companyController.text = job['company'] ?? '';
      _locationController.text = job['location'] ?? '';
      _salaryController.text = job['salary'] ?? '';
      _descriptionController.text = job['description'] ?? '';
      _contactEmailController.text = job['contactEmail'] ?? '';
      _applicationUrlController.text = job['applicationUrl'] ?? '';
      _selectedType = job['type'] ?? 'FULL_TIME';
      _requirements = List<String>.from(job['requirements'] ?? ['']);
      if (_requirements.isEmpty) _requirements = [''];
    });
  }

  Future<void> _deleteJob(String jobId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        title: const Text(
          'Delete Job',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: const Text(
          'Are you sure you want to delete this job?',
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
        await _jobService.deleteJob(jobId);
        ref.read(toastProvider.notifier).showToast(
          'Job deleted successfully',
          ToastType.success,
        );
        _loadJobs();
      } catch (error) {
        ref.read(toastProvider.notifier).showToast(
          error.toString().replaceFirst('Exception: ', ''),
          ToastType.error,
        );
      }
    }
  }

  bool _canEditJob(Map<String, dynamic> job) {
    final user = ref.read(authProvider).user;
    return user?.role == 'ALUMNI' && user?.id == job['postedBy'];
  }

  Color _getJobTypeColor(String type) {
    switch (type) {
      case 'FULL_TIME':
        return AppTheme.successColor;
      case 'INTERNSHIP':
        return AppTheme.primaryColor;
      case 'PART_TIME':
        return AppTheme.warningColor;
      case 'CONTRACT':
        return AppTheme.secondaryColor;
      default:
        return AppTheme.textMuted;
    }
  }

  String _getJobTypeLabel(String type) {
    switch (type) {
      case 'FULL_TIME':
        return 'Full-time';
      case 'PART_TIME':
        return 'Part-time';
      case 'INTERNSHIP':
        return 'Internship';
      case 'CONTRACT':
        return 'Contract';
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    
    if (_loading) {
      return const Center(
        child: LoadingWidget(message: 'Loading job opportunities...'),
      );
    }

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
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
                  Icons.work,
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
                      'Job Opportunities',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Discover career opportunities from our alumni network',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (user?.role == 'ALUMNI')
                GradientButton(
                  onPressed: () {
                    setState(() => _showCreateForm = true);
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add, size: 16),
                      const SizedBox(width: 4),
                      const Text('Post Job'),
                    ],
                  ),
                ),
            ],
          ),
        ),
        
        // Create job form
        if (_showCreateForm) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _editingJob != null ? 'Edit Job Posting' : 'Create New Job Posting',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: _resetForm,
                        icon: const Icon(
                          Icons.close,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Basic info
                  Row(
                    children: [
                      Expanded(
                        child: ProfessionalInput(
                          controller: _titleController,
                          label: 'Job Title',
                          hintText: 'e.g. Senior Software Engineer',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ProfessionalInput(
                          controller: _companyController,
                          label: 'Company',
                          hintText: 'Company name',
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: ProfessionalInput(
                          controller: _locationController,
                          label: 'Location',
                          hintText: 'e.g. Bangalore, India',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedType,
                          decoration: const InputDecoration(
                            labelText: 'Job Type',
                            prefixIcon: Icon(Icons.work_outline),
                          ),
                          dropdownColor: AppTheme.darkSurface,
                          style: const TextStyle(color: AppTheme.textPrimary),
                          items: ['FULL_TIME', 'PART_TIME', 'INTERNSHIP', 'CONTRACT'].map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(
                                _getJobTypeLabel(type),
                                style: const TextStyle(color: AppTheme.textPrimary),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedType = value ?? 'FULL_TIME');
                          },
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: ProfessionalInput(
                          controller: _salaryController,
                          label: 'Salary (Optional)',
                          hintText: 'e.g. ₹15-25 LPA',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ProfessionalInput(
                          controller: _contactEmailController,
                          label: 'Contact Email',
                          hintText: 'your.email@company.com',
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  ProfessionalInput(
                    controller: _descriptionController,
                    label: 'Job Description',
                    hintText: 'Describe the role, responsibilities, and what you\'re looking for...',
                    maxLines: 4,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Requirements
                  Text(
                    'Requirements',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  ..._requirements.asMap().entries.map((entry) {
                    final index = entry.key;
                    final requirement = entry.value;
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: requirement,
                              style: const TextStyle(color: AppTheme.textPrimary),
                              decoration: InputDecoration(
                                hintText: 'e.g. 3+ years experience in React',
                                hintStyle: const TextStyle(color: AppTheme.textMuted),
                                filled: true,
                                fillColor: AppTheme.glassBackground,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppTheme.glassBorder),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppTheme.glassBorder),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                                ),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _requirements[index] = value;
                                });
                              },
                            ),
                          ),
                          if (_requirements.length > 1)
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _requirements.removeAt(index);
                                });
                              },
                              icon: const Icon(
                                Icons.delete,
                                color: AppTheme.errorColor,
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                  
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _requirements.add('');
                      });
                    },
                    icon: const Icon(Icons.add, color: AppTheme.primaryColor),
                    label: const Text(
                      'Add Requirement',
                      style: TextStyle(color: AppTheme.primaryColor),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  ProfessionalInput(
                    controller: _applicationUrlController,
                    label: 'Application URL (Optional)',
                    hintText: 'https://company.com/careers/job-id',
                    keyboardType: TextInputType.url,
                  ),
                  
                  const SizedBox(height: 20),
                  
                  Row(
                    children: [
                      Expanded(
                        child: GradientButton(
                          onPressed: _createOrUpdateJob,
                          child: Text(_editingJob != null ? 'Update Job' : 'Post Job'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GradientButton(
                          onPressed: _resetForm,
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
        
        // Jobs list
        Expanded(
          child: _jobs.isEmpty
              ? GlassCard(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.work,
                        size: 64,
                        color: AppTheme.textMuted,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Jobs Available',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Be the first to share an exciting career opportunity!',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (user?.role == 'ALUMNI') ...[
                        const SizedBox(height: 16),
                        GradientButton(
                          onPressed: () {
                            setState(() => _showCreateForm = true);
                          },
                          child: const Text('Post the First Job'),
                        ),
                      ],
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _jobs.length,
                  itemBuilder: (context, index) {
                    final job = _jobs[index];
                    return _buildJobCard(job);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildJobCard(Map<String, dynamic> job) {
    final jobType = job['type'] ?? 'FULL_TIME';
    final typeColor = _getJobTypeColor(jobType);
    
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
                              job['title'] ?? 'Untitled Job',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: typeColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: typeColor.withOpacity(0.3)),
                            ),
                            child: Text(
                              _getJobTypeLabel(jobType),
                              style: TextStyle(
                                color: typeColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      
                      Row(
                        children: [
                          Icon(Icons.business, color: AppTheme.textMuted, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            job['company'] ?? 'Unknown Company',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.location_on, color: AppTheme.textMuted, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            job['location'] ?? 'Location not specified',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      
                      if (job['salary'] != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.attach_money, color: AppTheme.successColor, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              job['salary'],
                              style: const TextStyle(
                                color: AppTheme.successColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                
                if (_canEditJob(job))
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => _editJob(job),
                        icon: const Icon(
                          Icons.edit,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                      ),
                      IconButton(
                        onPressed: () => _deleteJob(job['id']),
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
            
            const SizedBox(height: 12),
            
            Text(
              job['description'] ?? 'No description available',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 12),
            
            // Requirements
            if (job['requirements'] != null && (job['requirements'] as List).isNotEmpty) ...[
              Text(
                'Requirements:',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: (job['requirements'] as List).take(3).map((req) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      req.toString(),
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 10,
                      ),
                    ),
                  );
                }).toList(),
              ),
              if ((job['requirements'] as List).length > 3)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '+${(job['requirements'] as List).length - 3} more requirements',
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
            
            const SizedBox(height: 16),
            
            // Posted info
            Row(
              children: [
                Icon(Icons.person, color: AppTheme.textMuted, size: 14),
                const SizedBox(width: 4),
                Text(
                  'Posted by ${job['postedByName'] ?? 'Unknown'}',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(Icons.access_time, color: AppTheme.textMuted, size: 14),
                const SizedBox(width: 4),
                Text(
                  job['postedAt'] != null 
                      ? DateTime.parse(job['postedAt']).toLocal().toString().split(' ')[0]
                      : 'Unknown date',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              children: [
                if (job['applicationUrl'] != null && job['applicationUrl'].toString().isNotEmpty)
                  Expanded(
                    child: GradientButton(
                      onPressed: () async {
                        final uri = Uri.parse(job['applicationUrl']);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.open_in_new, size: 16),
                          const SizedBox(width: 4),
                          const Text('Apply Now'),
                        ],
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: GradientButton(
                      onPressed: () async {
                        final uri = Uri(
                          scheme: 'mailto',
                          path: job['contactEmail'] ?? job['postedByEmail'],
                          query: 'subject=Application for ${job['title']}&body=Dear ${job['postedByName']},%0D%0A%0D%0AI am interested in applying for the ${job['title']} position at ${job['company']}.%0D%0A%0D%0APlease find my resume attached.%0D%0A%0D%0AThank you for your consideration.%0D%0A%0D%0ABest regards',
                        );
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.email, size: 16),
                          const SizedBox(width: 4),
                          const Text('Apply Now'),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: GradientButton(
                    onPressed: () async {
                      final uri = Uri(
                        scheme: 'mailto',
                        path: job['contactEmail'] ?? job['postedByEmail'],
                        query: 'subject=Inquiry about ${job['title']}',
                      );
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.contact_mail, size: 16),
                        const SizedBox(width: 4),
                        const Text('Contact'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}