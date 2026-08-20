import 'package:airsentine1/models/personal_telemetry.dart';
import 'package:airsentine1/providers/auth_provider.dart';
import 'package:airsentine1/providers/telemetry_provider.dart';
import 'package:airsentine1/services/bluetooth_telemetry_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class PersonalDashboardPage extends ConsumerWidget {
  const PersonalDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final telemetryState = ref.watch(telemetryProvider);
    final isConnected = telemetryState.connectionStatus == BluetoothConnectionStatus.connected ||
        telemetryState.connectionStatus == BluetoothConnectionStatus.simulatorMode;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. User Profile Header Card
            _buildProfileBanner(context, ref, authState),
            const SizedBox(height: 20),

            // 2. Bluetooth Connection & Scanner Control
            _buildBluetoothControlCard(context, ref, telemetryState),
            const SizedBox(height: 20),

            if (isConnected && telemetryState.currentReading != null) ...[
              // 3. Live Telemetry Gauge & Real-time Metrics
              _buildLiveTelemetryGrid(context, telemetryState.currentReading!),
              const SizedBox(height: 20),

              // 4. Personalized Exposure Trend Chart
              _buildExposureChart(context, telemetryState.history),
              const SizedBox(height: 20),

              // 5. Health Advice Card
              _buildPersonalizedHealthAdvice(context, telemetryState.currentReading!),
              const SizedBox(height: 20),
            ] else if (!isConnected) ...[
              _buildDisconnectedState(context, ref),
              const SizedBox(height: 20),
            ],

            // 6. Saved Telemetry History Log
            _buildTelemetryLogTable(context, telemetryState.history),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileBanner(BuildContext context, WidgetRef ref, AuthState authState) {
    final user = authState.user;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: const Color(0xFF007791),
            child: Text(
              user != null ? user.name[0].toUpperCase() : 'G',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user != null ? 'Welcome, ${user.name}!' : 'Welcome, Guest User',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user != null
                      ? 'Personal Telemetry Dashboard • Logged in as ${user.email}'
                      : 'Sign in to sync your personal Bluetooth telemetry data across devices.',
                  style: TextStyle(color: Colors.grey[400], fontSize: 13),
                ),
              ],
            ),
          ),
          if (user != null)
            OutlinedButton.icon(
              onPressed: () => ref.read(authProvider.notifier).logout(),
              icon: const Icon(Icons.logout, size: 16, color: Colors.redAccent),
              label: const Text('Sign Out', style: TextStyle(color: Colors.redAccent)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.redAccent),
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: () => context.go('/login'),
              icon: const Icon(Icons.login, size: 16),
              label: const Text('Sign In'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007791),
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBluetoothControlCard(BuildContext context, WidgetRef ref, TelemetryState state) {
    final status = state.connectionStatus;
    final isConnected = status == BluetoothConnectionStatus.connected ||
        status == BluetoothConnectionStatus.simulatorMode;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.bluetooth_audio,
                      color: isConnected ? Colors.blue : Colors.grey,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bluetooth Telemetry Sensor',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          state.connectedDevice != null
                              ? 'Connected: ${state.connectedDevice!.name}'
                              : 'Status: ${status.name.toUpperCase()}',
                          style: TextStyle(
                            fontSize: 13,
                            color: isConnected ? Colors.green[700] : Colors.grey[600],
                            fontWeight: isConnected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (!isConnected)
                      ElevatedButton.icon(
                        onPressed: state.isScanning
                            ? null
                            : () => ref.read(telemetryProvider.notifier).scanDevices(),
                        icon: state.isScanning
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.search, size: 16),
                        label: Text(state.isScanning ? 'Scanning...' : 'Scan Bluetooth'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF007791),
                          foregroundColor: Colors.white,
                        ),
                      )
                    else
                      OutlinedButton.icon(
                        onPressed: () => ref.read(telemetryProvider.notifier).disconnectDevice(),
                        icon: const Icon(Icons.bluetooth_disabled, size: 16),
                        label: const Text('Disconnect'),
                      ),
                  ],
                ),
              ],
            ),
            if (state.availableDevices.isNotEmpty && !isConnected) ...[
              const Divider(height: 24),
              const Text(
                'Available Devices Nearby:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Column(
                children: state.availableDevices.map((device) {
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      device.isSimulator ? Icons.sensors_outlined : Icons.bluetooth,
                      color: const Color(0xFF007791),
                    ),
                    title: Text(device.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('ID: ${device.id} • Signal: ${device.rssi} dBm'),
                    trailing: ElevatedButton(
                      onPressed: () => ref.read(telemetryProvider.notifier).connectDevice(device),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF007791),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: const Text('Connect'),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLiveTelemetryGrid(BuildContext context, PersonalTelemetry telemetry) {
    final aqiColor = _getAqiColor(telemetry.aqi);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Live Personal Sensor Streams',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Card(
                color: aqiColor.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: aqiColor, width: 2),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text(
                        'PERSONAL AQI',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${telemetry.aqi}',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          color: aqiColor,
                        ),
                      ),
                      Text(
                        telemetry.aqiCategory,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: aqiColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildMetricTile('PM2.5', '${telemetry.pm25} µg/m³', Icons.air, Colors.orange),
                      const SizedBox(width: 12),
                      _buildMetricTile('PM10', '${telemetry.pm10} µg/m³', Icons.grain, Colors.deepOrange),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildMetricTile('Temperature', '${telemetry.temperature} °C', Icons.thermostat, Colors.blue),
                      const SizedBox(width: 12),
                      _buildMetricTile('Humidity', '${telemetry.humidity} %', Icons.water_drop, Colors.teal),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricTile(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  const SizedBox(height: 2),
                  Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExposureChart(BuildContext context, List<PersonalTelemetry> history) {
    if (history.isEmpty) return const SizedBox.shrink();

    final spots = history.reversed.toList().asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.aqi.toDouble());
    }).toList();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Personal AQI Exposure History Stream',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Real-time Bluetooth sensor stream history',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true, drawVerticalLine: false),
                  titlesData: const FlTitlesData(
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: const Color(0xFF007791),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xFF007791).withValues(alpha: 0.15),
                      ),
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

  Widget _buildPersonalizedHealthAdvice(BuildContext context, PersonalTelemetry telemetry) {
    String adviceText;
    IconData iconData;
    Color color;

    if (telemetry.aqi <= 50) {
      adviceText = 'Air quality is great! Ideal for outdoor activities and exercise.';
      iconData = Icons.sentiment_very_satisfied;
      color = Colors.green;
    } else if (telemetry.aqi <= 100) {
      adviceText = 'Air quality is acceptable. Sensitive individuals should consider limiting prolonged outdoor exertion.';
      iconData = Icons.sentiment_satisfied;
      color = Colors.amber.shade800;
    } else {
      adviceText = 'High personal pollutant exposure detected! Consider wearing an N95 mask and using an air purifier indoors.';
      iconData = Icons.warning_amber_rounded;
      color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(iconData, color: color, size: 36),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Personalized Health Recommendation',
                  style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(adviceText, style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisconnectedState(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.bluetooth_searching, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              const Text(
                'No Bluetooth Telemetry Device Connected',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Click "Scan Bluetooth" above to pair your personal AQI monitor or start the BLE Simulator.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.read(telemetryProvider.notifier).scanDevices(),
                icon: const Icon(Icons.search),
                label: const Text('Scan & Connect Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007791),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTelemetryLogTable(BuildContext context, List<PersonalTelemetry> history) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Personal Telemetry Log History (SQLite Cached)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (history.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: Text('No telemetry logs recorded yet.')),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: history.length > 10 ? 10 : history.length,
                separatorBuilder: (_, _) => const Divider(),
                itemBuilder: (context, index) {
                  final item = history[index];
                  final timeStr = DateFormat('MMM dd, yyyy • HH:mm:ss').format(item.timestamp);
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: _getAqiColor(item.aqi),
                      radius: 18,
                      child: Text(
                        '${item.aqi}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    title: Text('Personal AQI: ${item.aqi} (${item.aqiCategory})'),
                    subtitle: Text('$timeStr • PM2.5: ${item.pm25} µg/m³ • PM10: ${item.pm10} µg/m³'),
                    trailing: Icon(
                      item.isSynced ? Icons.cloud_done : Icons.cloud_upload_outlined,
                      size: 18,
                      color: item.isSynced ? Colors.green : Colors.grey,
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Color _getAqiColor(int aqi) {
    if (aqi <= 50) return Colors.green;
    if (aqi <= 100) return Colors.amber.shade700;
    if (aqi <= 150) return Colors.orange;
    if (aqi <= 200) return Colors.red;
    if (aqi <= 300) return Colors.purple;
    return Colors.brown;
  }
}
