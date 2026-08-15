import 'package:airsentine1/models/alert.dart';
import 'package:flutter/material.dart';

class CommunityAlertBanner extends StatelessWidget {
  final AppAlert alert;
  final VoidCallback? onDismiss;

  const CommunityAlertBanner({
    super.key,
    required this.alert,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isDivergence = alert.type == 'divergence';
    final alertTitle = isDivergence
        ? 'Receive Community Alert: AQI Divergence'
        : 'Receive Community Alert: Anomaly Detected';

    final evidence = alert.evidence ?? {};
    final details = isDivergence
        ? 'Official AQI: ${evidence['official_aqi'] ?? 'N/A'} vs Community Median AQI: ${evidence['community_median_aqi'] ?? 'N/A'} (Δ ${evidence['divergence'] ?? '0'})'
        : 'IsolationForest score: ${evidence['anomaly_score'] ?? 'N/A'} (AQI: ${evidence['aqi'] ?? 'N/A'})';

    final bannerBg = isDark
        ? const Color(0xFF451A03).withValues(alpha: 0.9)
        : const Color(0xFFFEF3C7).withValues(alpha: 0.95);

    final borderColor = isDark
        ? const Color(0xFFF59E0B)
        : const Color(0xFFD97706);

    final textColor = isDark
        ? const Color(0xFFFDE68A)
        : const Color(0xFF92400E);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bannerBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor.withValues(alpha: 0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: borderColor.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: borderColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDivergence ? Icons.warning_amber_rounded : Icons.psychology_alt_rounded,
              color: borderColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  alertTitle,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  details,
                  style: TextStyle(
                    fontSize: 11,
                    color: textColor.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          if (onDismiss != null)
            IconButton(
              icon: Icon(Icons.close_rounded, size: 18, color: textColor),
              onPressed: onDismiss,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}
