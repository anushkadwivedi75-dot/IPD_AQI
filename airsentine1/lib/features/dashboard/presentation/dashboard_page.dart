import 'package:airsentine1/data/sample_data.dart';
import 'package:airsentine1/models/station.dart';
import 'package:airsentine1/providers/app_state.dart';
import 'package:airsentine1/widgets/forecast_card.dart';
import 'package:airsentine1/widgets/health_advice_card.dart';
import 'package:airsentine1/widgets/history_chart.dart';
import 'package:airsentine1/widgets/pollutant_card.dart';
import 'package:airsentine1/widgets/section_title.dart';
import 'package:airsentine1/widgets/station_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final station = ref.watch(selectedStationProvider);
    final favorites = ref.watch(favoriteStationIdsProvider);
    final aqiAlert = ref.watch(aqiAlarmProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AirSentinel'),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_outlined)),
          const SizedBox(width: 10),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: isDesktop ? 32 : 16, vertical: 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1300),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Good evening 👋', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Track your air quality, weather, and health insights in one place.', style: TextStyle(fontSize: 16, color: Colors.grey)),
                const SizedBox(height: 24),
                const SectionTitle(title: 'Stations', icon: Icons.location_city_outlined),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: stations.map((item) {
                    return StationChip(
                      station: item,
                      selected: item.id == station.id,
                      favorite: favorites.contains(item.id),
                      onTap: () { ref.read(selectedStationIdProvider.notifier).setStation(item.id); },
                      onFavoriteTap: () { ref.read(favoriteStationIdsProvider.notifier).toggleFavorite(item.id); },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 26),
                _buildOverviewCard(context, station, aqiAlert),
                const SizedBox(height: 24),
                isDesktop ? _buildDesktopLayout(context, station) : _buildMobileLayout(context, station),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewCard(BuildContext context, Station station, bool aqiAlert) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
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
                      Text('Current Air Quality', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey[700], letterSpacing: 0.8)),
                      const SizedBox(height: 8),
                      Text(station.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(station.summary, style: TextStyle(color: Colors.grey[700])),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(color: station.background, borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text('${station.aqi}', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: station.color)),
                      const SizedBox(height: 6),
                      Text(station.category.label, style: TextStyle(fontWeight: FontWeight.w700, color: station.color)),
                    ],
                  ),
                ),
              ],
            ),
            if (aqiAlert) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('AQI is above your configured threshold. Take extra care outdoors today.', style: TextStyle(color: Colors.orange.shade900)),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18),
            Wrap(
              runSpacing: 12,
              spacing: 12,
              children: [
                _buildSummaryChip(Icons.thermostat_outlined, '${station.weather.temperatureC}°C', 'Temperature'),
                _buildSummaryChip(Icons.water_drop_outlined, '${station.weather.humidity}%', 'Humidity'),
                _buildSummaryChip(Icons.air, station.primaryPollutant, 'Primary Pollutant'),
                _buildSummaryChip(Icons.calendar_today, station.weather.condition, 'Condition'),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryChip(IconData icon, String label, String subtitle) {
    return Chip(
      backgroundColor: Colors.grey.shade100,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      avatar: Icon(icon, size: 18, color: Colors.grey[700]),
      label: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, Station station) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 2, child: _buildLeftColumn(context, station)),
        const SizedBox(width: 20),
        Expanded(flex: 1, child: _buildRightColumn(context, station)),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context, Station station) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLeftColumn(context, station),
        const SizedBox(height: 20),
        _buildRightColumn(context, station),
      ],
    );
  }

  Widget _buildLeftColumn(BuildContext context, Station station) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: 'Pollutant Breakdown', icon: Icons.flare),
        const SizedBox(height: 14),
        GridView.count(
          shrinkWrap: true,
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.1,
          children: station.pollutants.map((pollutant) => PollutantCard(pollutant: pollutant)).toList(),
        ),
        const SizedBox(height: 24),
        const SectionTitle(title: '24-Hour History', icon: Icons.show_chart),
        const SizedBox(height: 14),
        Card(child: Padding(padding: const EdgeInsets.all(18), child: HistoryChart(history: station.history))),
      ],
    );
  }

  Widget _buildRightColumn(BuildContext context, Station station) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: 'Weekly Forecast', icon: Icons.cloud),
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
        const SectionTitle(title: 'Health Assistant', icon: Icons.health_and_safety_outlined),
        const SizedBox(height: 14),
        Column(
          children: station.advice.map((advice) => HealthAdviceCard(advice: advice)).toList(),
        ),
      ],
    );
  }
}
