import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

/// HTTP protocol: GET /status and POST /command {"command":"FORWARD"}.
/// BLE: discovers the ESP32's writable GATT characteristic; its UUID depends
/// on the installed ESP32 firmware and can be selected from Settings.
class RobotController extends ChangeNotifier {
  String ipAddress = '192.168.4.1';
  String bleName = 'RoboCar_BLE';
  bool demoPreview = true;
  bool connecting = false;
  bool scanning = false;
  bool runningProgram = false;
  String? error;
  ConnectionMode mode = ConnectionMode.none;
  String lastCommand = 'STOP';
  double speed = 60;
  double targetDistance = 100;
  double adjustedSetpoint = 102.78;
  double? distance;
  double? roll;
  double? pitch;
  double? yaw;
  double? battery;
  int? trial;
  String? robotMode;
  final List<double> distanceHistory = [];
  final List<DateTime> distanceTimes = [];
  final List<double> yawHistory = [];
  final List<DateTime> yawTimes = [];
  final List<ScanResult> devices = [];
  final List<BluetoothCharacteristic> writableCharacteristics = [];
  BluetoothDevice? bleDevice;
  BluetoothCharacteristic? bleWriteCharacteristic;
  Timer? _poller;
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<BluetoothConnectionState>? _bleStateSubscription;
  bool _programCancelled = false;
  bool _fetchInProgress = false;
  int _failedPolls = 0;
  Future<void> _lastCommandWrite = Future<void>.value();
  final HttpClient _client = HttpClient()..connectionTimeout = const Duration(seconds: 3);

  bool get connected => mode != ConnectionMode.none;
  bool get isDemo => !connected && demoPreview;
  String get statusLabel => mode == ConnectionMode.wifi
      ? 'Wi-Fi Connected'
      : mode == ConnectionMode.ble
          ? 'BLE Connected'
          : demoPreview
              ? 'Preview Mode'
              : 'Disconnected';
  double? get shownDistance => isDemo ? 102.78 : distance;
  double? get shownRoll => isDemo ? 1.2 : roll;
  double? get shownPitch => isDemo ? -0.8 : pitch;
  double? get shownYaw => isDemo ? 47.6 : yaw;
  double? get shownBattery => isDemo ? 78 : battery;
  List<double> get shownDistanceHistory => isDemo
      ? List.generate(32, (i) => 97 + 0.32 * i + 5 * sin(i * 0.70))
      : distanceHistory;
  List<double> get shownYawHistory => isDemo
      ? List.generate(32, (i) => 26 + 0.6 * i + 5 * sin(i * 0.46))
      : yawHistory;

  void setIp(String value) {
    ipAddress = value.trim().replaceAll('http://', '').replaceAll('https://', '').replaceAll(RegExp(r'/$'), '');
    notifyListeners();
  }

  void setBleName(String name) { bleName = name.trim(); notifyListeners(); }
  void setSpeed(double value) { speed = value; notifyListeners(); }
  void setTarget(double value) { targetDistance = value; notifyListeners(); }
  void setPreview(bool value) { demoPreview = value; notifyListeners(); }
  void clearError() { error = null; notifyListeners(); }

  Uri _uri(String path) => Uri.parse('http://$ipAddress$path');

