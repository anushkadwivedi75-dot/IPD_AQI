import 'package:airsentine1/providers/app_state.dart';
import 'package:airsentine1/widgets/history_chart.dart';
import 'package:airsentine1/widgets/section_title.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final station = ref.watch(selectedStationProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      appBar: AppBar(title: const Text('24-Hour History')),
      body: Padding(
        padding: EdgeInsets.all(isDesktop ? 28 : 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle(title: 'Historic AQI', icon: Icons.history),
                const SizedBox(height: 12),
                const Text('Review the last 24 hours of air quality data for the selected station.', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: HistoryChart(history: station.history),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    _buildStatCard('Peak AQI', station.history.map((e) => e.aqi).reduce((a, b) => a > b ? a : b).toString(), Colors.red.shade100),
                    const SizedBox(width: 16),
                    _buildStatCard('Lowest AQI', station.history.map((e) => e.aqi).reduce((a, b) => a < b ? a : b).toString(), Colors.green.shade100),
                  ],
                ),
                const SizedBox(height: 24),
                const SectionTitle(title: 'Observations', icon: Icons.lightbulb_outline),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: const Text('AQI rose during afternoon traffic and cooled off later in the evening, indicating stronger emissions during peak commute hours.'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color background) {
    return Expanded(
      child: Card(
        color: background,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
