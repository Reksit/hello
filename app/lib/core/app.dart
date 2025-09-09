import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/providers/auth_provider.dart';
import '../features/common/providers/toast_provider.dart';
import '../features/common/widgets/toast_widget.dart';
import 'constants/app_constants.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class EduConnectApp extends ConsumerWidget {
  const EduConnectApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark, // Default to dark theme like the web app
      routerConfig: router,
      builder: (context, child) {
        return Scaffold(
          body: Stack(
            children: [
              // Main app content
              child ?? const SizedBox.shrink(),
              
              // Toast overlay
              const Positioned(
                top: 50,
                right: 16,
                child: ToastWidget(),
              ),
            ],
          ),
        );
      },
    );
  }
}