  Future<Map<String, dynamic>> _request(String method, String path, [Map<String, dynamic>? body]) async {
    final request = await _client.openUrl(method, _uri(path)).timeout(const Duration(seconds: 4));
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    if (body != null) {
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(body));
    }
    final response = await request.close().timeout(const Duration(seconds: 5));
    final data = await utf8.decoder.bind(response).join().timeout(const Duration(seconds: 5));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException('HTTP ${response.statusCode} from $path', uri: _uri(path));
    }
    if (data.trim().isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(data);
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    return <String, dynamic>{'result': decoded};
  }

  Future<bool> connectWifi() async {
    if (connecting) return false;
    connecting = true; error = null; notifyListeners();
    try {
      final response = await _request('GET', '/status');
      await _leaveBle();
      mode = ConnectionMode.wifi;
      _applyTelemetry(response);
      _poller?.cancel();
      _poller = Timer.periodic(const Duration(seconds: 2), (_) => refreshStatus());
      connecting = false;
      notifyListeners();
      return true;
    } catch (e) {
      connecting = false;
      error = 'Could not reach the robot at $ipAddress. Connect to its Wi-Fi AP and check /status. ($e)';
      notifyListeners();
      return false;
    }
  }

  Future<void> refreshStatus() async {
    if (mode != ConnectionMode.wifi || _fetchInProgress) return;
    _fetchInProgress = true;
    try {
      final result = await _request('GET', '/status');
      _applyTelemetry(result);
      _failedPolls = 0;
      error = null;
      notifyListeners();
    } catch (e) {
      _failedPolls++;
      if (_failedPolls >= 3) {
        _poller?.cancel();
        mode = ConnectionMode.none;
        error = 'Wi-Fi connection lost. Check robot power and Wi-Fi. ($e)';
      } else {
        error = 'Status refresh failed: $e';
      }
      notifyListeners();
    } finally {
      _fetchInProgress = false;
    }
  }

  double? _number(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.replaceAll(RegExp(r'[^0-9.\-]'), ''));
    return null;
  }

  void _applyTelemetry(Map<String, dynamic> payload) {
    final sensor = payload['sensors'] is Map ? Map<String, dynamic>.from(payload['sensors'] as Map) : <String, dynamic>{};
    final imu = payload['imu'] is Map ? Map<String, dynamic>.from(payload['imu'] as Map) :
        sensor['imu'] is Map ? Map<String, dynamic>.from(sensor['imu'] as Map) : <String, dynamic>{};
    distance = _number(payload['distance_cm'] ?? payload['distance'] ?? sensor['distance_cm'] ?? sensor['tof_cm'] ?? sensor['distance']);
    roll = _number(payload['roll'] ?? imu['roll']);
    pitch = _number(payload['pitch'] ?? imu['pitch']);
    yaw = _number(payload['yaw'] ?? imu['yaw']);
    battery = _number(payload['battery_percent'] ?? payload['battery'] ?? sensor['battery']);
    final setpoint = _number(payload['adjusted_setpoint']);
    if (setpoint != null) adjustedSetpoint = setpoint;
    final target = _number(payload['target']);
    if (target != null) targetDistance = target;
    if (payload['trial'] is num) trial = (payload['trial'] as num).toInt();
    if (payload['mode'] != null) robotMode = payload['mode'].toString();
    if (payload['last_command'] != null) lastCommand = payload['last_command'].toString();
    if (distance != null) {
      distanceHistory.add(distance!);
      distanceTimes.add(DateTime.now());
      if (distanceHistory.length > 600) { distanceHistory.removeAt(0); distanceTimes.removeAt(0); }
    }
    if (yaw != null) {
      yawHistory.add(yaw!);
      yawTimes.add(DateTime.now());
      if (yawHistory.length > 600) { yawHistory.removeAt(0); yawTimes.removeAt(0); }
    }
  }

  Future<void> scanBle() async {
    error = null; devices.clear(); scanning = true; notifyListeners();
    try {
      if (Platform.isAndroid) {
        // Nearby Devices runtime permission (Android 12+). On older Android
        // versions location permission may also need to be enabled by the user.
        await [Permission.bluetoothScan, Permission.bluetoothConnect].request();
      }
      await _scanSubscription?.cancel();
      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        for (final result in results) {
          final name = result.device.platformName.isNotEmpty
              ? result.device.platformName : result.advertisementData.advName;
          if (name.isNotEmpty && !devices.any((v) => v.device.remoteId == result.device.remoteId)) {
            devices.add(result);
          }
        }
        notifyListeners();
      });
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 9));
      await Future.delayed(const Duration(seconds: 9));
      if (mode != ConnectionMode.ble) await FlutterBluePlus.stopScan();
    } catch (e) {
      error = 'Bluetooth scan unavailable: $e. Check Bluetooth and app permissions.';
    } finally {
      scanning = false; notifyListeners();
    }
  }

  Future<bool> connectBle(ScanResult scanResult) async {
    connecting = true; error = null; notifyListeners();
    try {
      await FlutterBluePlus.stopScan();
      await scanResult.device.connect(timeout: const Duration(seconds: 12));
      final services = await scanResult.device.discoverServices();
      writableCharacteristics.clear();
      for (final service in services) {
        for (final characteristic in service.characteristics) {
          if (characteristic.properties.write || characteristic.properties.writeWithoutResponse) {
            writableCharacteristics.add(characteristic);
          }
        }
      }
      if (writableCharacteristics.isEmpty) {
        throw StateError('No writable BLE characteristic was exposed by the firmware');
      }
      bleWriteCharacteristic = writableCharacteristics.length == 1 ? writableCharacteristics.first : null;
      bleDevice = scanResult.device;
      bleName = bleDevice!.platformName.isEmpty ? bleName : bleDevice!.platformName;
      _poller?.cancel();
      mode = ConnectionMode.ble;
      _bleStateSubscription?.cancel();
      _bleStateSubscription = bleDevice!.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected && mode == ConnectionMode.ble) {
          mode = ConnectionMode.none;
          bleWriteCharacteristic = null;
          notifyListeners();
        }
      });
      connecting = false; notifyListeners(); return true;
    } catch (e) {
      error = 'BLE connection failed: $e';
      connecting = false; notifyListeners(); return false;
    }
  }

  void chooseCharacteristic(BluetoothCharacteristic item) {
    bleWriteCharacteristic = item;
    notifyListeners();
  }

  Future<bool> sendCommand(String command) async {
    // Serialize writes so STOP cannot overtake an earlier movement request.
    final previous = _lastCommandWrite;
    final finished = Completer<void>();
    _lastCommandWrite = finished.future;
    await previous;
    try {
      return await _sendCommandNow(command);
    } finally {
      finished.complete();
    }
  }

  Future<bool> _sendCommandNow(String command) async {
    if (!connected) { error = 'Connect to the robot before sending commands.'; notifyListeners(); return false; }
    final normalized = command.toUpperCase();
    try {
      if (mode == ConnectionMode.wifi) {
        await _request('POST', '/command', <String, dynamic>{'command': normalized, 'speed': speed.round()});
      } else {
        if (bleWriteCharacteristic == null) {
          throw StateError('Choose the correct writable BLE characteristic in Settings first');
        }
        // Match the ESP32 firmware protocol here if its format differs.
        await bleWriteCharacteristic!.write(utf8.encode('MANUAL:$normalized'),
            withoutResponse: !bleWriteCharacteristic!.properties.write);
      }
      lastCommand = normalized;
      error = null; notifyListeners(); return true;
    } catch (e) {
      error = 'Command $normalized failed: $e'; notifyListeners(); return false;
    }
  }

  Future<bool> requestCalibration(String path, [Map<String, dynamic>? data]) async {
    if (mode != ConnectionMode.wifi) {
      error = 'This operation needs Wi-Fi and a matching calibration endpoint in the ESP32 firmware.';
      notifyListeners(); return false;
    }
    try {
      final result = await _request('POST', path, data ?? <String, dynamic>{});
      _applyTelemetry(result);
      error = null; notifyListeners(); return true;
    } catch (e) {
      error = '$path is not available on this firmware: $e';
      notifyListeners(); return false;
    }
  }

  Future<void> runSteps(List<RobotStep> steps) async {
    if (runningProgram) return;
    if (!connected) { error = 'Connect to the robot before running a program.'; notifyListeners(); return; }
    runningProgram = true; _programCancelled = false; notifyListeners();
    try {
      for (final step in steps) {
        if (_programCancelled) break;
        if (!await sendCommand(step.command)) break;
        var remaining = step.duration;
        while (remaining > Duration.zero && !_programCancelled) {
          final chunk = remaining > const Duration(milliseconds: 100)
              ? const Duration(milliseconds: 100) : remaining;
          await Future.delayed(chunk);
          remaining -= chunk;
        }
        if (!await sendCommand('STOP')) break;
      }
    } finally {
      await sendCommand('STOP');
      runningProgram = false;
      notifyListeners();
    }
  }

  Future<void> stop() async {
    _programCancelled = true;
    if (connected) await sendCommand('STOP');
    notifyListeners();
  }

  Future<void> _leaveBle() async {
    if (bleDevice != null) {
      try { await bleDevice!.disconnect(); } catch (_) {}
    }
    bleDevice = null;
    bleWriteCharacteristic = null;
    writableCharacteristics.clear();
  }

  Future<void> disconnect() async {
    _programCancelled = true;
    await stop();
    _poller?.cancel();
    await _leaveBle();
    mode = ConnectionMode.none;
    distance = null; roll = null; pitch = null; yaw = null; battery = null;
    distanceHistory.clear(); distanceTimes.clear(); yawHistory.clear(); yawTimes.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _programCancelled = true;
    _poller?.cancel();
    _scanSubscription?.cancel();
    _bleStateSubscription?.cancel();
    _client.close(force: true);
    super.dispose();
  }
}

enum ConnectionMode { none, wifi, ble }

class RobotStep {
  const RobotStep(this.command, this.duration);
  final String command;
  final Duration duration;
}
