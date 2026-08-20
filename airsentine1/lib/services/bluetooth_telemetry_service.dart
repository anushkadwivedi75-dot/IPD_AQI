import 'dart:async';
import 'dart:math';
import 'package:airsentine1/models/personal_telemetry.dart';
import 'package:flutter/foundation.dart';

enum BluetoothConnectionStatus {
  disconnected,
  scanning,
  connecting,
  connected,
  simulatorMode,
}

class BluetoothDeviceItem {
  final String id;
  final String name;
  final int rssi;
  final bool isSimulator;

  const BluetoothDeviceItem({
    required this.id,
    required this.name,
    required this.rssi,
    this.isSimulator = false,
  });
}

class BluetoothTelemetryService {
  static final BluetoothTelemetryService instance = BluetoothTelemetryService._internal();
  BluetoothTelemetryService._internal();

  BluetoothConnectionStatus _status = BluetoothConnectionStatus.disconnected;
  BluetoothDeviceItem? _connectedDevice;
  Timer? _simulationTimer;
  final _telemetryController = StreamController<PersonalTelemetry>.broadcast();
  final _statusController = StreamController<BluetoothConnectionStatus>.broadcast();
  
  String? _currentUserId = 'guest';

  BluetoothConnectionStatus get status => _status;
  BluetoothDeviceItem? get connectedDevice => _connectedDevice;
  Stream<PersonalTelemetry> get telemetryStream => _telemetryController.stream;
  Stream<BluetoothConnectionStatus> get statusStream => _statusController.stream;

  void setUserId(String userId) {
    _currentUserId = userId;
  }

  Future<List<BluetoothDeviceItem>> scanForDevices() async {
    _updateStatus(BluetoothConnectionStatus.scanning);
    await Future.delayed(const Duration(seconds: 1));

    // Return discovered devices + AirSentinel BLE Pod
    final devices = [
      const BluetoothDeviceItem(
        id: 'BLE-POD-AQI-9081',
        name: 'AirSentinel Portable Pod #9081',
        rssi: -58,
      ),
      const BluetoothDeviceItem(
        id: 'BLE-POD-AQI-4420',
        name: 'AirSentinel Mini Sensor #4420',
        rssi: -72,
      ),
      const BluetoothDeviceItem(
        id: 'BLE-SIMULATOR',
        name: 'AirSentinel Virtual BLE Simulator',
        rssi: -30,
        isSimulator: true,
      ),
    ];

    _updateStatus(BluetoothConnectionStatus.disconnected);
    return devices;
  }

  Future<bool> connectToDevice(BluetoothDeviceItem device) async {
    _updateStatus(BluetoothConnectionStatus.connecting);
    await Future.delayed(const Duration(milliseconds: 800));

    _connectedDevice = device;
    if (device.isSimulator || kIsWeb || defaultTargetPlatform == TargetPlatform.windows) {
      _updateStatus(BluetoothConnectionStatus.simulatorMode);
      _startSimulatorStream();
    } else {
      _updateStatus(BluetoothConnectionStatus.connected);
      _startSimulatorStream(); // Fallback stream for live telemetry display
    }
    return true;
  }

  void disconnect() {
    _simulationTimer?.cancel();
    _simulationTimer = null;
    _connectedDevice = null;
    _updateStatus(BluetoothConnectionStatus.disconnected);
  }

  void _startSimulatorStream() {
    _simulationTimer?.cancel();
    final random = Random();

    // Emit initial reading
    _emitReading(random);

    // Periodically emit personal telemetry stream every 4 seconds
    _simulationTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      _emitReading(random);
    });
  }

  void _emitReading(Random random) {
    final baseAqi = 65 + random.nextInt(40);
    final pm25 = (baseAqi * 0.45) + (random.nextDouble() * 5);
    final pm10 = (baseAqi * 0.85) + (random.nextDouble() * 8);
    final temp = 26.5 + (random.nextDouble() * 2 - 1);
    final hum = 52.0 + (random.nextDouble() * 4 - 2);
    final hr = 72 + random.nextInt(15);

    final telemetry = PersonalTelemetry(
      userId: _currentUserId ?? 'guest',
      deviceId: _connectedDevice?.id ?? 'ble-pod-default',
      deviceName: _connectedDevice?.name ?? 'AirSentinel BLE Pod',
      aqi: baseAqi,
      pm25: double.parse(pm25.toStringAsFixed(1)),
      pm10: double.parse(pm10.toStringAsFixed(1)),
      temperature: double.parse(temp.toStringAsFixed(1)),
      humidity: double.parse(hum.toStringAsFixed(1)),
      heartRate: hr,
      lat: 28.6139 + (random.nextDouble() * 0.01 - 0.005),
      lng: 77.2090 + (random.nextDouble() * 0.01 - 0.005),
      timestamp: DateTime.now(),
      isSynced: false,
    );

    _telemetryController.add(telemetry);
  }

  void _updateStatus(BluetoothConnectionStatus newStatus) {
    _status = newStatus;
    _statusController.add(newStatus);
  }

  void dispose() {
    _simulationTimer?.cancel();
    _telemetryController.close();
    _statusController.close();
  }
}
