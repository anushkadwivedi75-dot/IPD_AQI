import 'package:airsentine1/models/station.dart';
import 'package:airsentine1/widgets/cards.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Weekly Trend Line Chart Widget with Dark Tooltips & Accessible Text Alternative
class WeeklyTrendChartWidget extends StatefulWidget {
  final List<DailyForecast> forecast;

  const WeeklyTrendChartWidget({
    super.key,
    required this.forecast,
  });

  @override
  State<WeeklyTrendChartWidget> createState() => _WeeklyTrendChartWidgetState();
}

class _WeeklyTrendChartWidgetState extends State<WeeklyTrendChartWidget> {
  bool _showTable = false;

  @override
  Widget build(BuildContext context) {
    if (widget.forecast.isEmpty) {
      return const SizedBox();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF10B981) : const Color(0xFF0F9D58);
    final primaryTextColor = isDark ? const Color(0xFFF5F2EB) : const Color(0xFF0F172A);
    final summaryBg = isDark ? const Color(0xFF28231E) : const Color(0xFFF1F5F9);
    final summaryBorder = isDark ? const Color(0xFF38322B) : const Color(0xFFCBD5E1);

    final peakEntry = widget.forecast.reduce((a, b) => a.aqi > b.aqi ? a : b);
    final lowestEntry = widget.forecast.reduce((a, b) => a.aqi < b.aqi ? a : b);
    final peakMeta = getAqiMeta(peakEntry.aqi);
    final lowestMeta = getAqiMeta(lowestEntry.aqi);

    final summaryText =
        'Weekly Trend Summary: Forecast ranges from ${lowestEntry.aqi} (${lowestMeta.label}) to ${peakEntry.aqi} (${peakMeta.label}). Peak expected on ${peakEntry.label} (${peakEntry.condition}).';

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Title & View Mode Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.trending_up, color: primaryColor, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '7-DAY AQI FORECAST TREND',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.8, color: primaryTextColor),
                  ),
                ],
              ),
              Semantics(
                button: true,
                label: _showTable ? 'Switch to Line Chart View' : 'Switch to Data Table View',
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _showTable = !_showTable;
                    });
                  },
                  icon: Icon(_showTable ? Icons.show_chart : Icons.table_chart, size: 16, color: primaryColor),
                  label: Text(_showTable ? 'CHART VIEW' : 'TABLE VIEW', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 11)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // MANDATORY ACCESSIBLE TEXT ALTERNATIVE SUMMARY
          Semantics(
            liveRegion: true,
            label: summaryText,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: summaryBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: summaryBorder),
              ),
              child: Row(
                children: [
                  Icon(Icons.accessibility_new, color: primaryColor, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      summaryText,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? const Color(0xFFF5F2EB) : const Color(0xFF334155)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Render Line Chart or Table Alternative
          _showTable ? _buildDataTable(isDark, primaryTextColor) : _buildFlLineChart(context, primaryColor, isDark),
        ],
      ),
    );
  }

  Widget _buildFlLineChart(BuildContext context, Color primaryColor, bool isDark) {
    final spots = widget.forecast.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.aqi.toDouble());
    }).toList();

    final maxAqi = widget.forecast.map((e) => e.aqi).reduce((a, b) => a > b ? a : b).toDouble();

    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: (maxAqi + 40).clamp(100.0, 500.0),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: (isDark ? const Color(0xFF2E2924) : const Color(0xFFE2E8F0)).withValues(alpha: 0.5),
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
                  if (idx < 0 || idx >= widget.forecast.length) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      widget.forecast[idx].label,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFA8A29E) : const Color(0xFF64748B)),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (value, meta) => Text(
                  value.toInt().toString(),
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFA8A29E) : const Color(0xFF64748B)),
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
                  final aqi = spot.y.toInt();
                  final meta = getAqiMeta(aqi);
                  return LineTooltipItem(
                    'AQI $aqi\n${meta.label}',
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
              color: primaryColor,
              barWidth: 3.5,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  final meta = getAqiMeta(spot.y.toInt());
                  return FlDotCirclePainter(
                    radius: 5,
                    color: meta.color,
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

  Widget _buildDataTable(bool isDark, Color primaryTextColor) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(label: Text('DATE (IST)', style: TextStyle(fontWeight: FontWeight.w900, color: primaryTextColor))),
          DataColumn(label: Text('FORECAST AQI', style: TextStyle(fontWeight: FontWeight.w900, color: primaryTextColor))),
          DataColumn(label: Text('CPCB CATEGORY', style: TextStyle(fontWeight: FontWeight.w900, color: primaryTextColor))),
          DataColumn(label: Text('CONDITION', style: TextStyle(fontWeight: FontWeight.w900, color: primaryTextColor))),
        ],
        rows: widget.forecast.map((entry) {
          final meta = getAqiMeta(entry.aqi);
          return DataRow(
            cells: [
              DataCell(Text(entry.label, style: TextStyle(color: primaryTextColor))),
              DataCell(Text('${entry.aqi}', style: TextStyle(fontWeight: FontWeight.bold, color: primaryTextColor))),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: meta.backgroundColor, borderRadius: BorderRadius.circular(6)),
                  child: Text(meta.label.toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, color: meta.badgeTextColor, fontSize: 11)),
                ),
              ),
              DataCell(Text(entry.condition, style: TextStyle(color: primaryTextColor))),
            ],
          );
        }).toList(),
      ),
    );
  }
}

