import 'package:airsentine1/data/sample_data.dart';
import 'package:airsentine1/providers/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MapPage extends ConsumerWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedStation = ref.watch(selectedStationProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      appBar: AppBar(title: const Text('Air Quality Map')),
      body: Padding(
        padding: EdgeInsets.all(isDesktop ? 28 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Interactive Map', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Select a station marker to view its current AQI status.'),
            const SizedBox(height: 20),
            Expanded(
              child: Card(
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: selectedStation.location,
                    initialZoom: 12,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                    ),
                    MarkerLayer(
                      markers: stations.map((station) {
                        return Marker(
                          width: 52,
                          height: 52,
                          point: station.location,
                          child: GestureDetector(
                            onTap: () => ref.read(selectedStationIdProvider.notifier).setStation(station.id),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: station.id == selectedStation.id ? 38 : 30,
                                  color: station.color,
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [BoxShadow(color: Colors.black.withAlpha(31), blurRadius: 6)],
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  child: Text(station.name, style: const TextStyle(fontSize: 10)),
                                ),
                              ],
                            ),
                          ),
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
