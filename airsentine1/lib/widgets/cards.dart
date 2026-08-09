import 'package:airsentine1/core/design_tokens.dart';
import 'package:flutter/material.dart';

/// Standard App Card adapting dynamically to Light and Dark Theme Modes
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Border? border;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.backgroundColor,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBg = isDark ? const Color(0xFF1E1B18) : Colors.white;
    final defaultBorderColor = isDark ? const Color(0xFF2E2924) : const Color(0xFFEBE5DF);

    final content = Container(
      padding: padding ?? const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: backgroundColor ?? defaultBg,
        borderRadius: AppRadius.lgBorder,
        boxShadow: AppShadows.card,
        border: border ?? Border.all(color: defaultBorderColor, width: 1),
      ),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: AppRadius.lgBorder,
        child: content,
      );
    }
    return content;
  }
}

/// Large Card with extra padding and rounded XL corners adapting to Theme Mode
class AppCardLg extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;

  const AppCardLg({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBg = isDark ? const Color(0xFF1E1B18) : Colors.white;
    final defaultBorderColor = isDark ? const Color(0xFF332E29) : const Color(0xFFE2E8F0);

    final content = Container(
      padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: backgroundColor ?? defaultBg,
        borderRadius: AppRadius.xlBorder,
        boxShadow: AppShadows.cardElevated,
        border: Border.all(color: defaultBorderColor, width: 1),
      ),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: AppRadius.xlBorder,
        child: content,
      );
    }
    return content;
  }
}

/// Dark Accent Card with dark gradient background & crisp white text
class AppCardAccent extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Gradient? gradient;

  const AppCardAccent({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: gradient ?? AppGradients.darkAccent,
        borderRadius: AppRadius.xlBorder,
        boxShadow: AppShadows.cardElevated,
      ),
      child: DefaultTextStyle(
        style: const TextStyle(color: Colors.white),
        child: child,
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: AppRadius.xlBorder,
        child: content,
      );
    }
    return content;
  }
}
