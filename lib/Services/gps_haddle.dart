import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:driver_app/Utils/colors.dart';
import 'gps_socket.dart';
import 'api_service.dart';
import 'token_storage.dart';

class GpsHaddlePage extends StatefulWidget {
  const GpsHaddlePage({super.key});

  @override
  State<GpsHaddlePage> createState() => _GpsHaddlePageState();
}

class _GpsHaddlePageState extends State<GpsHaddlePage> {
  GpsSocketService? _gpsSocket;
  String? _jwtToken;
  bool _socketActive = false;
  bool _loadingToken = true;
  double? _currentLat;
  double? _currentLon;
  double? _currentSpeed;
  String? _lastUpdated;
  String _debugInfo = '';
  StreamSubscription<Position>? _uiSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestPermissionOnce();
      _loadStoredToken();
    });
  }

  Future<void> _requestPermissionOnce() async {
    final status = await Permission.location.request();
    if (status.isPermanentlyDenied) await openAppSettings();
  }

  Future<void> _loadStoredToken() async {
    if (mounted) setState(() { _loadingToken = true; _debugInfo = ''; });
    try {
      final token = await TokenStorage.getToken();
      if (token == null || token.isEmpty) {
        if (mounted) setState(() { _debugInfo = 'Token required.\nPlease log in again.'; });
      }
      if (mounted) setState(() { _jwtToken = token; _loadingToken = false; });
    } catch (e) {
      if (mounted) setState(() { _loadingToken = false; _debugInfo = 'Error: $e'; });
    }
  }

  Future<bool> _ensureServiceAndPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showSnack('Location services are disabled.');
      return false;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "LIVE TRACKING",
          style: GoogleFonts.orbitron(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_socketActive)
            IconButton(
              icon: const Icon(Icons.stop_circle_outlined, color: Colors.redAccent),
              onPressed: _stopAll,
            ),
        ],
      ),
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Image.asset("assets/login3.webp", fit: BoxFit.cover),
          ),
          
          // Gradient & Blur
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    backgroundColor.withOpacity(0.85),
                    backgroundColor,
                  ],
                ),
              ),
            ),
          ),

          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(color: Colors.transparent),
            ),
          ),

          SafeArea(
            child: _loadingToken
                ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: Column(
                      children: [
                        // Connection HUD
                        buildConnectionHud(),
                        
                        const SizedBox(height: 30),

                        // Stats Dashboard
                        buildStatsDashboard(),

                        const Spacer(),

                        // Info Display
                        buildInfoDisplay(),

                        const SizedBox(height: 40),

                        // Controls
                        buildControlBar(),
                        
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget buildConnectionHud() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Glowing Indicator
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _socketActive ? Colors.greenAccent : Colors.redAccent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (_socketActive ? Colors.greenAccent : Colors.redAccent).withOpacity(0.5),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Text(
                _socketActive ? "STREAMING ACTIVE" : "STREAMING PAUSED",
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _socketActive ? Colors.greenAccent : Colors.white24,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          if (_jwtToken == null) ...[
            const SizedBox(height: 20),
            Text(
              "Access Token Required",
              style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: _loadStoredToken,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text("Reconnect Profile"),
            ),
          ],
        ],
      ),
    );
  }

  Widget buildStatsDashboard() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: statTile("LATITUDE", _currentLat?.toStringAsFixed(6) ?? "0.000000", Icons.location_on_outlined)),
            const SizedBox(width: 16),
            Expanded(child: statTile("LONGITUDE", _currentLon?.toStringAsFixed(6) ?? "0.000000", Icons.explore_outlined)),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            children: [
              Text(
                "CURRENT SPEED",
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.blueAccent, letterSpacing: 2),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                textBaseline: TextBaseline.alphabetic,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                children: [
                  Text(
                    _currentSpeed == null ? "0.0" : (_currentSpeed! * 3.6).toStringAsFixed(1),
                    style: GoogleFonts.orbitron(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "KM/H",
                    style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white24),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget statTile(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.blueAccent, size: 16),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white24, letterSpacing: 1),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.orbitron(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget buildInfoDisplay() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.amberAccent.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amberAccent.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: Colors.amberAccent, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "TRANSMISSION LOG",
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.amberAccent, letterSpacing: 1),
                ),
                const SizedBox(height: 4),
                Text(
                  _lastUpdated != null ? "Last transmission: $_lastUpdated" : "Waiting for GPS pulse...",
                  style: GoogleFonts.inter(color: Colors.white60, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildControlBar() {
    return Column(
      children: [
        if (!_socketActive)
          Row(
            children: [
              Expanded(
                child: controlBtn(Icons.my_location_rounded, "SEND ONCE", Colors.white10, _sendOnce),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: controlBtn(Icons.play_arrow_rounded, "START LIVE", Colors.blueAccent, _startLive, isPrimary: true),
              ),
            ],
          )
        else
          SizedBox(
            width: double.infinity,
            child: controlBtn(Icons.stop_rounded, "STOP STREAMING", Colors.redAccent, _stopAll, isPrimary: true),
          ),
      ],
    );
  }

  Widget controlBtn(IconData icon, String label, Color color, VoidCallback? onTap, {bool isPrimary = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: isPrimary ? null : color,
          gradient: isPrimary ? LinearGradient(colors: [color, color.withOpacity(0.6)]) : null,
          boxShadow: isPrimary ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10))] : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 1),
            ),
          ],
        ),
      ),
    );
  }

  // ── Logic ───────────────────────────────────────────────────────────────

  Future<void> _sendOnce() async {
    if (!await _ensureServiceAndPermission()) return;
    if (!await _ensureSocketConnected()) return;
    try {
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      _gpsSocket!.emitLocation({
        'lat': pos.latitude, 'lon': pos.longitude, 'speed': pos.speed, 'heading': pos.heading, 'timestamp': DateTime.now().toIso8601String(),
      });
      _updateDisplay(pos);
    } catch (e) {
      _showSnack('Location Error: Please ensure GPS is enabled.');
    }
  }

  Future<void> _startLive() async {
    if (!await _ensureServiceAndPermission()) return;
    if (!await _ensureSocketConnected()) return;
    await _gpsSocket!.startSending(intervalMs: 1500);
    await _uiSubscription?.cancel();
    _uiSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.bestForNavigation),
    ).listen(_updateDisplay, onError: (e) { _stopAll(); });
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

  Future<bool> _ensureSocketConnected() async {
    if (_jwtToken == null || _jwtToken!.isEmpty) { _showSnack('No profile token found.'); return false; }
    _gpsSocket ??= GpsSocketService(serverUrl: ApiService.baseUrl);
    if (!_gpsSocket!.isConnected) {
      _gpsSocket!.connect(token: _jwtToken!);
      await Future.delayed(const Duration(milliseconds: 800));
      if (!_gpsSocket!.isConnected) { _showSnack('Connection failed. Server unreachable.'); return false; }
    }
    return true;
  }

  void _updateDisplay(Position pos) {
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      content: Text(msg, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      backgroundColor: Colors.redAccent.withOpacity(0.9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    ));
  }

  @override
  void dispose() {
    _uiSubscription?.cancel();
    _gpsSocket?.stopSending();
    _gpsSocket?.disconnect();
    super.dispose();
  }
}