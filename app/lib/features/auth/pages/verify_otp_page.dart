import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../common/providers/toast_provider.dart';
import '../../common/widgets/animated_background.dart';
import '../../common/widgets/glass_card.dart';
import '../../common/widgets/gradient_button.dart';
import '../providers/auth_provider.dart';

class VerifyOtpPage extends ConsumerStatefulWidget {
  final String? email;
  
  const VerifyOtpPage({super.key, this.email});

  @override
  ConsumerState<VerifyOtpPage> createState() => _VerifyOtpPageState();
}

class _VerifyOtpPageState extends ConsumerState<VerifyOtpPage>
    with TickerProviderStateMixin {
  final _otpController = TextEditingController();
  Timer? _timer;
  int _timeLeft = 300; // 5 minutes
  bool _canResend = false;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    if (widget.email == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/register');
      });
      return;
    }
    
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
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _startTimer();
    _animationController.forward();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() {
          _timeLeft--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        timer.cancel();
      }
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> _handleVerifyOtp() async {
    if (_otpController.text.length != 4) {
      ref.read(toastProvider.notifier).showToast(
        'Please enter a 4-digit OTP',
        ToastType.error,
      );
      return;
    }
    
    try {
      await ref.read(authProvider.notifier).verifyOtp(
        widget.email!,
        _otpController.text,
      );
      
      ref.read(toastProvider.notifier).showToast(
        'Email verified successfully!',
        ToastType.success,
      );
      
      context.go('/login');
    } catch (error) {
      ref.read(toastProvider.notifier).showToast(
        error.toString().replaceFirst('Exception: ', ''),
        ToastType.error,
      );
    }
  }

  Future<void> _handleResendOtp() async {
    if (!_canResend) return;
    
    try {
      await ref.read(authProvider.notifier).resendOtp(widget.email!);
      
      ref.read(toastProvider.notifier).showToast(
        'OTP sent successfully!',
        ToastType.success,
      );
      
      setState(() {
        _timeLeft = 300;
        _canResend = false;
      });
      _startTimer();
    } catch (error) {
      ref.read(toastProvider.notifier).showToast(
        error.toString().replaceFirst('Exception: ', ''),
        ToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    
    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              height: MediaQuery.of(context).size.height - 
                     MediaQuery.of(context).padding.top - 48,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: GlassCard(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              // Header
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [AppTheme.successColor, AppTheme.primaryColor],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: AppTheme.glowShadow,
                                ),
                                child: const Icon(
                                  Icons.email_outlined,
                                  size: 40,
                                  color: Colors.white,
                                ),
                              ),
                              
                              const SizedBox(height: 24),
                              
                              Text(
                                'Verify Your Email',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              
                              const SizedBox(height: 8),
                              
                              Text(
                                'Enter the code sent to your email',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              
                              const SizedBox(height: 16),
                              
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.glassBackground,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppTheme.glassBorder),
                                ),
                                child: Text(
                                  widget.email ?? '',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.primaryLight,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: 32),
                              
                              // OTP Input
                              TextFormField(
                                controller: _otpController,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                maxLength: 4,
                                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 8,
                                ),
                                decoration: InputDecoration(
                                  hintText: '0000',
                                  hintStyle: TextStyle(
                                    color: AppTheme.textMuted.withOpacity(0.5),
                                    letterSpacing: 8,
                                  ),
                                  counterText: '',
                                  suffixIcon: const Icon(
                                    Icons.security,
                                    color: AppTheme.successColor,
                                  ),
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                onChanged: (value) {
                                  if (value.length == 4) {
                                    FocusScope.of(context).unfocus();
                                  }
                                },
                              ),
                              
                              const SizedBox(height: 32),
                              
                              // Timer and resend section
                              if (_timeLeft > 0)
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppTheme.glassBackground,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppTheme.glassBorder),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.timer_outlined,
                                            color: AppTheme.primaryColor,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            _formatTime(_timeLeft),
                                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                              color: AppTheme.primaryColor,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'monospace',
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Time remaining',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: AppTheme.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppTheme.warningColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppTheme.warningColor.withOpacity(0.3)),
                                  ),
                                  child: Column(
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: _handleResendOtp,
                                        icon: const Icon(Icons.refresh),
                                        label: const Text('Resend Code'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.warningColor,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Code expired - Get a new one',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: AppTheme.warningColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              
                              const SizedBox(height: 32),
                              
                              // Verify button
                              GradientButton(
                                onPressed: (authState.isLoading || _otpController.text.length != 4) 
                                    ? null 
                                    : _handleVerifyOtp,
                                isLoading: authState.isLoading,
                                child: const Text(
                                  'Verify Email',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: 24),
                              
                              // Progress indicators
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 32,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 32,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: AppTheme.successColor,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 32,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: AppTheme.textMuted.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 8),
                              
                              Text(
                                'Step 2 of 3 - Email Verification',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.textMuted,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
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
    );
  }
}