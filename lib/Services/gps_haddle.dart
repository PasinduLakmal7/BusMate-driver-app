import 'dart:async';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:location/location.dart' as loc;

import 'gps_socket.dart';

class GpsHaddlePage extends StatefulWidget {
  const GpsHaddlePage({super.key});

  @override
  State<GpsHaddlePage> createState() => _GpsHaddlePageState();
}

class _GpsHaddlePageState extends State<GpsHaddlePage> {
  final loc.Location _location = loc.Location();

  // Socket.IO service
  GpsSocketService? _gpsSocket;

  // JWT token for authenticating with the backend
  String? _jwtToken;
  bool _socketActive = false;

  // Latest location values (shown in UI without Firestore)
  double? _currentLat;
  double? _currentLon;
  String? _lastUpdated;

  // Continuous location subscription (used for the non-socket fallback)
  StreamSubscription<loc.LocationData>? _locationSubscription;

  @override
  void initState() {
    super.initState();
    _requestPermissionOnce();
  }

  // ── Permissions ──────────────────────────────────────────────────────────────

  Future<void> _requestPermissionOnce() async {
    final status = await Permission.location.request();
    if (status.isPermanentlyDenied) {
      await openAppSettings();
    }
  }

  Future<bool> _ensureServiceAndPermission() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) return false;
    }

    var perm = await _location.hasPermission();
    if (perm == loc.PermissionStatus.denied) {
      perm = await _location.requestPermission();
      if (perm != loc.PermissionStatus.granted) return false;
    }

    await _location.changeSettings(
      accuracy: loc.LocationAccuracy.high,
      interval: 1000,
      distanceFilter: 0,
    );

    return true;
  }

  // ── UI ───────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GPS Handler'),
        actions: [
          IconButton(
            icon: const Icon(Icons.stop_circle),
            onPressed: _stopAll,
            tooltip: 'Stop',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // JWT input
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: _jwtToken,
                    decoration: const InputDecoration(
                      labelText: 'Backend JWT',
                      hintText: 'Paste JWT to enable Socket.IO GPS streaming',
                    ),
                    onChanged: (v) =>
                        _jwtToken = v.trim().isEmpty ? null : v.trim(),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  _socketActive ? Icons.cloud_done : Icons.cloud_off,
                  color: _socketActive ? Colors.green : Colors.red,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Control buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _sendOnce,
                  icon: const Icon(Icons.my_location),
                  label: const Text('Send Once'),
                ),
                ElevatedButton.icon(
                  onPressed: _startLive,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start Live'),
                ),
                ElevatedButton.icon(
                  onPressed: _stopAll,
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop'),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Live location display (local state — no Firestore)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Live Location',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currentLat != null
                          ? 'Lat: $_currentLat\nLon: $_currentLon'
                          : 'No location yet',
                    ),
                    if (_lastUpdated != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Updated: $_lastUpdated',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color:
                                _socketActive ? Colors.green : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _socketActive
                              ? 'Streaming via Socket.IO → Redis'
                              : 'Not streaming',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
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

  // ── Actions ──────────────────────────────────────────────────────────────────

  /// Send a single GPS fix via Socket.IO
  Future<void> _sendOnce() async {
    try {
      if (!await _ensureServiceAndPermission()) return;
      await _ensureSocketConnected();
      if (_gpsSocket == null || !_gpsSocket!.isConnected) return;

      final pos = await _location.getLocation();
      final payload = {
        'lat': pos.latitude,
        'lon': pos.longitude,
        'speed': pos.speed,
        'heading': pos.heading,
        'timestamp': DateTime.now().toIso8601String(),
      };

      _gpsSocket!.emitLocation(payload);
      _updateLocalDisplay(pos);
    } catch (e) {
      debugPrint('Send once error: $e');
    }
  }

  /// Start continuous GPS streaming via Socket.IO
  Future<void> _startLive() async {
    try {
      if (!await _ensureServiceAndPermission()) return;
      await _ensureSocketConnected();
      if (_gpsSocket == null || !_gpsSocket!.isConnected) return;

      // startSending() uses its own internal Timer + location reads
      await _gpsSocket!.startSending(intervalMs: 1500);

      // Also subscribe locally so the UI updates in real time
      await _locationSubscription?.cancel();
      _locationSubscription = _location.onLocationChanged.listen((pos) {
        _updateLocalDisplay(pos);
      });

      if (mounted) setState(() => _socketActive = true);
    } catch (e) {
      debugPrint('Start live error: $e');
    }
  }

  /// Stop everything
  Future<void> _stopAll() async {
    await _locationSubscription?.cancel();
    _locationSubscription = null;

    _gpsSocket?.stopSending();
    _gpsSocket?.disconnect();
    _gpsSocket = null;

    if (mounted) setState(() => _socketActive = false);
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  /// Create and connect the socket if not already connected.
  Future<void> _ensureSocketConnected() async {
    // Prompt for JWT if not provided
    if (_jwtToken == null || _jwtToken!.isEmpty) {
      final token = await _promptForToken();
      if (token == null || token.isEmpty) return;
      _jwtToken = token;
    }

    _gpsSocket ??= GpsSocketService(serverUrl: 'http://10.0.2.2:4000');

    if (!_gpsSocket!.isConnected) {
      _gpsSocket!.connect(token: _jwtToken!);
      // Give socket a moment to handshake
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  void _updateLocalDisplay(loc.LocationData pos) {
    if (!mounted) return;
    setState(() {
      _currentLat = pos.latitude;
      _currentLon = pos.longitude;
      _lastUpdated = DateTime.now().toIso8601String();
    });
  }

  Future<String?> _promptForToken() async {
    String? input;
    if (!mounted) return null;

    await showDialog(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Enter Backend JWT'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Paste JWT here'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                input = controller.text.trim();
                Navigator.of(ctx).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
    return input;
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _gpsSocket?.stopSending();
    _gpsSocket?.disconnect();
    super.dispose();
  }
}
