import 'package:airsentine1/core/aqi_utils.dart';
import 'package:airsentine1/models/station.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class HistoryChart extends StatelessWidget {
  final List<HistoryEntry> history;

  const HistoryChart({
    super.key,
    required this.history,
  });

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const SizedBox(
        height: 220,
        child: Center(
          child: Text('No historical telemetry available', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final aqis = history.map((entry) => entry.aqi).toList();
    final maxAqi = aqis.reduce((a, b) => a > b ? a : b);
    final minAqi = aqis.reduce((a, b) => a < b ? a : b);
    final avgAqi = (aqis.reduce((a, b) => a + b) / aqis.length).round();

    final maxEntry = history.firstWhere((e) => e.aqi == maxAqi);
    final minEntry = history.firstWhere((e) => e.aqi == minAqi);

    final spots = history.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.aqi.toDouble());
    }).toList();

    final maxAqiVal = maxAqi.toDouble();
    final maxY = (maxAqiVal + 40.0).clamp(100.0, 500.0);

    // Calculate dynamic Y-axis interval
    final double yInterval;
    if (maxY > 300) {
      yInterval = 100;
    } else if (maxY > 150) {
      yInterval = 50;
    } else {
      yInterval = 25;
    }

    // Dynamic X-axis label interval so text doesn't overlap
    final double xInterval = (history.length / 6).ceil().toDouble().clamp(2.0, 4.0);

    final primaryColor = isDark ? const Color(0xFF10B981) : const Color(0xFF0F9D58);
    final secondaryColor = isDark ? const Color(0xFF34D399) : const Color(0xFF059669);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Summary Header Stat Badges
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildStatBadge(
              context,
              label: '24H AVG',
              value: '$avgAqi',
              color: getAqiMeta(avgAqi).color,
              icon: Icons.stacked_line_chart,
            ),
            _buildStatBadge(
              context,
              label: 'PEAK (${maxEntry.hour})',
              value: '$maxAqi',
              color: getAqiMeta(maxAqi).color,
              icon: Icons.arrow_upward_rounded,
            ),
            _buildStatBadge(
              context,
              label: 'MIN (${minEntry.hour})',
              value: '$minAqi',
              color: getAqiMeta(minAqi).color,
              icon: Icons.arrow_downward_rounded,
            ),
          ],
        ),
        const SizedBox(height: 20),

        // 2. Spacious Line Chart
        SizedBox(
          height: 280,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: maxY,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: yInterval,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
                  strokeWidth: 1,
                  dashArray: [4, 4],
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: yInterval,
                    reservedSize: 44,
                    getTitlesWidget: (value, meta) {
                      if (value < 0 || value > maxY) return const SizedBox();
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          value.toInt().toString(),
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFFA8A29E) : const Color(0xFF78716C),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: xInterval,
                    reservedSize: 36,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= history.length) return const SizedBox();
                      return Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          history[index].hour,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFFA8A29E) : const Color(0xFF78716C),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              lineTouchData: LineTouchData(
                enabled: true,
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (spot) => isDark ? const Color(0xFF26231F) : const Color(0xFF0F172A),
                  tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final index = spot.x.toInt();
                      final hourStr = (index >= 0 && index < history.length) ? history[index].hour : '';
                      final aqiVal = spot.y.toInt();
                      final meta = getAqiMeta(aqiVal);
                      return LineTooltipItem(
                        '$hourStr IST\nAQI $aqiVal • ${meta.label}',
                        TextStyle(
                          color: meta.color,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          height: 1.3,
                        ),
                      );
                    }).toList();
                  },
                ),
                handleBuiltInTouches: true,
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  curveSmoothness: 0.35,
                  gradient: LinearGradient(
                    colors: [primaryColor, secondaryColor],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  barWidth: 3.5,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      final meta = getAqiMeta(spot.y.toInt());
                      return FlDotCirclePainter(
                        radius: 4,
                        color: meta.color,
                        strokeWidth: 2,
                        strokeColor: isDark ? const Color(0xFF1C1917) : Colors.white,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        primaryColor.withValues(alpha: 0.28),
                        primaryColor.withValues(alpha: 0.0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatBadge(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF26231F) : const Color(0xFFF1F5F9);
    final labelColor = isDark ? const Color(0xFFA8A29E) : const Color(0xFF64748B);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                  color: labelColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
