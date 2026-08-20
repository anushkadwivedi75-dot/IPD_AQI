import 'package:airsentine1/models/station.dart';
import 'package:airsentine1/providers/app_state.dart';
import 'package:airsentine1/widgets/cards.dart';
import 'package:airsentine1/widgets/motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StationDetailPage extends ConsumerWidget {
  final String stationId;

  const StationDetailPage({
    super.key,
    required this.stationId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allStations = ref.watch(stationsListProvider);
    final station = allStations.firstWhere(
      (s) => s.id == stationId,
      orElse: () => ref.watch(selectedStationProvider),
    );
    final aqiMeta = getAqiMeta(station.aqi);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF10B981) : const Color(0xFF0F9D58);
    final titleTextColor = isDark ? const Color(0xFFF5F2EB) : const Color(0xFF0F172A);

    return PopScope(
      canPop: true,
      child: Semantics(
        container: true,
        scopesRoute: true,
        explicitChildNodes: true,
        label: 'Station Detail & ESP32 Telemetry Modal for ${station.name}',
        child: FadeScaleModal(
          child: Dialog.fullscreen(
            child: Scaffold(
              appBar: AppBar(
                title: Row(
                  children: [
                    Icon(Icons.location_on_outlined, color: primaryColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(station.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5)),
                          Text(station.area.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF78716C))),
                        ],
                      ),
                    ),
                  ],
                ),
                actions: [
                  Semantics(
                    button: true,
                    label: 'Close Station Detail Modal',
                    child: IconButton(
                      autofocus: true,
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Current AQI Hero Block & Category Badge
                        AppCardLg(
                          backgroundColor: aqiMeta.backgroundColor,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                alignment: WrapAlignment.spaceBetween,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Row(
                                    children: [
                                      PulsingDot(color: aqiMeta.dotColor, size: 12),
                                      const SizedBox(width: 8),
                                      Text(
                                        'CPCB STATION TELEMETRY',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 11,
                                          letterSpacing: 1.0,
                                          color: aqiMeta.badgeTextColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: aqiMeta.color,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      aqiMeta.label.toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 11,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    '${station.aqi}',
                                    style: TextStyle(
                                      fontSize: 60,
                                      fontWeight: FontWeight.w900,
                                      color: aqiMeta.badgeTextColor,
                                      height: 1.0,
                                      letterSpacing: -1.5,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'PRIMARY: ${station.primaryPollutant}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.8,
                                      color: aqiMeta.badgeTextColor.withValues(alpha: 0.9),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                station.summary,
                                style: TextStyle(fontSize: 13, color: aqiMeta.badgeTextColor.withValues(alpha: 0.9)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // 2. Hardware Specs Section (ESP32 Wearable Pendant)
                        Text(
                          'ESP32 WEARABLE PENDANT HARDWARE SPECS',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.8, color: titleTextColor),
                        ),
                        const SizedBox(height: 12),
                        _buildHardwareSpecsCard(isDark, primaryColor),
                        const SizedBox(height: 24),

                        // 3. Pollutant Readings with CPCB Safe-Limit Comparison
                        Text(
                          'POLLUTANT READINGS VS CPCB SAFE LIMITS',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.8, color: titleTextColor),
                        ),
                        const SizedBox(height: 12),
                        _buildSafeLimitsGrid(station, isDark),
                        const SizedBox(height: 28),

                        // 4. Bottom CTA: "Close Telemetry View"
                        Semantics(
                          button: true,
                          label: 'Close Telemetry View Button',
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                              label: const Text(
                                'CLOSE TELEMETRY VIEW',
                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.8, color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Hardware Specs Card for ESP32 Wearable Pendant
  Widget _buildHardwareSpecsCard(bool isDark, Color primaryColor) {
    final specs = [
      {'label': 'Device Node', 'value': 'ESP32 AirSentinel Pendant v2', 'icon': Icons.memory},
      {'label': 'Battery Level', 'value': '92% (LiPo 3.7V 1200mAh)', 'icon': Icons.battery_charging_full},
      {'label': 'Sensor Array', 'value': 'PMS7003 (PM) + SHT31 (Temp/Hum)', 'icon': Icons.sensors},
      {'label': 'Firmware', 'value': 'v2.4.1-cpcb-ind (OTA ready)', 'icon': Icons.system_update},
      {'label': 'BLE Sync Status', 'value': 'Connected (0.4s latency)', 'icon': Icons.bluetooth_connected},
    ];

    return AppCard(
      child: Column(
        children: specs.map((item) {
          final label = item['label'] as String;
          final value = item['value'] as String;
          final icon = item['icon'] as IconData;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: primaryColor, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF78716C), letterSpacing: 0.5)),
                      const SizedBox(height: 2),
                      Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? const Color(0xFFF5F2EB) : const Color(0xFF0F172A))),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Safe Limits Grid comparing station readings against CPCB standard limits
  Widget _buildSafeLimitsGrid(MonitoringStation station, bool isDark) {
    final safeLimits = {
      'PM2.5': {'limit': '60 µg/m³', 'desc': 'CPCB 24h standard limit'},
      'PM10': {'limit': '100 µg/m³', 'desc': 'CPCB 24h standard limit'},
      'NO2': {'limit': '80 µg/m³', 'desc': 'CPCB 24h standard limit'},
      'SO2': {'limit': '80 µg/m³', 'desc': 'CPCB 24h standard limit'},
      'CO': {'limit': '2 mg/m³', 'desc': 'CPCB 8h standard limit'},
    };

    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.7,
      children: station.pollutants.map((p) {
        final limitInfo = safeLimits[p.code] ?? {'limit': 'N/A', 'desc': 'CPCB Standard'};
        final limitStr = limitInfo['limit']!;
        final subIndex = p.subIndex ?? p.value.round();
        final meta = getAqiMeta(subIndex);

        return AppCard(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(p.code, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: isDark ? const Color(0xFFF5F2EB) : const Color(0xFF0F172A))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: meta.backgroundColor, borderRadius: BorderRadius.circular(8)),
                    child: Text(meta.label.toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, color: meta.badgeTextColor, fontSize: 9)),
                  ),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text('${p.value.round()}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: isDark ? const Color(0xFFF5F2EB) : const Color(0xFF0F172A))),
                  const SizedBox(width: 4),
                  Text(p.unit, style: const TextStyle(fontSize: 11, color: Color(0xFF78716C))),
                ],
              ),
              Text(
                'CPCB Safe Limit: $limitStr',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF78716C)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
