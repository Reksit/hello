import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/pages/login_page.dart';
import '../../features/auth/pages/register_page.dart';
import '../../features/auth/pages/verify_otp_page.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/dashboards/pages/alumni_dashboard_page.dart';
import '../../features/dashboards/pages/management_dashboard_page.dart';
import '../../features/dashboards/pages/professor_dashboard_page.dart';
import '../../features/dashboards/pages/student_dashboard_page.dart';
import '../../features/debug/pages/debug_page.dart';
import '../../features/profile/pages/user_profile_page.dart';
import '../constants/app_constants.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authState.user != null;
      final isLoggingIn = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/verify-otp';
      
      // If not logged in and not on auth pages, redirect to login
      if (!isLoggedIn && !isLoggingIn) {
        return '/login';
      }
      
      // If logged in and on auth pages, redirect to appropriate dashboard
      if (isLoggedIn && isLoggingIn) {
        switch (authState.user?.role) {
          case AppConstants.studentRole:
            return '/student';
          case AppConstants.professorRole:
            return '/professor';
          case AppConstants.managementRole:
            return '/management';
          case AppConstants.alumniRole:
            return '/alumni';
          default:
            return '/login';
        }
      }
      
      return null;
    },
    routes: [
      // Auth routes
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/verify-otp',
        builder: (context, state) {
          final email = state.extra as String?;
          return VerifyOtpPage(email: email);
        },
      ),
      
      // Debug route
      GoRoute(
        path: '/debug',
        builder: (context, state) => const DebugPage(),
      ),
      
      // Profile route
      GoRoute(
        path: '/profile/:userId',
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          return UserProfilePage(userId: userId);
        },
      ),
      
      // Dashboard routes
      GoRoute(
        path: '/student',
        builder: (context, state) => const StudentDashboardPage(),
      ),
      GoRoute(
        path: '/professor',
        builder: (context, state) => const ProfessorDashboardPage(),
      ),
      GoRoute(
        path: '/management',
        builder: (context, state) => const ManagementDashboardPage(),
      ),
      GoRoute(
        path: '/alumni',
        builder: (context, state) => const AlumniDashboardPage(),
      ),
      
      // Fallback route
      GoRoute(
        path: '/',
        redirect: (context, state) => '/login',
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Page Not Found',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'The page you are looking for does not exist.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/login'),
              child: const Text('Go to Login'),
            ),
          ],
        ),
      ),
    ),
  );
});