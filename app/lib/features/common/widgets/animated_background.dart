import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class AnimatedBackground extends StatefulWidget {
  final Widget child;
  
  const AnimatedBackground({
    super.key,
    required this.child,
  });

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with TickerProviderStateMixin {
  late AnimationController _controller1;
  late AnimationController _controller2;
  late AnimationController _controller3;
  
  late Animation<Offset> _animation1;
  late Animation<Offset> _animation2;
  late Animation<Offset> _animation3;

  @override
  void initState() {
    super.initState();
    
    _controller1 = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat(reverse: true);
    
    _controller2 = AnimationController(
      duration: const Duration(seconds: 25),
      vsync: this,
    )..repeat(reverse: true);
    
    _controller3 = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    )..repeat(reverse: true);
    
    _animation1 = Tween<Offset>(
      begin: const Offset(-0.2, -0.2),
      end: const Offset(0.2, 0.2),
    ).animate(CurvedAnimation(
      parent: _controller1,
      curve: Curves.easeInOut,
    ));
    
    _animation2 = Tween<Offset>(
      begin: const Offset(0.2, -0.2),
      end: const Offset(-0.2, 0.2),
    ).animate(CurvedAnimation(
      parent: _controller2,
      curve: Curves.easeInOut,
    ));
    
    _animation3 = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: const Offset(0, -0.2),
    ).animate(CurvedAnimation(
      parent: _controller3,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    _controller3.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.backgroundGradient,
      ),
      child: Stack(
        children: [
          // Animated background elements
          AnimatedBuilder(
            animation: _animation1,
            builder: (context, child) {
              return Positioned(
                top: size.height * 0.1 + _animation1.value.dy * 100,
                right: size.width * 0.1 + _animation1.value.dx * 100,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          ),
          
          AnimatedBuilder(
            animation: _animation2,
            builder: (context, child) {
              return Positioned(
                bottom: size.height * 0.1 + _animation2.value.dy * 100,
                left: size.width * 0.1 + _animation2.value.dx * 100,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          ),
          
          AnimatedBuilder(
            animation: _animation3,
            builder: (context, child) {
              return Positioned(
                top: size.height * 0.5 + _animation3.value.dy * 50,
                left: size.width * 0.5 + _animation3.value.dx * 50,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          ),
          
          // Floating tech icons
          Positioned(
            top: size.height * 0.15,
            left: size.width * 0.1,
            child: AnimatedBuilder(
              animation: _controller1,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _animation1.value.dy * 20),
                  child: Icon(
                    Icons.code,
                    size: 24,
                    color: AppTheme.primaryColor.withOpacity(0.3),
                  ),
                );
              },
            ),
          ),
          
          Positioned(
            top: size.height * 0.25,
            right: size.width * 0.15,
            child: AnimatedBuilder(
              animation: _controller2,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _animation2.value.dy * 15),
                  child: Icon(
                    Icons.storage,
                    size: 28,
                    color: AppTheme.secondaryColor.withOpacity(0.25),
                  ),
                );
              },
            ),
          ),
          
          Positioned(
            bottom: size.height * 0.2,
            left: size.width * 0.2,
            child: AnimatedBuilder(
              animation: _controller3,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _animation3.value.dy * 25),
                  child: Icon(
                    Icons.computer,
                    size: 26,
                    color: AppTheme.accentColor.withOpacity(0.3),
                  ),
                );
              },
            ),
          ),
          
          Positioned(
            bottom: size.height * 0.15,
            right: size.width * 0.1,
            child: AnimatedBuilder(
              animation: _controller1,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _animation1.value.dy * 18),
                  child: Icon(
                    Icons.devices,
                    size: 24,
                    color: AppTheme.primaryColor.withOpacity(0.3),
                  ),
                );
              },
            ),
          ),
          
          // Main content
          widget.child,
        ],
      ),
    );
  }
}