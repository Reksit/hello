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
import '../services/student_service.dart';
import 'activity_heatmap_component.dart';

class StudentProfileComponent extends ConsumerStatefulWidget {
  const StudentProfileComponent({super.key});

  @override
  ConsumerState<StudentProfileComponent> createState() => _StudentProfileComponentState();
}

class _StudentProfileComponentState extends ConsumerState<StudentProfileComponent> {
  final StudentService _studentService = StudentService();
  
  Map<String, dynamic>? _profile;
  bool _loading = true;
  bool _isEditing = false;
  bool _saving = false;
  
  final _bioController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _linkedinController = TextEditingController();
  final _githubController = TextEditingController();
  final _portfolioController = TextEditingController();
  
  List<String> _skills = [];
  final _skillController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _bioController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _linkedinController.dispose();
    _githubController.dispose();
    _portfolioController.dispose();
    _skillController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final response = await _studentService.getMyProfile();
      
      setState(() {
        _profile = response;
        _bioController.text = response['bio'] ?? '';
        _phoneController.text = response['phoneNumber'] ?? '';
        _locationController.text = response['location'] ?? '';
        _linkedinController.text = response['linkedinUrl'] ?? '';
        _githubController.text = response['githubUrl'] ?? '';
        _portfolioController.text = response['portfolioUrl'] ?? '';
        _skills = List<String>.from(response['skills'] ?? []);
        _loading = false;
      });
    } catch (error) {
      setState(() => _loading = false);
      final user = ref.read(authProvider).user;
      if (user != null) {
        setState(() {
          _profile = {
            'id': user.id,
            'name': user.name,
            'email': user.email,
            'department': user.department ?? '',
            'className': user.className ?? '',
            'bio': '',
            'skills': <String>[],
            'phoneNumber': '',
            'location': '',
            'linkedinUrl': '',
            'githubUrl': '',
            'portfolioUrl': '',
          };
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_profile == null) return;
    
    setState(() => _saving = true);
    
    try {
      final updateData = {
        'bio': _bioController.text.trim(),
        'skills': _skills,
        'location': _locationController.text.trim(),
        'phone': _phoneController.text.trim(),
        'linkedinUrl': _linkedinController.text.trim(),
        'githubUrl': _githubController.text.trim(),
        'portfolioUrl': _portfolioController.text.trim(),
      };
      
      await _studentService.updateMyProfile(updateData);
      await _loadProfile();
      
      ref.read(toastProvider.notifier).showToast(
        'Profile updated successfully!',
        ToastType.success,
      );
      
      setState(() => _isEditing = false);
    } catch (error) {
      ref.read(toastProvider.notifier).showToast(
        error.toString().replaceFirst('Exception: ', ''),
        ToastType.error,
      );
    } finally {
      setState(() => _saving = false);
    }
  }

  void _addSkill() {
    final skill = _skillController.text.trim();
    if (skill.isNotEmpty && !_skills.contains(skill)) {
      setState(() {
        _skills.add(skill);
      });
      _skillController.clear();
    }
  }

  void _removeSkill(String skill) {
    setState(() {
      _skills.remove(skill);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: LoadingWidget(message: 'Loading profile...'),
      );
    }

    if (_profile == null) {
      return GlassCard(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.person,
              size: 64,
              color: AppTheme.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              'Profile Not Found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Unable to load your profile information.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Student Profile',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GradientButton(
                onPressed: _saving ? null : (_isEditing ? _saveProfile : () => setState(() => _isEditing = true)),
                isLoading: _saving,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_isEditing ? Icons.save : Icons.edit, size: 16),
                    const SizedBox(width: 4),
                    Text(_isEditing ? (_saving ? 'Saving...' : 'Save') : 'Edit Profile'),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Profile card
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left column - Profile info
              Expanded(
                child: GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Avatar
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: AppTheme.glowShadow,
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      Text(
                        _profile!['name'] ?? 'Unknown',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 4),
                      
                      Text(
                        'Student',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      
                      Text(
                        'Class ${_profile!['className'] ?? 'Unknown'}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textMuted,
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Contact info
                      _buildContactInfo(
                        Icons.business,
                        _profile!['department'] ?? 'Unknown Department',
                      ),
                      _buildContactInfo(
                        Icons.email,
                        _profile!['email'] ?? 'No email',
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Right column - Editable details
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    // Bio section
                    GlassCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'About',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_isEditing)
                            ProfessionalInput(
                              controller: _bioController,
                              hintText: 'Tell us about yourself...',
                              maxLines: 4,
                            )
                          else
                            Text(
                              _profile!['bio']?.isNotEmpty == true 
                                  ? _profile!['bio'] 
                                  : 'No bio added yet.',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Contact information
                    GlassCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Contact Information',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ProfessionalInput(
                            controller: _phoneController,
                            label: 'Phone',
                            hintText: 'Phone number',
                            prefixIcon: Icons.phone,
                            readOnly: !_isEditing,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Social links
                    GlassCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Social Links',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ProfessionalInput(
                            controller: _linkedinController,
                            label: 'LinkedIn',
                            hintText: 'https://linkedin.com/in/username',
                            prefixIcon: Icons.link,
                            readOnly: !_isEditing,
                            suffixIcon: _linkedinController.text.isNotEmpty && !_isEditing
                                ? IconButton(
                                    icon: const Icon(Icons.open_in_new, color: AppTheme.primaryColor),
                                    onPressed: () async {
                                      final uri = Uri.parse(_linkedinController.text);
                                      if (await canLaunchUrl(uri)) {
                                        await launchUrl(uri);
                                      }
                                    },
                                  )
                                : null,
                          ),
                          const SizedBox(height: 12),
                          ProfessionalInput(
                            controller: _githubController,
                            label: 'GitHub',
                            hintText: 'https://github.com/username',
                            prefixIcon: Icons.code,
                            readOnly: !_isEditing,
                            suffixIcon: _githubController.text.isNotEmpty && !_isEditing
                                ? IconButton(
                                    icon: const Icon(Icons.open_in_new, color: AppTheme.primaryColor),
                                    onPressed: () async {
                                      final uri = Uri.parse(_githubController.text);
                                      if (await canLaunchUrl(uri)) {
                                        await launchUrl(uri);
                                      }
                                    },
                                  )
                                : null,
                          ),
                          const SizedBox(height: 12),
                          ProfessionalInput(
                            controller: _portfolioController,
                            label: 'Portfolio',
                            hintText: 'https://yourportfolio.com',
                            prefixIcon: Icons.web,
                            readOnly: !_isEditing,
                            suffixIcon: _portfolioController.text.isNotEmpty && !_isEditing
                                ? IconButton(
                                    icon: const Icon(Icons.open_in_new, color: AppTheme.primaryColor),
                                    onPressed: () async {
                                      final uri = Uri.parse(_portfolioController.text);
                                      if (await canLaunchUrl(uri)) {
                                        await launchUrl(uri);
                                      }
                                    },
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Skills
                    GlassCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Skills',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          // Skills display
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _skills.map((skill) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      skill,
                                      style: const TextStyle(
                                        color: AppTheme.primaryColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (_isEditing) ...[
                                      const SizedBox(width: 4),
                                      GestureDetector(
                                        onTap: () => _removeSkill(skill),
                                        child: const Icon(
                                          Icons.close,
                                          color: AppTheme.primaryColor,
                                          size: 14,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                          
                          if (_isEditing) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: ProfessionalInput(
                                    controller: _skillController,
                                    hintText: 'Add a skill',
                                    onSubmitted: (_) => _addSkill(),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GradientButton(
                                  onPressed: _addSkill,
                                  child: const Text('Add'),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Activity heatmap
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Activity Overview',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ActivityHeatmapComponent(
                  userId: _profile!['id'],
                  userName: _profile!['name'],
                  showTitle: false,
                ),
              ],
            ),
          ),
          
          if (_isEditing) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GradientButton(
                    onPressed: () {
                      setState(() => _isEditing = false);
                      _loadProfile(); // Reset changes
                    },
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GradientButton(
                    onPressed: _saving ? null : _saveProfile,
                    isLoading: _saving,
                    child: Text(_saving ? 'Saving...' : 'Save Changes'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContactInfo(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textMuted, size: 16),
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
      ),
    );
  }

  void _addSkill() {
    final skill = _skillController.text.trim();
    if (skill.isNotEmpty && !_skills.contains(skill)) {
      setState(() {
        _skills.add(skill);
      });
      _skillController.clear();
    }
  }
}