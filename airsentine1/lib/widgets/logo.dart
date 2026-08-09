import 'package:flutter/material.dart';

enum LogoLayout { horizontal, compact }

/// Premium Futuristic AirSentinel Brand Logo Widget
class AirSentinelLogo extends StatelessWidget {
  final LogoLayout layout;
  final double iconSize;
  final bool showSubtag;

  const AirSentinelLogo({
    super.key,
    this.layout = LogoLayout.horizontal,
    this.iconSize = 42.0,
    this.showSubtag = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF10B981) : const Color(0xFF0F9D58);
    final accentCyan = isDark ? const Color(0xFF06B6D4) : const Color(0xFF0284C7);
    final textMainColor = isDark ? const Color(0xFFF5F2EB) : const Color(0xFF1C1917);

    // Multi-layered Shield & Wind Icon Mark
    final iconWidget = Container(
      width: iconSize,
      height: iconSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(iconSize * 0.3),
        gradient: LinearGradient(
          colors: [
            primaryColor,
            accentCyan,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.4),
            blurRadius: 14,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: accentCyan.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Shield Silhouette
          Icon(
            Icons.shield_rounded,
            color: Colors.white.withValues(alpha: 0.25),
            size: iconSize * 0.7,
          ),
          // Foreground Air / Wind Waves Icon
          Icon(
            Icons.air_rounded,
            color: Colors.white,
            size: iconSize * 0.52,
          ),
        ],
      ),
    );

    if (layout == LogoLayout.compact) {
      return Semantics(
        label: 'AirSentinel App Brand Logo',
        child: iconWidget,
      );
    }

    return Semantics(
      label: 'AirSentinel CPCB Air Quality Monitoring Brand Logo',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          iconWidget,
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: iconSize * 0.45,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.8,
                    color: textMainColor,
                  ),
                  children: [
                    const TextSpan(text: 'AIR'),
                    TextSpan(
                      text: 'SENTINEL',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              if (showSubtag) ...[
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (isDark ? const Color(0xFF28231E) : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: (isDark ? const Color(0xFF38322B) : const Color(0xFFE2E8F0)),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'CPCB LIVE • INDIA',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          color: Color(0xFF78716C),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
