import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/user_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../common/providers/toast_provider.dart';
import '../../common/widgets/animated_background.dart';
import '../../common/widgets/glass_card.dart';
import '../../common/widgets/gradient_button.dart';
import '../../common/widgets/professional_input.dart';
import '../providers/auth_provider.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _graduationYearController = TextEditingController();
  final _batchController = TextEditingController();
  final _companyController = TextEditingController();
  
  String _selectedRole = 'student';
  String _selectedDepartment = '';
  String _selectedClass = '';
  bool _obscurePassword = true;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppConstants.longAnimation,
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _graduationYearController.dispose();
    _batchController.dispose();
    _companyController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    
    try {
      final request = RegisterRequest(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _selectedRole != 'alumni' ? _passwordController.text : null,
        phoneNumber: _phoneController.text.trim(),
        department: _selectedDepartment,
        className: _selectedRole == 'student' ? _selectedClass : null,
        role: _selectedRole.toUpperCase(),
        graduationYear: _selectedRole == 'alumni' ? _graduationYearController.text : null,
        batch: _selectedRole == 'alumni' ? _batchController.text : null,
        placedCompany: _selectedRole == 'alumni' ? _companyController.text.trim() : null,
      );
      
      await ref.read(authProvider.notifier).register(request);
      
      ref.read(toastProvider.notifier).showToast(
        'Registration successful!',
        ToastType.success,
      );
      
      if (_selectedRole == 'alumni') {
        ref.read(toastProvider.notifier).showToast(
          'Alumni registration submitted! Please wait for management approval.',
          ToastType.info,
        );
        context.go('/login');
      } else {
        context.go('/verify-otp', extra: _emailController.text.trim());
      }
    } catch (error) {
      ref.read(toastProvider.notifier).showToast(
        error.toString().replaceFirst('Exception: ', ''),
        ToastType.error,
      );
    }
  }

  Widget _buildRoleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Your Role *',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildRoleOption('student', Icons.school, 'Student'),
            const SizedBox(width: 8),
            _buildRoleOption('professor', Icons.person_outline, 'Professor'),
            const SizedBox(width: 8),
            _buildRoleOption('alumni', Icons.work_outline, 'Alumni'),
          ],
        ),
      ],
    );
  }

  Widget _buildRoleOption(String role, IconData icon, String label) {
    final isSelected = _selectedRole == role;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedRole = role;
          });
        },
        child: AnimatedContainer(
          duration: AppConstants.mediumAnimation,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor.withOpacity(0.2) : AppTheme.glassBackground,
            border: Border.all(
              color: isSelected ? AppTheme.primaryColor : AppTheme.glassBorder,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 24,
                color: isSelected ? AppTheme.primaryColor : AppTheme.textMuted,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isSelected ? AppTheme.primaryColor : AppTheme.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    
    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Column(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: AppTheme.mediumShadow,
                            ),
                            child: const Icon(
                              Icons.person_add,
                              size: 30,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Join EduConnect',
                            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create your educational journey',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Registration form
                    GlassCard(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Role selection
                              _buildRoleSelector(),
                              
                              const SizedBox(height: 24),
                              
                              // Name and Phone
                              Row(
                                children: [
                                  Expanded(
                                    child: ProfessionalInput(
                                      controller: _nameController,
                                      label: 'Full Name',
                                      hintText: 'Enter your full name',
                                      prefixIcon: Icons.person_outline,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Name is required';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: ProfessionalInput(
                                      controller: _phoneController,
                                      label: 'Phone Number',
                                      hintText: 'Enter phone number',
                                      keyboardType: TextInputType.phone,
                                      prefixIcon: Icons.phone_outlined,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Phone is required';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 20),
                              
                              // Email
                              ProfessionalInput(
                                controller: _emailController,
                                label: 'Email Address',
                                hintText: _selectedRole == 'alumni' 
                                    ? 'Enter your email'
                                    : 'Enter your college email',
                                keyboardType: TextInputType.emailAddress,
                                prefixIcon: Icons.email_outlined,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Email is required';
                                  }
                                  if (_selectedRole != 'alumni' && 
                                      !value.endsWith(AppConstants.collegeEmailDomain)) {
                                    return 'Please use your college email address';
                                  }
                                  return null;
                                },
                              ),
                              
                              const SizedBox(height: 20),
                              
                              // Password (not for alumni)
                              if (_selectedRole != 'alumni') ...[
                                ProfessionalInput(
                                  controller: _passwordController,
                                  label: 'Password',
                                  hintText: 'Create a secure password',
                                  obscureText: _obscurePassword,
                                  prefixIcon: Icons.lock_outline,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: AppTheme.textMuted,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Password is required';
                                    }
                                    if (value.length < AppConstants.minPasswordLength) {
                                      return 'Password must be at least ${AppConstants.minPasswordLength} characters';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),
                              ],
                              
                              // Department
                              DropdownButtonFormField<String>(
                                value: _selectedDepartment.isEmpty ? null : _selectedDepartment,
                                decoration: const InputDecoration(
                                  labelText: 'Department *',
                                  prefixIcon: Icon(Icons.business_outlined),
                                ),
                                dropdownColor: AppTheme.darkSurface,
                                style: const TextStyle(color: AppTheme.textPrimary),
                                items: AppConstants.departments.map((dept) {
                                  return DropdownMenuItem(
                                    value: dept,
                                    child: Text(
                                      dept,
                                      style: const TextStyle(color: AppTheme.textPrimary),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedDepartment = value ?? '';
                                  });
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Department is required';
                                  }
                                  return null;
                                },
                              ),
                              
                              const SizedBox(height: 20),
                              
                              // Student specific fields
                              if (_selectedRole == 'student') ...[
                                DropdownButtonFormField<String>(
                                  value: _selectedClass.isEmpty ? null : _selectedClass,
                                  decoration: const InputDecoration(
                                    labelText: 'Class *',
                                    prefixIcon: Icon(Icons.class_outlined),
                                  ),
                                  dropdownColor: AppTheme.darkSurface,
                                  style: const TextStyle(color: AppTheme.textPrimary),
                                  items: AppConstants.classes.map((cls) {
                                    return DropdownMenuItem(
                                      value: cls,
                                      child: Text(
                                        'Class $cls',
                                        style: const TextStyle(color: AppTheme.textPrimary),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedClass = value ?? '';
                                    });
                                  },
                                  validator: (value) {
                                    if (_selectedRole == 'student' && (value == null || value.isEmpty)) {
                                      return 'Class is required for students';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),
                              ],
                              
                              // Alumni specific fields
                              if (_selectedRole == 'alumni') ...[
                                Row(
                                  children: [
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        value: _graduationYearController.text.isEmpty ? null : _graduationYearController.text,
                                        decoration: const InputDecoration(
                                          labelText: 'Graduation Year *',
                                          prefixIcon: Icon(Icons.calendar_today_outlined),
                                        ),
                                        dropdownColor: AppTheme.darkSurface,
                                        style: const TextStyle(color: AppTheme.textPrimary),
                                        items: AppConstants.graduationYears.map((year) {
                                          return DropdownMenuItem(
                                            value: year,
                                            child: Text(
                                              year,
                                              style: const TextStyle(color: AppTheme.textPrimary),
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            _graduationYearController.text = value ?? '';
                                          });
                                        },
                                        validator: (value) {
                                          if (_selectedRole == 'alumni' && (value == null || value.isEmpty)) {
                                            return 'Graduation year is required';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        value: _batchController.text.isEmpty ? null : _batchController.text,
                                        decoration: const InputDecoration(
                                          labelText: 'Batch *',
                                          prefixIcon: Icon(Icons.group_outlined),
                                        ),
                                        dropdownColor: AppTheme.darkSurface,
                                        style: const TextStyle(color: AppTheme.textPrimary),
                                        items: AppConstants.batches.map((batch) {
                                          return DropdownMenuItem(
                                            value: batch,
                                            child: Text(
                                              'Batch $batch',
                                              style: const TextStyle(color: AppTheme.textPrimary),
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            _batchController.text = value ?? '';
                                          });
                                        },
                                        validator: (value) {
                                          if (_selectedRole == 'alumni' && (value == null || value.isEmpty)) {
                                            return 'Batch is required';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                ProfessionalInput(
                                  controller: _companyController,
                                  label: 'Current Company',
                                  hintText: 'Enter your current company',
                                  prefixIcon: Icons.business_outlined,
                                  validator: (value) {
                                    if (_selectedRole == 'alumni' && (value == null || value.isEmpty)) {
                                      return 'Company name is required for alumni';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),
                              ],
                              
                              // Register button
                              GradientButton(
                                onPressed: authState.isLoading ? null : _handleRegister,
                                isLoading: authState.isLoading,
                                child: const Text(
                                  'Create Account',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: 24),
                              
                              // Login link
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Already have an account? ',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => context.go('/login'),
                                    child: Text(
                                      'Sign in',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: AppTheme.primaryLight,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}