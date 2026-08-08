import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:airsentine1/models/station.dart';

class HistoryChart extends StatelessWidget {
  final List<HistoryEntry> history;

  const HistoryChart({
    super.key,
    required this.history,
  });

  @override
  Widget build(BuildContext context) {
    final spots = history.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.aqi.toDouble());
    }).toList();

    final maxAqi = history.map((entry) => entry.aqi).reduce((a, b) => a > b ? a : b).toDouble();
    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxAqi + 20,
          gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withValues(alpha: 0.12), strokeWidth: 1)),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 2,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= history.length) return const SizedBox();
                  return Text(history[index].hour, style: const TextStyle(fontSize: 10));
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, interval: 25, reservedSize: 36, getTitlesWidget: (value, meta) {
                return Text(value.toInt().toString(), style: const TextStyle(fontSize: 10));
              }),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              gradient: LinearGradient(colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary]),
              barWidth: 4,
              dotData: FlDotData(show: true),
            )
          ],
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }
}
