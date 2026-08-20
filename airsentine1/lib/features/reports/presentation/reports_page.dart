import 'package:airsentine1/features/ai_assistant/presentation/ai_assistant_page.dart';
import 'package:airsentine1/features/reports/presentation/widgets/reports_charts.dart';
import 'package:airsentine1/models/station.dart';
import 'package:airsentine1/providers/app_state.dart';
import 'package:airsentine1/widgets/cards.dart';
import 'package:airsentine1/widgets/forecast_card.dart';
import 'package:airsentine1/widgets/health_advice_card.dart';
import 'package:airsentine1/widgets/section_title.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReportsPage extends ConsumerWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final station = ref.watch(selectedStationProvider);
    final allStations = ref.watch(stationsListProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final aqiMeta = station.aqiMeta;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.assessment_outlined, color: isDark ? const Color(0xFF10B981) : const Color(0xFF0F9D58)),
            const SizedBox(width: 8),
            const Text('CPCB REPORTS & FORECAST INSIGHTS'),
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
                // Top Header Banner with Ask AI CTA
                _buildReportHeaderBanner(context, station, aqiMeta, isDark),
                const SizedBox(height: 24),

                // 1. 7-Day Forecast Cards Section
                const SectionTitle(title: '7-Day CPCB AQI Forecast Cards', icon: Icons.calendar_today),
                const SizedBox(height: 14),
                SizedBox(
                  height: 175,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: station.forecast.length,
                    itemBuilder: (context, index) => ForecastCard(forecast: station.forecast[index]),
                  ),
                ),
                const SizedBox(height: 24),

                // 2. Weekly Trend Line Chart (with mandatory accessible text summary)
                WeeklyTrendChartWidget(forecast: station.forecast),
                const SizedBox(height: 24),

                // 3. Multi-City Comparison Bar Chart (with mandatory accessible text summary)
                MultiCityBarChartWidget(stations: allStations),
                const SizedBox(height: 24),

                // 4. Health Recommendations Section
                const SectionTitle(title: 'Health Recommendations (CPCB)', icon: Icons.health_and_safety_outlined),
                const SizedBox(height: 14),
                Column(
                  children: station.advice.map((advice) => HealthAdviceCard(advice: advice)).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Top Banner for Reports Page with Ask AI Forecast Advice CTA
  Widget _buildReportHeaderBanner(BuildContext context, MonitoringStation station, AqiMeta aqiMeta, bool isDark) {
    return AppCardLg(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FORECAST REPORT FOR ${station.name.toUpperCase()} (${station.area.toUpperCase()})',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF78716C),
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${station.name.toUpperCase()} AIR INSIGHTS',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: isDark ? const Color(0xFFF5F2EB) : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'PRIMARY POLLUTANT: ${station.primaryPollutant} • CURRENT AQI: ${station.aqi} (${aqiMeta.label.toUpperCase()})',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFD6D3D1) : const Color(0xFF475569)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: aqiMeta.backgroundColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: aqiMeta.color.withValues(alpha: 0.5)),
                ),
                child: Text(
                  aqiMeta.label.toUpperCase(),
                  style: TextStyle(fontWeight: FontWeight.w900, color: aqiMeta.badgeTextColor, fontSize: 11, letterSpacing: 0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Ask AI Forecast Advice CTA
          Semantics(
            button: true,
            label: 'Ask AI Forecast Advice for ${station.name}',
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => showAiAssistantModal(context),
                icon: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                label: const Text(
                  'ASK AI FORECAST ADVICE',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.8),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xFF10B981) : const Color(0xFF0F9D58),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
