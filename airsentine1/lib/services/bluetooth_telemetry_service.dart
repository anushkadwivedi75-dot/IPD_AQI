import 'dart:async';
import 'dart:math';
import 'package:airsentine1/models/personal_telemetry.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

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
  final BluetoothDevice? rawDevice;

  const BluetoothDeviceItem({
    required this.id,
    required this.name,
    required this.rssi,
    this.isSimulator = false,
    this.rawDevice,
  });
}

class BluetoothTelemetryService {
  static final BluetoothTelemetryService instance = BluetoothTelemetryService._internal();
  BluetoothTelemetryService._internal();

  static final Guid serviceUuid = Guid('12345678-1234-5678-1234-56789abcdef0');
  static final Guid aqiCharUuid = Guid('12345678-1234-5678-1234-56789abcdef1');
  static final Guid humCharUuid = Guid('12345678-1234-5678-1234-56789abcdef2');
  static final Guid batCharUuid = Guid('12345678-1234-5678-1234-56789abcdef3');

  BluetoothConnectionStatus _status = BluetoothConnectionStatus.disconnected;
  BluetoothDeviceItem? _connectedDevice;
  BluetoothDevice? _connectedBleDevice;
  Timer? _simulationTimer;
  final List<StreamSubscription> _subscriptions = [];

  final _telemetryController = StreamController<PersonalTelemetry>.broadcast();
  final _statusController = StreamController<BluetoothConnectionStatus>.broadcast();

  String? _currentUserId = 'guest';

  int _latestAqi = 65;
  double _latestHumidity = 50.0;
  int _latestBattery = 100;

  BluetoothConnectionStatus get status => _status;
  BluetoothDeviceItem? get connectedDevice => _connectedDevice;
  int get batteryLevel => _latestBattery;
  Stream<PersonalTelemetry> get telemetryStream => _telemetryController.stream;
  Stream<BluetoothConnectionStatus> get statusStream => _statusController.stream;

  void setUserId(String userId) {
    _currentUserId = userId;
  }

  Future<List<BluetoothDeviceItem>> scanForDevices() async {
    _updateStatus(BluetoothConnectionStatus.scanning);
    final List<BluetoothDeviceItem> devices = [];

    try {
      if (!kIsWeb && defaultTargetPlatform != TargetPlatform.windows && defaultTargetPlatform != TargetPlatform.linux) {
        await FlutterBluePlus.startScan(
          withServices: [serviceUuid],
          timeout: const Duration(seconds: 4),
        );

        await FlutterBluePlus.isScanning.where((scanning) => !scanning).first;

        for (final r in FlutterBluePlus.lastScanResults) {
          final deviceName = r.device.platformName.isNotEmpty
              ? r.device.platformName
              : (r.advertisementData.advName.isNotEmpty ? r.advertisementData.advName : 'AirSentinel BLE Pod');
          devices.add(BluetoothDeviceItem(
            id: r.device.remoteId.str,
            name: deviceName,
            rssi: r.rssi,
            rawDevice: r.device,
            isSimulator: false,
          ));
        }
      }
    } catch (e) {
      debugPrint('Error during BLE scan: $e');
    }

    // Always append BLE-SIMULATOR fallback entry
    devices.add(
      const BluetoothDeviceItem(
        id: 'BLE-SIMULATOR',
        name: 'AirSentinel Virtual BLE Simulator',
        rssi: -30,
        isSimulator: true,
      ),
    );

    _updateStatus(BluetoothConnectionStatus.disconnected);
    return devices;
  }

  Future<bool> connectToDevice(BluetoothDeviceItem device) async {
    _updateStatus(BluetoothConnectionStatus.connecting);
    _connectedDevice = device;

    if (device.isSimulator || kIsWeb || defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux) {
      _updateStatus(BluetoothConnectionStatus.simulatorMode);
      _startSimulatorStream();
      return true;
    }

    try {
      final bleDevice = device.rawDevice ?? BluetoothDevice.fromId(device.id);
      _connectedBleDevice = bleDevice;

      await bleDevice.connect(autoConnect: false);

      final connSub = bleDevice.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _updateStatus(BluetoothConnectionStatus.disconnected);
        }
      });
      _subscriptions.add(connSub);

      final services = await bleDevice.discoverServices();
      BluetoothService? targetService;
      for (final s in services) {
        if (s.uuid == serviceUuid) {
          targetService = s;
          break;
        }
      }

      if (targetService != null) {
        for (final char in targetService.characteristics) {
          if (char.uuid == aqiCharUuid) {
            await char.setNotifyValue(true);
            final sub = char.onValueReceived.listen((bytes) {
              _onAqiReceived(bytes);
            });
            _subscriptions.add(sub);
          } else if (char.uuid == humCharUuid) {
            await char.setNotifyValue(true);
            final sub = char.onValueReceived.listen((bytes) {
              _onHumidityReceived(bytes);
            });
            _subscriptions.add(sub);
          } else if (char.uuid == batCharUuid) {
            await char.setNotifyValue(true);
            final sub = char.onValueReceived.listen((bytes) {
              _onBatteryReceived(bytes);
            });
            _subscriptions.add(sub);
          }
        }
      }

      _updateStatus(BluetoothConnectionStatus.connected);
      return true;
    } catch (e) {
      debugPrint('Error connecting to BLE device: $e');
      disconnect();
      return false;
    }
  }

  void disconnect() {
    _simulationTimer?.cancel();
    _simulationTimer = null;

    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();

    if (_connectedBleDevice != null) {
      _connectedBleDevice?.disconnect();
      _connectedBleDevice = null;
    }

    _connectedDevice = null;
    _updateStatus(BluetoothConnectionStatus.disconnected);
  }

  void _onAqiReceived(List<int> bytes) {
    if (bytes.length >= 2) {
      final bd = ByteData.sublistView(Uint8List.fromList(bytes));
      _latestAqi = bd.getUint16(0, Endian.little);
      _emitBleReading();
    }
  }

  void _onHumidityReceived(List<int> bytes) {
    if (bytes.length >= 4) {
      final bd = ByteData.sublistView(Uint8List.fromList(bytes));
      _latestHumidity = bd.getFloat32(0, Endian.little);
      _emitBleReading();
    }
  }

  void _onBatteryReceived(List<int> bytes) {
    if (bytes.isNotEmpty) {
      _latestBattery = bytes[0];
      _emitBleReading();
    }
  }

  void _emitBleReading() {
    final random = Random();
    final baseAqi = _latestAqi;
    final pm25 = (baseAqi * 0.45) + (random.nextDouble() * 2);
    final pm10 = (baseAqi * 0.85) + (random.nextDouble() * 3);
    final temp = 26.5 + (random.nextDouble() * 2 - 1);
    final hum = _latestHumidity;
    final hr = 72 + random.nextInt(10);

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
    disconnect();
    _telemetryController.close();
    _statusController.close();
  }
}

