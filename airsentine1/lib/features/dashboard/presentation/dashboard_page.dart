import 'package:airsentine1/models/station.dart';
import 'package:airsentine1/providers/app_state.dart';
import 'package:airsentine1/widgets/aqi_gauge_bar.dart';
import 'package:airsentine1/widgets/cards.dart';
import 'package:airsentine1/widgets/forecast_card.dart';
import 'package:airsentine1/widgets/header/app_header.dart';
import 'package:airsentine1/widgets/health_advice_card.dart';
import 'package:airsentine1/widgets/history_chart.dart';
import 'package:airsentine1/widgets/motion.dart';
import 'package:airsentine1/widgets/pollutant_card.dart';
import 'package:airsentine1/widgets/section_title.dart';
import 'package:airsentine1/widgets/station_quick_list.dart';
import 'package:airsentine1/widgets/weather_strip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final station = ref.watch(selectedStationProvider);
    final aqiMeta = station.aqiMeta;
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: const AirSentinelHeader(),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: isDesktop ? 32 : 16, vertical: 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1300),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section Title: Station Quick Picker
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SectionTitle(
                      title: 'CPCB Monitoring Stations',
                      icon: Icons.location_city_outlined,
                    ),
                    Semantics(
                      button: true,
                      label: 'View hardware information for ${station.name}',
                      child: TextButton.icon(
                        onPressed: () => context.push('/station/${station.id}'),
                        icon: Icon(Icons.developer_board, size: 16, color: isDark ? const Color(0xFF10B981) : const Color(0xFF0F9D58)),
                        label: Text(
                          'HARDWARE INFO',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                            letterSpacing: 0.8,
                            color: isDark ? const Color(0xFF10B981) : const Color(0xFF0F9D58),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 1. Station Quick List (Scrollable cards with scale animation)
                const StationQuickList(),
                const SizedBox(height: 24),

                // 2. AQI Hero Card
                _buildAqiHeroCard(context, station, aqiMeta, isDark),
                const SizedBox(height: 24),

                // 3. 4-Card Weather Strip
                WeatherStrip(weather: station.weather),
                const SizedBox(height: 24),

                // Desktop vs Mobile Split Layout
                isDesktop ? _buildDesktopLayout(context, station) : _buildMobileLayout(context, station),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// AQI Hero Card with huge numeric value, category badge, and CPCB horizontal gauge bar
  Widget _buildAqiHeroCard(BuildContext context, MonitoringStation station, AqiMeta aqiMeta, bool isDark) {
    final titleTextColor = isDark ? const Color(0xFFF5F2EB) : const Color(0xFF0F172A);

    return Semantics(
      label: 'Current Air Quality Hero for ${station.name} in ${station.area}. AQI is ${station.aqi}, CPCB Category: ${aqiMeta.label}. Summary: ${station.summary}',
      child: AppCardLg(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Location Header & AQI Numeric Callout
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          PulsingDot(color: aqiMeta.dotColor, size: 10),
                          const SizedBox(width: 8),
                          const Text(
                            'LIVE CPCB AIR QUALITY INDEX',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                              color: Color(0xFF78716C),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            station.name.toUpperCase(),
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                              color: titleTextColor,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Semantics(
                            button: true,
                            label: 'Station detail modal for ${station.name}',
                            child: IconButton(
                              icon: Icon(Icons.open_in_new, size: 18, color: isDark ? const Color(0xFF10B981) : const Color(0xFF0F9D58)),
                              tooltip: 'Station Detail',
                              onPressed: () => context.push('/station/${station.id}'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${station.area.toUpperCase()} • UPDATED IST • PRIMARY: ${station.primaryPollutant}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.6, color: Color(0xFF78716C)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        station.summary,
                        style: TextStyle(fontSize: 13, color: isDark ? const Color(0xFFD6D3D1) : const Color(0xFF334155)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // Huge AQI Number Block
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                  decoration: BoxDecoration(
                    color: aqiMeta.backgroundColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: aqiMeta.color.withValues(alpha: 0.4), width: 1.5),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${station.aqi}',
                        style: TextStyle(
                          fontSize: 52,
                          fontWeight: FontWeight.w900,
                          color: aqiMeta.badgeTextColor,
                          height: 1.0,
                          letterSpacing: -1.0,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: aqiMeta.color,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          aqiMeta.label.toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            fontSize: 11,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            Divider(color: isDark ? const Color(0xFF2E2924) : const Color(0xFFE2E8F0)),
            const SizedBox(height: 16),

            // Horizontal CPCB Gauge Bar
            AqiGaugeBar(aqi: station.aqi),
          ],
        ),
      ),
    );
  }

  /// AI Advisory Card (`AppCardAccent` dark gradient) with health guidance and Consult Gemini Copilot CTA
  Widget _buildAiAdvisoryCard(BuildContext context, MonitoringStation station) {
    final aqiMeta = station.aqiMeta;

    return Semantics(
      label: 'AI Health Advisory Card: ${aqiMeta.healthAdvisory}',
      child: AppCardAccent(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const BouncingAlertIcon(
                  icon: Icons.auto_awesome,
                  color: Colors.amberAccent,
                  size: 24,
                ),
                const SizedBox(width: 10),
                const Text(
                  'CPCB AI HEALTH GUIDANCE',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    aqiMeta.label.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                      color: Colors.amberAccent,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              aqiMeta.healthAdvisory,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFFE2E8F0),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),

            // Full-Width CTA "Consult Gemini Copilot"
            Semantics(
              button: true,
              label: 'Consult Gemini Copilot for personalized air health advice',
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/ai-assistant'),
                  icon: const Icon(Icons.auto_awesome, size: 18, color: Color(0xFF0F172A)),
                  label: const Text(
                    'CONSULT GEMINI COPILOT',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 0.8,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0F172A),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, MonitoringStation station) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 2, child: _buildLeftColumn(context, station)),
        const SizedBox(width: 24),
        Expanded(flex: 1, child: _buildRightColumn(context, station)),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context, MonitoringStation station) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLeftColumn(context, station),
        const SizedBox(height: 24),
        _buildRightColumn(context, station),
      ],
    );
  }

  Widget _buildLeftColumn(BuildContext context, MonitoringStation station) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pollutant Breakdown Grid
        const SectionTitle(title: 'Pollutant Breakdown (CPCB)', icon: Icons.flare),
        const SizedBox(height: 14),
        GridView.count(
          shrinkWrap: true,
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.25,
          children: station.pollutants.map((pollutant) => PollutantCard(pollutant: pollutant)).toList(),
        ),
        const SizedBox(height: 24),

        // 24-Hour History Chart
        const SectionTitle(title: '24-Hour AQI Trend (IST)', icon: Icons.show_chart),
        const SizedBox(height: 14),
        AppCard(
          padding: const EdgeInsets.all(18),
          child: HistoryChart(history: station.history),
        ),
      ],
    );
  }

  Widget _buildRightColumn(BuildContext context, MonitoringStation station) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // AI Advisory Card
        _buildAiAdvisoryCard(context, station),
        const SizedBox(height: 24),

        // 7-Day Forecast
        const SectionTitle(title: '7-Day CPCB Forecast', icon: Icons.cloud),
        const SizedBox(height: 14),
        SizedBox(
          height: 170,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: station.forecast.length,
            itemBuilder: (context, index) => ForecastCard(forecast: station.forecast[index]),
          ),
        ),
        const SizedBox(height: 24),

        // CPCB Health Recommendations
        const SectionTitle(title: 'Health Recommendations', icon: Icons.health_and_safety_outlined),
        const SizedBox(height: 14),
        Column(
          children: station.advice.map((advice) => HealthAdviceCard(advice: advice)).toList(),
        ),
      ],
    );
  }
}