/// Multi-City Comparison Bar Chart Widget with Dynamic CPCB Colors & Accessible Text Summary
class MultiCityBarChartWidget extends StatefulWidget {
  final List<MonitoringStation> stations;

  const MultiCityBarChartWidget({
    super.key,
    required this.stations,
  });

  @override
  State<MultiCityBarChartWidget> createState() => _MultiCityBarChartWidgetState();
}

class _MultiCityBarChartWidgetState extends State<MultiCityBarChartWidget> {
  bool _showTable = false;

  @override
  Widget build(BuildContext context) {
    if (widget.stations.isEmpty) return const SizedBox();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF10B981) : const Color(0xFF0F9D58);
    final primaryTextColor = isDark ? const Color(0xFFF5F2EB) : const Color(0xFF0F172A);
    final summaryBg = isDark ? const Color(0xFF28231E) : const Color(0xFFF1F5F9);
    final summaryBorder = isDark ? const Color(0xFF38322B) : const Color(0xFFCBD5E1);

    final highest = widget.stations.reduce((a, b) => a.aqi > b.aqi ? a : b);
    final lowest = widget.stations.reduce((a, b) => a.aqi < b.aqi ? a : b);

    final summaryText =
        'Multi-City AQI Comparison: Highest air pollution in ${highest.name} (${highest.area}) at ${highest.aqi} (${highest.aqiMeta.label}). Lowest in ${lowest.name} (${lowest.area}) at ${lowest.aqi} (${lowest.aqiMeta.label}).';

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.bar_chart, color: primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'MULTI-CITY CPCB AQI COMPARISON',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.8, color: primaryTextColor),
                  ),
                ],
              ),
              Semantics(
                button: true,
                label: _showTable ? 'Switch to Bar Chart View' : 'Switch to Data Table View',
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _showTable = !_showTable;
                    });
                  },
                  icon: Icon(_showTable ? Icons.bar_chart : Icons.table_chart, size: 16, color: primaryColor),
                  label: Text(_showTable ? 'CHART VIEW' : 'TABLE VIEW', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 11)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // MANDATORY ACCESSIBLE TEXT SUMMARY
          Semantics(
            liveRegion: true,
            label: summaryText,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: summaryBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: summaryBorder),
              ),
              child: Row(
                children: [
                  Icon(Icons.accessibility_new, color: primaryColor, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      summaryText,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? const Color(0xFFF5F2EB) : const Color(0xFF334155)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          _showTable ? _buildCityTable(isDark, primaryTextColor) : _buildFlBarChart(context, isDark),
        ],
      ),
    );
  }

  Widget _buildFlBarChart(BuildContext context, bool isDark) {
    final maxAqi = widget.stations.map((s) => s.aqi).reduce((a, b) => a > b ? a : b).toDouble();

    return SizedBox(
      height: 240,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: (maxAqi + 50).clamp(100.0, 500.0),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (group) => const Color(0xFF0F172A),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final st = widget.stations[group.x.toInt()];
                final meta = st.aqiMeta;
                return BarTooltipItem(
                  '${st.area}\nAQI ${st.aqi} • ${meta.label}',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= widget.stations.length) return const SizedBox();
                  final city = widget.stations[idx].area;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      city.toUpperCase(),
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFA8A29E) : const Color(0xFF64748B)),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (val, meta) => Text(val.toInt().toString(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFA8A29E) : const Color(0xFF64748B))),
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(color: (isDark ? const Color(0xFF2E2924) : const Color(0xFFE2E8F0)).withValues(alpha: 0.5), strokeWidth: 1),
          ),
          barGroups: widget.stations.asMap().entries.map((entry) {
            final st = entry.value;
            final meta = st.aqiMeta;
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: st.aqi.toDouble(),
                  color: meta.color,
                  width: 18,
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(6)),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCityTable(bool isDark, Color primaryTextColor) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(label: Text('CITY / AREA', style: TextStyle(fontWeight: FontWeight.w900, color: primaryTextColor))),
          DataColumn(label: Text('STATION NAME', style: TextStyle(fontWeight: FontWeight.w900, color: primaryTextColor))),
          DataColumn(label: Text('CURRENT AQI', style: TextStyle(fontWeight: FontWeight.w900, color: primaryTextColor))),
          DataColumn(label: Text('CPCB CATEGORY', style: TextStyle(fontWeight: FontWeight.w900, color: primaryTextColor))),
          DataColumn(label: Text('PRIMARY POLLUTANT', style: TextStyle(fontWeight: FontWeight.w900, color: primaryTextColor))),
        ],
        rows: widget.stations.map((st) {
          final meta = st.aqiMeta;
          return DataRow(
            cells: [
              DataCell(Text(st.area, style: TextStyle(color: primaryTextColor))),
              DataCell(Text(st.name, style: TextStyle(color: primaryTextColor))),
              DataCell(Text('${st.aqi}', style: TextStyle(fontWeight: FontWeight.bold, color: primaryTextColor))),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: meta.backgroundColor, borderRadius: BorderRadius.circular(6)),
                  child: Text(meta.label.toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, color: meta.badgeTextColor, fontSize: 11)),
                ),
              ),
              DataCell(Text(st.primaryPollutant, style: TextStyle(color: primaryTextColor))),
            ],
          );
        }).toList(),
      ),
    );
  }
}
