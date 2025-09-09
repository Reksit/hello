import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../common/providers/toast_provider.dart';
import '../common/widgets/glass_card.dart';
import '../common/widgets/gradient_button.dart';
import '../common/widgets/professional_input.dart';
import '../services/password_service.dart';

class PasswordChangeComponent extends ConsumerStatefulWidget {
  const PasswordChangeComponent({super.key});

  @override
  ConsumerState<PasswordChangeComponent> createState() => _PasswordChangeComponentState();
}

class _PasswordChangeComponentState extends ConsumerState<PasswordChangeComponent> {
  final PasswordService _passwordService = PasswordService();
  
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  bool _loading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _validateForm() {
    if (_currentPasswordController.text.trim().isEmpty) {
      ref.read(toastProvider.notifier).showToast(
        'Current password is required',
        ToastType.error,
      );
      return false;
    }

    if (_newPasswordController.text.trim().isEmpty) {
      ref.read(toastProvider.notifier).showToast(
        'New password is required',
        ToastType.error,
      );
      return false;
    }

    if (_newPasswordController.text.length < AppConstants.minPasswordLength) {
      ref.read(toastProvider.notifier).showToast(
        'New password must be at least ${AppConstants.minPasswordLength} characters long',
        ToastType.error,
      );
      return false;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      ref.read(toastProvider.notifier).showToast(
        'New password and confirm password do not match',
        ToastType.error,
      );
      return false;
    }

    if (_currentPasswordController.text == _newPasswordController.text) {
      ref.read(toastProvider.notifier).showToast(
        'New password must be different from current password',
        ToastType.error,
      );
      return false;
    }

    return true;
  }

  Future<void> _handleSubmit() async {
    if (!_validateForm()) return;

    setState(() => _loading = true);
    
    try {
      await _passwordService.changePassword(
        _currentPasswordController.text,
        _newPasswordController.text,
      );

      ref.read(toastProvider.notifier).showToast(
        'Password changed successfully!',
        ToastType.success,
      );
      
      // Reset form
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    } catch (error) {
      ref.read(toastProvider.notifier).showToast(
        error.toString().replaceFirst('Exception: ', ''),
        ToastType.error,
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              const Icon(
                Icons.lock,
                color: AppTheme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Change Password',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Form
          GlassCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current password
                ProfessionalInput(
                  controller: _currentPasswordController,
                  label: 'Current Password',
                  hintText: 'Enter your current password',
                  obscureText: !_showCurrentPassword,
                  prefixIcon: Icons.lock_outline,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showCurrentPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppTheme.textMuted,
                    ),
                    onPressed: () {
                      setState(() {
                        _showCurrentPassword = !_showCurrentPassword;
                      });
                    },
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // New password
                ProfessionalInput(
                  controller: _newPasswordController,
                  label: 'New Password',
                  hintText: 'Enter your new password',
                  obscureText: !_showNewPassword,
                  prefixIcon: Icons.lock_outline,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showNewPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppTheme.textMuted,
                    ),
                    onPressed: () {
                      setState(() {
                        _showNewPassword = !_showNewPassword;
                      });
                    },
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  'Password must be at least ${AppConstants.minPasswordLength} characters long',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Confirm password
                ProfessionalInput(
                  controller: _confirmPasswordController,
                  label: 'Confirm New Password',
                  hintText: 'Confirm your new password',
                  obscureText: !_showConfirmPassword,
                  prefixIcon: Icons.lock_outline,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showConfirmPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppTheme.textMuted,
                    ),
                    onPressed: () {
                      setState(() {
                        _showConfirmPassword = !_showConfirmPassword;
                      });
                    },
                  ),
                ),
                
                const SizedBox(height: 32),
                
                GradientButton(
                  onPressed: _loading ? null : _handleSubmit,
                  isLoading: _loading,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.save, size: 20),
                      const SizedBox(width: 8),
                      Text(_loading ? 'Changing Password...' : 'Change Password'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Security tips
          GlassCard(
            padding: const EdgeInsets.all(20),
            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
            borderColor: AppTheme.primaryColor.withOpacity(0.3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.security,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Password Security Tips',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                ...[
                  'Use a combination of letters, numbers, and symbols',
                  'Make it at least 8 characters long',
                  'Don\'t use personal information like your name or email',
                  'Don\'t reuse passwords from other accounts',
                ].map((tip) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '• ',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            tip,
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontSize: 12,
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
      ),
    );
  }
}