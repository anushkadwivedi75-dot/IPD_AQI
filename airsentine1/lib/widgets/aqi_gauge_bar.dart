import 'package:airsentine1/core/aqi_utils.dart';
import 'package:flutter/material.dart';

/// Horizontal CPCB Gauge Bar with multi-stop CPCB color gradient and dynamic marker position
class AqiGaugeBar extends StatelessWidget {
  final int aqi;

  const AqiGaugeBar({
    super.key,
    required this.aqi,
  });

  @override
  Widget build(BuildContext context) {
    final meta = getAqiMeta(aqi);
    final double percent = meta.gaugePercent.clamp(0.0, 100.0) / 100.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryTextColor = isDark ? const Color(0xFFA8A29E) : const Color(0xFF64748B);

    return Semantics(
      label: 'CPCB Air Quality Gauge: $aqi out of 500 (${(percent * 100).toStringAsFixed(0)}%), Category: ${meta.label}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CPCB AQI SCALE (0–500)',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                  color: secondaryTextColor,
                ),
              ),
              Text(
                '${(percent * 100).toStringAsFixed(0)}% OF MAX SCALE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                  color: meta.badgeTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final double barWidth = constraints.maxWidth;
              final double markerX = (barWidth * percent).clamp(8.0, barWidth - 8.0);

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // 1. CPCB Multi-stop Gradient Bar
                  Container(
                    height: 12,
                    width: barWidth,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF00B050), // Good 0-50
                          Color(0xFF7CB342), // Satisfactory 51-100
                          Color(0xFFFBC02D), // Moderate 101-200
                          Color(0xFFF57C00), // Poor 201-300
                          Color(0xFFD32F2F), // Very Poor 301-400
                          Color(0xFF70131B), // Severe 401-500
                        ],
                        stops: [0.10, 0.20, 0.40, 0.60, 0.80, 1.0],
                      ),
                    ),
                  ),

                  // 2. Dynamic Needle / Marker Pin
                  Positioned(
                    left: markerX - 8,
                    top: -4,
                    child: Container(
                      width: 16,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: meta.color, width: 3),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x33000000),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          // CPCB Scale Labels
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('0 GOOD', style: TextStyle(fontSize: 9, color: Color(0xFF00B050), fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              Text('100 SAT.', style: TextStyle(fontSize: 9, color: Color(0xFF7CB342), fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              Text('200 MOD.', style: TextStyle(fontSize: 9, color: Color(0xFFFBC02D), fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              Text('300 POOR', style: TextStyle(fontSize: 9, color: Color(0xFFF57C00), fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              Text('400 V.POOR', style: TextStyle(fontSize: 9, color: Color(0xFFD32F2F), fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              Text('500 SEVERE', style: TextStyle(fontSize: 9, color: Color(0xFF70131B), fontWeight: FontWeight.w900, letterSpacing: 0.5)),
            ],
          ),
        ],
      ),
    );
  }
}
