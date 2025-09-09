import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';

enum CardVariant { 
  defaultCard, 
  interactive, 
  glass, 
  solid 
}

enum CardPadding { 
  none, 
  small, 
  medium, 
  large 
}

class ProfessionalCard extends StatefulWidget {
  final Widget child;
  final CardVariant variant;
  final CardPadding cardPadding;
  final bool hover;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final Color? borderColor;
  final List<BoxShadow>? boxShadow;
  final double borderRadius;

  const ProfessionalCard({
    super.key,
    required this.child,
    this.variant = CardVariant.defaultCard,
    this.cardPadding = CardPadding.medium,
    this.hover = false,
    this.onTap,
    this.width,
    this.height,
    this.margin,
    this.backgroundColor,
    this.borderColor,
    this.boxShadow,
    this.borderRadius = 16,
  });

  @override
  State<ProfessionalCard> createState() => _ProfessionalCardState();
}

class _ProfessionalCardState extends State<ProfessionalCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppConstants.mediumAnimation,
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _elevationAnimation = Tween<double>(
      begin: 0.0,
      end: 8.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getBackgroundColor() {
    if (widget.backgroundColor != null) return widget.backgroundColor!;
    
    switch (widget.variant) {
      case CardVariant.defaultCard:
        return AppTheme.glassBackground;
      case CardVariant.interactive:
        return AppTheme.glassBackground;
      case CardVariant.glass:
        return const Color(0x0DFFFFFF); // 5% white opacity
      case CardVariant.solid:
        return const Color(0x26FFFFFF); // 15% white opacity
    }
  }

  Color _getBorderColor() {
    if (widget.borderColor != null) return widget.borderColor!;
    
    switch (widget.variant) {
      case CardVariant.defaultCard:
        return AppTheme.glassBorder;
      case CardVariant.interactive:
        return AppTheme.glassBorder;
      case CardVariant.glass:
        return const Color(0x1AFFFFFF); // 10% white opacity
      case CardVariant.solid:
        return const Color(0x4DFFFFFF); // 30% white opacity
    }
  }

  EdgeInsetsGeometry _getPadding() {
    switch (widget.cardPadding) {
      case CardPadding.none:
        return EdgeInsets.zero;
      case CardPadding.small:
        return const EdgeInsets.all(16);
      case CardPadding.medium:
        return const EdgeInsets.all(24);
      case CardPadding.large:
        return const EdgeInsets.all(32);
    }
  }

  List<BoxShadow> _getBoxShadow() {
    if (widget.boxShadow != null) return widget.boxShadow!;
    
    switch (widget.variant) {
      case CardVariant.defaultCard:
        return AppTheme.mediumShadow;
      case CardVariant.interactive:
        return AppTheme.mediumShadow;
      case CardVariant.glass:
        return AppTheme.softShadow;
      case CardVariant.solid:
        return AppTheme.largeShadow;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget card = AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: widget.width,
            height: widget.height,
            margin: widget.margin,
            padding: _getPadding(),
            decoration: BoxDecoration(
              color: _getBackgroundColor(),
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: Border.all(
                color: _getBorderColor(),
                width: 1,
              ),
              boxShadow: _getBoxShadow(),
            ),
            child: widget.child,
          ),
        );
      },
    );

    if (widget.onTap != null || widget.variant == CardVariant.interactive) {
      return GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) {
          if (widget.hover || widget.variant == CardVariant.interactive) {
            _animationController.forward();
          }
        },
        onTapUp: (_) {
          if (widget.hover || widget.variant == CardVariant.interactive) {
            _animationController.reverse();
          }
        },
        onTapCancel: () {
          if (widget.hover || widget.variant == CardVariant.interactive) {
            _animationController.reverse();
          }
        },
        child: card,
      );
    }

    return card;
  }
}

class CardHeader extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const CardHeader({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.only(bottom: 24),
      child: child,
    );
  }
}

class CardTitle extends StatelessWidget {
  final String title;
  final TextStyle? style;
  final Color? color;
  final FontWeight? fontWeight;
  final double? fontSize;

  const CardTitle({
    super.key,
    required this.title,
    this.style,
    this.color,
    this.fontWeight,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: style ?? Theme.of(context).textTheme.titleLarge?.copyWith(
        color: color ?? AppTheme.textPrimary,
        fontWeight: fontWeight ?? FontWeight.w600,
        fontSize: fontSize,
      ),
    );
  }
}

class CardContent extends StatelessWidget {
  final Widget child;
  final Color? textColor;

  const CardContent({
    super.key,
    required this.child,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: textColor ?? AppTheme.textSecondary,
      ) ?? const TextStyle(),
      child: child,
    );
  }
}

class CardFooter extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const CardFooter({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: padding ?? const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.only(top: 16),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppTheme.glassBorder,
            width: 1,
          ),
        ),
      ),
      child: child,
    );
  }
}