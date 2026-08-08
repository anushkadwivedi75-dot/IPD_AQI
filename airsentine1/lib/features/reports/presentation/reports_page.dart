import 'package:airsentine1/providers/app_state.dart';
import 'package:airsentine1/widgets/forecast_card.dart';
import 'package:airsentine1/widgets/section_title.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReportsPage extends ConsumerWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final station = ref.watch(selectedStationProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      appBar: AppBar(title: const Text('Reports & Forecast')),
      body: Padding(
        padding: EdgeInsets.all(isDesktop ? 28 : 16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(title: 'Station Insights', icon: Icons.analytics_outlined),
              const SizedBox(height: 14),
              Text('Deep dive into pollutant trends and 7-day AQI outlook for ${station.name}.', style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Forecast Overview', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 170,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: station.forecast.length,
                          itemBuilder: (context, index) => ForecastCard(forecast: station.forecast[index]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const SectionTitle(title: 'AQI Alert Summary', icon: Icons.report_gmailerrorred_outlined),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Today’s AQI: ${station.aqi}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 8),
                      Text('Primary pollutant: ${station.primaryPollutant}', style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 16),
                      Text('Expected air quality is stable with moderate particulate matter. Follow health guidance if you are sensitive.', style: const TextStyle(height: 1.5)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const SectionTitle(title: 'Health Recommendations', icon: Icons.health_and_safety),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: station.advice.map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Icon(item.icon, color: item.tint),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(item.description, style: const TextStyle(color: Colors.grey)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
