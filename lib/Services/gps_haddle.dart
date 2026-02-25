import 'dart:async';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:location/location.dart' as loc;

import 'gps_socket.dart';
import 'token_storage.dart';

/// GPS streaming page.
/// - Reads the JWT from secure storage automatically (saved at login).
/// - Streams GPS to the Node.js backend via Socket.IO every 1.5 s.
/// - Backend stores latest position in Redis (real-time) and writes to
///   bus_locations table every 10 minutes.
class GpsHaddlePage extends StatefulWidget {
  const GpsHaddlePage({super.key});

  @override
  State<GpsHaddlePage> createState() => _GpsHaddlePageState();
}

class _GpsHaddlePageState extends State<GpsHaddlePage> {
  final loc.Location _location = loc.Location();

  GpsSocketService? _gpsSocket;
  String? _jwtToken;

  bool _socketActive = false;
  bool _loadingToken = true;

  // Latest GPS values shown in the status card
  double? _currentLat;
  double? _currentLon;
  double? _currentSpeed;
  String? _lastUpdated;

  // Debug info shown when JWT is missing
  String _debugInfo = '';

  // UI poll subscription for status card
  StreamSubscription<loc.LocationData>? _uiSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestPermissionOnce();
      _loadStoredToken();
    });
  }

  // ── Init ─────────────────────────────────────────────────────────────────

  Future<void> _requestPermissionOnce() async {
    final status = await Permission.location.request();
    if (status.isPermanentlyDenied) await openAppSettings();
  }

  /// Reads JWT saved by verifyLoginOtp at login time.
  Future<void> _loadStoredToken() async {
    if (mounted) setState(() { _loadingToken = true; _debugInfo = ''; });
    try {
      final token = await TokenStorage.getToken();
      if (token == null || token.isEmpty) {
        if (mounted) setState(() { _debugInfo = 'No token found.\nPlease log out and log in again.'; });
      }
      if (mounted) setState(() { _jwtToken = token; _loadingToken = false; });
    } catch (e) {
      debugPrint('_loadStoredToken error: $e');
      if (mounted) setState(() { _loadingToken = false; _debugInfo = 'Error: $e'; });
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

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('GPS Tracking'),
        actions: [
          IconButton(
            icon: const Icon(Icons.stop_circle_outlined),
            onPressed: _stopAll,
            tooltip: 'Stop streaming',
          ),
        ],
      ),
      body: _loadingToken
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Status card ──────────────────────────────────────────
                  Card(
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Socket status dot
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: _socketActive
                                      ? Colors.green
                                      : Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _socketActive
                                    ? 'Streaming → Socket.IO → Redis'
                                    : 'Not streaming',
                                style: theme.textTheme.titleSmall,
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          // JWT info
                          Row(
                            children: [
                              const Icon(Icons.vpn_key, size: 16),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _jwtToken != null
                                      ? 'JWT loaded ✓'
                                      : 'No JWT — login first',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: _jwtToken != null
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                              ),
                              if (_jwtToken == null)
                                TextButton.icon(
                                  onPressed: () async {
                                    await _loadStoredToken();
                                    if (_jwtToken == null && mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Still no token — please log out and log in again'),
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.refresh, size: 16),
                                  label: const Text('Reload'),
                                ),
                            ],
                          ),
                          // Debug info when JWT failed — shows phone & error
                          if (_debugInfo.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _debugInfo,
                                  style: const TextStyle(fontSize: 11, color: Colors.orange),
                                ),
                              ),
                            ),
                          const SizedBox(height: 12),
                          // Location info
                          if (_currentLat != null) ...[
                            Text('Lat: ${_currentLat!.toStringAsFixed(6)}'),
                            Text('Lon: ${_currentLon!.toStringAsFixed(6)}'),
                            if (_currentSpeed != null)
                              Text(
                                  'Speed: ${(_currentSpeed! * 3.6).toStringAsFixed(1)} km/h'),
                            if (_lastUpdated != null)
                              Text(
                                'Updated: $_lastUpdated',
                                style: theme.textTheme.bodySmall,
                              ),
                          ] else
                            const Text('No location yet'),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Info box ─────────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '📡  GPS pings every 1.5 s → Redis (live display)\n'
                      '🗄️  bus_locations table updated every 10 min',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),

                  const Spacer(),

                  // ── Buttons ──────────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _socketActive ? null : _sendOnce,
                          icon: const Icon(Icons.my_location),
                          label: const Text('Send Once'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _socketActive ? null : _startLive,
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Start Live'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _socketActive ? _stopAll : null,
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop Streaming'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  /// Send a single GPS fix via Socket.IO
  Future<void> _sendOnce() async {
    if (!await _ensureServiceAndPermission()) return;
    if (!await _ensureSocketConnected()) return;

    try {
      final pos = await _location.getLocation();
      _gpsSocket!.emitLocation({
        'lat': pos.latitude,
        'lon': pos.longitude,
        'speed': pos.speed,
        'heading': pos.heading,
        'timestamp': DateTime.now().toIso8601String(),
      });
      _updateDisplay(pos);
    } catch (e) {
      debugPrint('sendOnce error: $e');
    }
  }

  /// Start continuous GPS streaming every 1.5 s
  Future<void> _startLive() async {
    if (!await _ensureServiceAndPermission()) return;
    if (!await _ensureSocketConnected()) return;

    // GpsSocketService handles the timer internally
    await _gpsSocket!.startSending(intervalMs: 1500);

    // Also update the local UI card from location stream
    await _uiSubscription?.cancel();
    _uiSubscription = _location.onLocationChanged.listen(_updateDisplay);

    if (mounted) setState(() => _socketActive = true);
  }

  Future<void> _stopAll() async {
    await _uiSubscription?.cancel();
    _uiSubscription = null;

    _gpsSocket?.stopSending();
    _gpsSocket?.disconnect();
    _gpsSocket = null;

    if (mounted) setState(() => _socketActive = false);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Ensures a socket exists and is connected. Returns false if no token.
  Future<bool> _ensureSocketConnected() async {
    if (_jwtToken == null || _jwtToken!.isEmpty) {
      _showSnack('No JWT token. Please log in first.');
      return false;
    }

    _gpsSocket ??= GpsSocketService(serverUrl: 'http://10.0.2.2:4000');

    if (!_gpsSocket!.isConnected) {
      _gpsSocket!.connect(token: _jwtToken!);
      // Brief wait for the WebSocket handshake
      await Future.delayed(const Duration(milliseconds: 600));
      if (!_gpsSocket!.isConnected) {
        _showSnack('Could not connect to server. Is the backend running?');
        return false;
      }
    }
    return true;
  }

  void _updateDisplay(loc.LocationData pos) {
    if (!mounted) return;
    final now = DateTime.now();
    setState(() {
      _currentLat = pos.latitude;
      _currentLon = pos.longitude;
      _currentSpeed = pos.speed;
      _lastUpdated = '${now.hour.toString().padLeft(2, '0')}:'
          '${now.minute.toString().padLeft(2, '0')}:'
          '${now.second.toString().padLeft(2, '0')}';
    });
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _uiSubscription?.cancel();
    _gpsSocket?.stopSending();
    _gpsSocket?.disconnect();
    super.dispose();
  }
}