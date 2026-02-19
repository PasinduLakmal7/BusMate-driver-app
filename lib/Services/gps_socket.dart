import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:location/location.dart';

class GpsSocketService {
  IO.Socket? _socket;
  Timer? _timer;
  final String serverUrl;

  GpsSocketService({required this.serverUrl});

  void connect({required String token}) {
    _socket = IO.io(serverUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'auth': {'token': token},
    });

    _socket!.on('connect', (_) => print('GPS socket connected'));
    _socket!.on('disconnect', (_) => print('GPS socket disconnected'));
    _socket!.on('connect_error', (err) => print('GPS socket error: $err'));

    _socket!.connect();
  }

  Future<void> startSending({int intervalMs = 1500}) async {
    if (_socket == null || !_socket!.connected) {
      print('Socket not connected');
      return;
    }

    Location location = Location();
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) serviceEnabled = await location.requestService();
    PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return;
    }

    _timer?.cancel();
    _timer = Timer.periodic(Duration(milliseconds: intervalMs), (_) async {
      try {
        final pos = await location.getLocation();
        _socket?.emit('location:update', {
          'lat': pos.latitude,
          'lon': pos.longitude,
          'speed': pos.speed,
          'heading': pos.heading,
          'timestamp': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        print('Error reading location: $e');
      }
    });
  }

  void stopSending() {
    _timer?.cancel();
  }

  void disconnect() {
    _timer?.cancel();
    _socket?.disconnect();
    _socket = null;
  }

  /// Emit a single location update immediately.
  void emitLocation(Map<String, dynamic> payload) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('location:update', payload);
    } else {
      print('emitLocation: socket not connected');
    }
  }

  /// Whether the socket is currently connected.
  bool get isConnected => _socket?.connected == true;
}
