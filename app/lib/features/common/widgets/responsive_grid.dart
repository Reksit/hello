import 'package:flutter/material.dart';

class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int columns;
  final double spacing;
  final double runSpacing;
  final Map<String, int>? breakpoints;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.columns = 3,
    this.spacing = 16,
    this.runSpacing = 16,
    this.breakpoints,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Determine columns based on screen width
    int effectiveColumns = columns;
    
    if (breakpoints != null) {
      if (screenWidth < 600) {
        effectiveColumns = breakpoints!['sm'] ?? 1;
      } else if (screenWidth < 900) {
        effectiveColumns = breakpoints!['md'] ?? 2;
      } else if (screenWidth < 1200) {
        effectiveColumns = breakpoints!['lg'] ?? columns;
      } else {
        effectiveColumns = breakpoints!['xl'] ?? columns;
      }
    } else {
      // Default responsive behavior
      if (screenWidth < 600) {
        effectiveColumns = 1;
      } else if (screenWidth < 900) {
        effectiveColumns = 2;
      } else {
        effectiveColumns = columns;
      }
    }
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - (spacing * (effectiveColumns - 1))) / effectiveColumns;
        
        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: children.map((child) {
            return SizedBox(
              width: itemWidth,
              child: child,
            );
          }).toList(),
        );
      },
    );
  }
}

class ResponsiveGridPresets {
  static Widget responsive({
    required List<Widget> children,
    double spacing = 16,
    double runSpacing = 16,
  }) {
    return ResponsiveGrid(
      columns: 4,
      spacing: spacing,
      runSpacing: runSpacing,
      breakpoints: const {
        'sm': 2,
        'md': 3,
        'lg': 4,
      },
      children: children,
    );
  }

  static Widget twoColumn({
    required List<Widget> children,
    double spacing = 16,
    double runSpacing = 16,
  }) {
    return ResponsiveGrid(
      columns: 2,
      spacing: spacing,
      runSpacing: runSpacing,
      breakpoints: const {
        'sm': 1,
        'md': 2,
      },
      children: children,
    );
  }

  static Widget threeColumn({
    required List<Widget> children,
    double spacing = 16,
    double runSpacing = 16,
  }) {
    return ResponsiveGrid(
      columns: 3,
      spacing: spacing,
      runSpacing: runSpacing,
      breakpoints: const {
        'sm': 1,
        'md': 2,
        'lg': 3,
      },
      children: children,
    );
  }

  static Widget feature({
    required List<Widget> children,
    double spacing = 24,
    double runSpacing = 24,
  }) {
    return ResponsiveGrid(
      columns: 3,
      spacing: spacing,
      runSpacing: runSpacing,
      breakpoints: const {
        'sm': 1,
        'md': 2,
        'lg': 3,
      },
      children: children,
    );
  }

  static Widget stats({
    required List<Widget> children,
    double spacing = 16,
    double runSpacing = 16,
  }) {
    return ResponsiveGrid(
      columns: 4,
      spacing: spacing,
      runSpacing: runSpacing,
      breakpoints: const {
        'sm': 2,
        'md': 4,
      },
      children: children,
    );
  }

  static Widget cards({
    required List<Widget> children,
    double spacing = 24,
    double runSpacing = 24,
  }) {
    return ResponsiveGrid(
      columns: 3,
      spacing: spacing,
      runSpacing: runSpacing,
      breakpoints: const {
        'sm': 1,
        'md': 2,
        'lg': 3,
        'xl': 4,
      },
      children: children,
    );
  }
}