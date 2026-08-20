import 'dart:async';
import 'package:airsentine1/data/local_db.dart';
import 'package:airsentine1/models/personal_telemetry.dart';
import 'package:airsentine1/services/bluetooth_telemetry_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TelemetryState {
  final BluetoothConnectionStatus connectionStatus;
  final BluetoothDeviceItem? connectedDevice;
  final List<BluetoothDeviceItem> availableDevices;
  final PersonalTelemetry? currentReading;
  final List<PersonalTelemetry> history;
  final bool isScanning;

  const TelemetryState({
    this.connectionStatus = BluetoothConnectionStatus.disconnected,
    this.connectedDevice,
    this.availableDevices = const [],
    this.currentReading,
    this.history = const [],
    this.isScanning = false,
  });

  TelemetryState copyWith({
    BluetoothConnectionStatus? connectionStatus,
    BluetoothDeviceItem? connectedDevice,
    bool clearDevice = false,
    List<BluetoothDeviceItem>? availableDevices,
    PersonalTelemetry? currentReading,
    List<PersonalTelemetry>? history,
    bool? isScanning,
  }) {
    return TelemetryState(
      connectionStatus: connectionStatus ?? this.connectionStatus,
      connectedDevice: clearDevice ? null : (connectedDevice ?? this.connectedDevice),
      availableDevices: availableDevices ?? this.availableDevices,
      currentReading: currentReading ?? this.currentReading,
      history: history ?? this.history,
      isScanning: isScanning ?? this.isScanning,
    );
  }
}

class TelemetryNotifier extends StateNotifier<TelemetryState> {
  final BluetoothTelemetryService _bleService = BluetoothTelemetryService.instance;
  StreamSubscription<PersonalTelemetry>? _telemetrySub;
  StreamSubscription<BluetoothConnectionStatus>? _statusSub;

  TelemetryNotifier() : super(const TelemetryState()) {
    _init();
  }

  void _init() {
    _loadHistory();

    _statusSub = _bleService.statusStream.listen((status) {
      state = state.copyWith(
        connectionStatus: status,
        connectedDevice: _bleService.connectedDevice,
      );
    });

    _telemetrySub = _bleService.telemetryStream.listen((telemetry) async {
      // Save reading to local SQLite DB
      await LocalDb.instance.insertPersonalTelemetry(telemetry);

      // Prepend reading to local history list
      final updatedHistory = [telemetry, ...state.history];
      if (updatedHistory.length > 50) {
        updatedHistory.removeLast();
      }

      state = state.copyWith(
        currentReading: telemetry,
        history: updatedHistory,
      );
    });
  }

  Future<void> _loadHistory() async {
    final historyList = await LocalDb.instance.getPersonalTelemetryHistory(limit: 50);
    state = state.copyWith(
      history: historyList,
      currentReading: historyList.isNotEmpty ? historyList.first : null,
    );
  }

  Future<void> scanDevices() async {
    state = state.copyWith(isScanning: true);
    final devices = await _bleService.scanForDevices();
    state = state.copyWith(
      availableDevices: devices,
      isScanning: false,
    );
  }

  Future<bool> connectDevice(BluetoothDeviceItem device) async {
    return await _bleService.connectToDevice(device);
  }

  void disconnectDevice() {
    _bleService.disconnect();
    state = state.copyWith(
      clearDevice: true,
      connectionStatus: BluetoothConnectionStatus.disconnected,
    );
  }

  @override
  void dispose() {
    _telemetrySub?.cancel();
    _statusSub?.cancel();
    super.dispose();
  }
}

final telemetryProvider = StateNotifierProvider<TelemetryNotifier, TelemetryState>((ref) {
  return TelemetryNotifier();
});
