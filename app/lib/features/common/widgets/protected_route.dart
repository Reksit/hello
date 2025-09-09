import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/toast_provider.dart';
import 'loading_widget.dart';

class ProtectedRoute extends ConsumerWidget {
  final Widget child;
  final List<String> allowedRoles;

  const ProtectedRoute({
    super.key,
    required this.child,
    required this.allowedRoles,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    
    if (authState.isLoading) {
      return const Scaffold(
        body: Center(
          child: ProfessionalLoadingWidget(
            title: 'Loading...',
            subtitle: 'Please wait while we verify your access',
            icon: Icons.security,
          ),
        ),
      );
    }
    
    if (authState.user == null) {
      print('ProtectedRoute: No authenticated user, redirecting to login');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/login');
      });
      return const Scaffold(
        body: Center(
          child: LoadingWidget(message: 'Redirecting to login...'),
        ),
      );
    }
    
    if (!allowedRoles.contains(authState.user!.role)) {
      print('ProtectedRoute: User role not authorized: ${authState.user!.role}, Required: $allowedRoles');
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(toastProvider.notifier).showToast(
          'You do not have permission to access this page',
          ToastType.error,
        );
        context.go('/login');
      });
      
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.block,
                size: 64,
                color: AppTheme.errorColor,
              ),
              const SizedBox(height: 16),
              Text(
                'Access Denied',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You do not have permission to access this page',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    print('ProtectedRoute: Access granted for user: ${authState.user!.name}, Role: ${authState.user!.role}');
    return child;
  }
}