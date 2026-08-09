import 'package:airsentine1/features/history/presentation/widgets/history_area_chart.dart';
import 'package:airsentine1/models/station.dart';
import 'package:airsentine1/providers/app_state.dart';
import 'package:airsentine1/widgets/cards.dart';
import 'package:airsentine1/widgets/section_title.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  HistoryMetric _selectedMetric = HistoryMetric.aqi;
  final TextEditingController _tableSearchController = TextEditingController();
  String _tableFilterQuery = '';

  @override
  void dispose() {
    _tableSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final station = ref.watch(selectedStationProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF10B981) : const Color(0xFF0F9D58);
    final primaryTextColor = isDark ? const Color(0xFFF5F2EB) : const Color(0xFF0F172A);
    final historyList = station.history;

    // Calculate KPI values
    final double avgAqi = historyList.isNotEmpty
        ? historyList.map((e) => e.aqi).reduce((a, b) => a + b) / historyList.length
        : 0;
    final peakEntry = historyList.isNotEmpty
        ? historyList.reduce((a, b) => a.aqi > b.aqi ? a : b)
        : const HourlyReading(hour: '00:00', aqi: 0);
    final lowestEntry = historyList.isNotEmpty
        ? historyList.reduce((a, b) => a.aqi < b.aqi ? a : b)
        : const HourlyReading(hour: '00:00', aqi: 0);

    final peakMeta = getAqiMeta(peakEntry.aqi);
    final lowestMeta = getAqiMeta(lowestEntry.aqi);

    // Filter telemetry rows based on search query
    final filteredHistory = historyList.where((entry) {
      if (_tableFilterQuery.isEmpty) return true;
      final q = _tableFilterQuery.toLowerCase();
      final meta = getAqiMeta(entry.aqi);
      return entry.hour.toLowerCase().contains(q) ||
          entry.aqi.toString().contains(q) ||
          meta.label.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.show_chart_outlined, color: primaryColor),
            const SizedBox(width: 8),
            const Text('24-HOUR TELEMETRY HISTORY (IST)'),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isDesktop ? 28 : 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section Title & Metric Selector Pill Group
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TELEMETRY FOR ${station.name.toUpperCase()} (${station.area.toUpperCase()})',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF78716C),
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '24-HOUR AIR QUALITY HISTORY',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                              color: isDark ? const Color(0xFFF5F2EB) : const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildMetricSelectorPills(isDark, primaryColor),
                  ],
                ),
                const SizedBox(height: 20),

                // 1. 3 KPI Cards (24h Average, Peak Value, Cleanest Hour)
                _buildKpiCardsRow(avgAqi, peakEntry, peakMeta, lowestEntry, lowestMeta),
                const SizedBox(height: 24),

                // 2. Gradient Area Chart
                AppCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.ssid_chart, color: primaryColor, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '24-HOUR ${_getMetricLabel(_selectedMetric)} GRADIENT AREA CHART',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.8),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      HistoryAreaChartWidget(
                        history: historyList,
                        pollutants: station.pollutants,
                        selectedMetric: _selectedMetric,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // 3. Accessible Search Filter & Semantic Telemetry DataTable Section
                const SectionTitle(title: 'Semantic Telemetry DataTable (IST)', icon: Icons.table_chart_outlined),
                const SizedBox(height: 12),
                const Text(
                  'Structured tabular telemetry data providing full screen-reader accessibility.',
                  style: TextStyle(color: Color(0xFF78716C), fontSize: 13),
                ),
                const SizedBox(height: 14),

                // Accessible Search / Filter Field
                Semantics(
                  label: 'Filter 24-Hour Telemetry Table by Time, AQI, or CPCB Category',
                  child: TextField(
                    controller: _tableSearchController,
                    onChanged: (val) {
                      setState(() {
                        _tableFilterQuery = val;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'FILTER TELEMETRY DATA',
                      hintText: 'Search by hour (e.g. 06:00) or category (e.g. Severe)...',
                      prefixIcon: Icon(Icons.filter_list, color: primaryColor),
                      suffixIcon: _tableFilterQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _tableSearchController.clear();
                                setState(() {
                                  _tableFilterQuery = '';
                                });
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: isDark ? const Color(0xFF28231E) : const Color(0xFFF1F5F9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: isDark ? const Color(0xFF38322B) : const Color(0xFFCBD5E1)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Semantic DataTable
                AppCard(
                  padding: const EdgeInsets.all(12),
                  child: _buildSemanticDataTable(filteredHistory, station.pollutants, isDark, primaryTextColor),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Metric Selector Connected Pill Buttons (AQI / PM2.5 / PM10)
  Widget _buildMetricSelectorPills(bool isDark, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF28231E) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF38322B) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPillButton('AQI', HistoryMetric.aqi, isDark, primaryColor),
          _buildPillButton('PM2.5', HistoryMetric.pm25, isDark, primaryColor),
          _buildPillButton('PM10', HistoryMetric.pm10, isDark, primaryColor),
        ],
      ),
    );
  }

  Widget _buildPillButton(String label, HistoryMetric metric, bool isDark, Color primaryColor) {
    final isSelected = _selectedMetric == metric;

    return Semantics(
      button: true,
      selected: isSelected,
      label: 'Select metric $label for history chart',
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedMetric = metric;
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
              letterSpacing: 0.5,
              color: isSelected ? Colors.white : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
            ),
          ),
        ),
      ),
    );
  }

  /// 3 KPI Cards Row: 24h Average, Peak Value, Cleanest Hour
  Widget _buildKpiCardsRow(
    double avgAqi,
    HourlyReading peakEntry,
    AqiMeta peakMeta,
    HourlyReading lowestEntry,
    AqiMeta lowestMeta,
  ) {
    final avgMeta = getAqiMeta(avgAqi.round());

    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = (constraints.maxWidth - 32) / 3;

        return Row(
          children: [
            // 1. 24h Average Card
            SizedBox(
              width: width,
              child: Semantics(
                label: '24-hour Average AQI: ${avgAqi.toStringAsFixed(0)}, Category ${avgMeta.label}',
                child: AppCard(
                  backgroundColor: avgMeta.backgroundColor,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('24H AVERAGE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5, color: avgMeta.badgeTextColor)),
                          Icon(Icons.functions, color: avgMeta.badgeTextColor, size: 18),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        avgAqi.toStringAsFixed(0),
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: avgMeta.badgeTextColor),
                      ),
                      const SizedBox(height: 4),
                      Text(avgMeta.label.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5, color: avgMeta.badgeTextColor)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // 2. Peak Value Card
            SizedBox(
              width: width,
              child: Semantics(
                label: '24-hour Peak AQI: ${peakEntry.aqi} at ${peakEntry.hour} IST, Category ${peakMeta.label}',
                child: AppCard(
                  backgroundColor: peakMeta.backgroundColor,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('PEAK READING', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5, color: peakMeta.badgeTextColor)),
                          Icon(Icons.trending_up, color: peakMeta.badgeTextColor, size: 18),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${peakEntry.aqi}',
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: peakMeta.badgeTextColor),
                      ),
                      const SizedBox(height: 4),
                      Text('AT ${peakEntry.hour} IST • ${peakMeta.label.toUpperCase()}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5, color: peakMeta.badgeTextColor)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // 3. Cleanest Hour Card
            SizedBox(
              width: width,
              child: Semantics(
                label: '24-hour Cleanest Reading: ${lowestEntry.aqi} at ${lowestEntry.hour} IST, Category ${lowestMeta.label}',
                child: AppCard(
                  backgroundColor: lowestMeta.backgroundColor,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('CLEANEST HOUR', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5, color: lowestMeta.badgeTextColor)),
                          Icon(Icons.eco_outlined, color: lowestMeta.badgeTextColor, size: 18),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${lowestEntry.aqi}',
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: lowestMeta.badgeTextColor),
                      ),
                      const SizedBox(height: 4),
                      Text('AT ${lowestEntry.hour} IST • ${lowestMeta.label.toUpperCase()}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5, color: lowestMeta.badgeTextColor)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Real Flutter Semantic DataTable for Telemetry
  Widget _buildSemanticDataTable(List<HourlyReading> history, List<PollutantDetail> pollutants, bool isDark, Color primaryTextColor) {
    if (history.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Center(child: Text('No telemetry records match your search filter.', style: TextStyle(color: primaryTextColor))),
      );
    }

    final pm25Val = pollutants.firstWhere((p) => p.code == 'PM2.5', orElse: () => const PollutantDetail(code: 'PM2.5', name: '', value: 45, unit: 'µg/m³', trend: '', description: '')).value;
    final pm10Val = pollutants.firstWhere((p) => p.code == 'PM10', orElse: () => const PollutantDetail(code: 'PM10', name: '', value: 95, unit: 'µg/m³', trend: '', description: '')).value;
    final no2Val = pollutants.firstWhere((p) => p.code == 'NO2', orElse: () => const PollutantDetail(code: 'NO2', name: '', value: 35, unit: 'µg/m³', trend: '', description: '')).value;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 24,
        columns: [
          DataColumn(label: Text('TIME (IST)', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: primaryTextColor))),
          DataColumn(label: Text('AQI', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: primaryTextColor))),
          DataColumn(label: Text('CPCB CATEGORY', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: primaryTextColor))),
          DataColumn(label: Text('PM2.5 (µg/m³)', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: primaryTextColor))),
          DataColumn(label: Text('PM10 (µg/m³)', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: primaryTextColor))),
          DataColumn(label: Text('NO₂ (µg/m³)', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: primaryTextColor))),
        ],
        rows: history.map((entry) {
          final meta = getAqiMeta(entry.aqi);
          final pm25Calculated = (pm25Val * (0.8 + (entry.aqi % 30) / 100)).toStringAsFixed(1);
          final pm10Calculated = (pm10Val * (0.85 + (entry.aqi % 25) / 100)).toStringAsFixed(1);
          final no2Calculated = (no2Val * (0.9 + (entry.aqi % 20) / 100)).toStringAsFixed(1);

          return DataRow(
            cells: [
              DataCell(Text(entry.hour, style: TextStyle(fontWeight: FontWeight.w600, color: primaryTextColor))),
              DataCell(Text('${entry.aqi}', style: TextStyle(fontWeight: FontWeight.w900, color: primaryTextColor))),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: meta.backgroundColor, borderRadius: BorderRadius.circular(8)),
                  child: Text(meta.label.toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, color: meta.badgeTextColor, fontSize: 10)),
                ),
              ),
              DataCell(Text(pm25Calculated, style: TextStyle(color: primaryTextColor))),
              DataCell(Text(pm10Calculated, style: TextStyle(color: primaryTextColor))),
              DataCell(Text(no2Calculated, style: TextStyle(color: primaryTextColor))),
            ],
          );
        }).toList(),
      ),
    );
  }

  String _getMetricLabel(HistoryMetric metric) {
    switch (metric) {
      case HistoryMetric.aqi:
        return 'AQI';
      case HistoryMetric.pm25:
        return 'PM2.5';
      case HistoryMetric.pm10:
        return 'PM10';
    }
  }
}
