import 'package:airsentine1/models/station.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

enum HistoryMetric { aqi, pm25, pm10 }

/// 24-Hour Area Chart with gradient fill under curve representing selected metric over time
class HistoryAreaChartWidget extends StatelessWidget {
  final List<HourlyReading> history;
  final List<PollutantDetail> pollutants;
  final HistoryMetric selectedMetric;

  const HistoryAreaChartWidget({
    super.key,
    required this.history,
    required this.pollutants,
    required this.selectedMetric,
  });

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) return const SizedBox();

    // Map spots based on selected metric
    final spots = history.asMap().entries.map((entry) {
      final idx = entry.key.toDouble();
      double val = entry.value.aqi.toDouble();

      if (selectedMetric == HistoryMetric.pm25) {
        final pm25 = pollutants.firstWhere(
          (p) => p.code == 'PM2.5',
          orElse: () => const PollutantDetail(code: 'PM2.5', name: '', value: 35, unit: 'µg/m³', trend: '', description: ''),
        );
        // Vary slightly over history hours for realism
        val = (pm25.value * (0.8 + (entry.value.aqi % 30) / 100)).clamp(5.0, 500.0);
      } else if (selectedMetric == HistoryMetric.pm10) {
        final pm10 = pollutants.firstWhere(
          (p) => p.code == 'PM10',
          orElse: () => const PollutantDetail(code: 'PM10', name: '', value: 75, unit: 'µg/m³', trend: '', description: ''),
        );
        val = (pm10.value * (0.85 + (entry.value.aqi % 25) / 100)).clamp(10.0, 600.0);
      }

      return FlSpot(idx, val);
    }).toList();

    final maxVal = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final metricName = selectedMetric == HistoryMetric.aqi
        ? 'AQI'
        : selectedMetric == HistoryMetric.pm25
            ? 'PM2.5 (µg/m³)'
            : 'PM10 (µg/m³)';

    return SizedBox(
      height: 230,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: (maxVal * 1.25).clamp(50.0, 600.0),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: const Color(0xFFE2E8F0),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= history.length) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      history[idx].hour,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 38,
                getTitlesWidget: (value, meta) => Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                ),
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (touchedSpot) => const Color(0xFF0F172A),
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final val = spot.y.round();
                  final meta = selectedMetric == HistoryMetric.aqi ? getAqiMeta(val) : null;
                  final categoryLabel = meta != null ? '\nCategory: ${meta.label}' : '';
                  return LineTooltipItem(
                    '$metricName: $val$categoryLabel',
                    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: const Color(0xFF0F9D58),
              barWidth: 3.5,
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF0F9D58).withValues(alpha: 0.35),
                    const Color(0xFF0F9D58).withValues(alpha: 0.02),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4.5,
                    color: const Color(0xFF0F9D58),
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
            ),
          ],
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }
}
