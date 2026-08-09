import 'package:flutter/material.dart';

class SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const SectionTitle({
    super.key,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? const Color(0xFF10B981) : const Color(0xFF0F9D58);
    final textColor = isDark ? const Color(0xFFF5F2EB) : const Color(0xFF1C1917);

    return Semantics(
      header: true,
      label: title,
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
