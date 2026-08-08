import 'package:airsentine1/data/sample_data.dart';
import 'package:airsentine1/providers/app_state.dart';
import 'package:airsentine1/widgets/section_title.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertThreshold = ref.watch(alertThresholdProvider);
    final notificationsEnabled = ref.watch(notificationEnabledProvider);
    final useMetric = ref.watch(unitPreferenceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const SectionTitle(title: 'Preferences', icon: Icons.settings),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Notifications'),
                      subtitle: const Text('Receive AQI alerts and health suggestions'),
                      value: notificationsEnabled,
                      onChanged: (value) => ref.read(notificationEnabledProvider.notifier).setEnabled(value),
                    ),
                    const Divider(),
                    ListTile(
                      title: const Text('AQI Alert Threshold'),
                      subtitle: Text('$alertThreshold'),
                      trailing: Slider(
                        min: 50,
                        max: 200,
                        divisions: 15,
                        label: alertThreshold.toString(),
                        value: alertThreshold.toDouble(),
                        onChanged: (value) => ref.read(alertThresholdProvider.notifier).setThreshold(value.round()),
                      ),
                    ),
                    const Divider(),
                    SwitchListTile(
                      title: const Text('Use metric units'),
                      subtitle: const Text('Show temperature in Celsius and metric weather values'),
                      value: useMetric,
                      onChanged: (_) => ref.read(unitPreferenceProvider.notifier).toggleUnits(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const SectionTitle(title: 'Station Management', icon: Icons.favorite_outline),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Favorites allow quick access to your top stations.'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: stations.map((station) {
                        return Chip(
                          label: Text(station.name),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
