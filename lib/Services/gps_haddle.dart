import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:location/location.dart' as loc;
import 'package:firebase_auth/firebase_auth.dart';

import 'map.dart';
import 'gps_socket.dart';

class GpsHaddlePage extends StatefulWidget {
  const GpsHaddlePage({super.key});

  @override
  State<GpsHaddlePage> createState() => _GpsHaddlePageState();
}

class _GpsHaddlePageState extends State<GpsHaddlePage> {
  final loc.Location location = loc.Location();
  StreamSubscription<loc.LocationData>? _locationSubscription;
  GpsSocketService? _gpsSocket;
  String? _jwtToken;
  bool _socketActive = false;

  // ✅ CONNECT BOTH TABLES USING SAME ID
  // drivers/{driverId}  -> driver details (create once somewhere else)
  // driver_locations/{driverId} -> live GPS (this file updates)
  final String driverId =
      "driver_001"; // later you can replace with FirebaseAuth uid

  @override
  void initState() {
    super.initState();
    _requestPermissionOnce();
  }

  // ✅ get correct driverId (prefer FirebaseAuth uid, fallback to driver_001)
  String _driverDocId() {
    return FirebaseAuth.instance.currentUser?.uid ?? driverId;
  }

  // ✅ get driver name from drivers/{uid} (fallback: drivers_test/{uid}, else "Driver")
  Future<String> _getDriverName() async {
    try {
      final id = _driverDocId();

      final doc = await FirebaseFirestore.instance
          .collection('drivers')
          .doc(id)
          .get();
      if (doc.exists) {
        final name = (doc.data()?['name'] ?? 'Driver').toString().trim();
        return name.isEmpty ? 'Driver' : name;
      }

      final doc2 = await FirebaseFirestore.instance
          .collection('drivers_test')
          .doc(id)
          .get();
      if (doc2.exists) {
        final name = (doc2.data()?['name'] ?? 'Driver').toString().trim();
        return name.isEmpty ? 'Driver' : name;
      }

      return "Driver";
    } catch (e) {
      debugPrint("Get driver name error: $e");
      return "Driver";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("GPS Handler"),
        actions: [
          IconButton(
            icon: const Icon(Icons.stop_circle),
            onPressed: _stopLocation,
            tooltip: "Stop",
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: _jwtToken,
                    decoration: const InputDecoration(
                      labelText: 'Backend JWT (optional)',
                      hintText: 'Paste backend JWT to enable socket GPS',
                    ),
                    onChanged: (v) =>
                        _jwtToken = v.trim().isEmpty ? null : v.trim(),
                  ),
                ),
                const SizedBox(width: 8),
                _socketActive
                    ? const Icon(Icons.cloud_done, color: Colors.green)
                    : const Icon(Icons.cloud_off, color: Colors.red),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: _getLocation,
                child: const Text("Add once"),
              ),
              ElevatedButton(
                onPressed: _startLive,
                child: const Text("Start live"),
              ),
              ElevatedButton(
                onPressed: _stopLocation,
                child: const Text("Stop"),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('driver_locations')
                  .doc(_driverDocId())
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.data!.exists) {
                  return const Center(child: Text("No location yet"));
                }

                final data = snapshot.data!.data() as Map<String, dynamic>;
                final name = data['name']?.toString() ?? "unknown";
                final lat = data['latitude']?.toString() ?? "-";
                final lng = data['longitude']?.toString() ?? "-";

                return ListTile(
                  title: Text(name),
                  subtitle: Text("Lat: $lat   Lng: $lng"),
                  trailing: IconButton(
                    icon: const Icon(Icons.map),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MyMap(_driverDocId()),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _requestPermissionOnce() async {
    final status = await Permission.location.request();

    if (status.isGranted) {
      debugPrint("Permission granted");
    } else if (status.isPermanentlyDenied) {
      await openAppSettings();
    } else {
      debugPrint("Permission denied");
    }
  }

  Future<bool> _ensureServiceAndPermission() async {
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) return false;
    }

    var perm = await location.hasPermission();
    if (perm == loc.PermissionStatus.denied) {
      perm = await location.requestPermission();
      if (perm != loc.PermissionStatus.granted) return false;
    }

    await location.changeSettings(
      accuracy: loc.LocationAccuracy.high,
      interval: 1000,
      distanceFilter: 0,
    );

    return true;
  }

  Future<void> _getLocation() async {
    try {
      if (!await _ensureServiceAndPermission()) return;

      final loc.LocationData locationResult = await location.getLocation();
      final id = _driverDocId();
      final driverName = await _getDriverName();

      // ✅ write ONLY live gps to driver_locations/{driverId}
      await FirebaseFirestore.instance
          .collection('driver_locations')
          .doc(id)
          .set({
            'latitude': locationResult.latitude,
            'longitude': locationResult.longitude,
            'name': driverName, // ✅ same corresponding user name
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
      // if socket available, also emit once
      if (_gpsSocket != null && _socketActive) {
        _gpsSocket!.emitLocation({
          'lat': locationResult.latitude,
          'lon': locationResult.longitude,
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint("Get location error: $e");
    }
  }

  Future<void> _listenLocation() async {
    try {
      if (!await _ensureServiceAndPermission()) return;

      await _locationSubscription?.cancel();

      final id = _driverDocId();
      final driverName = await _getDriverName();

      _locationSubscription = location.onLocationChanged.listen(
        (currentLocation) async {
          // ✅ write ONLY live gps to driver_locations/{driverId}
          await FirebaseFirestore.instance
              .collection('driver_locations')
              .doc(id)
              .set({
                'latitude': currentLocation.latitude,
                'longitude': currentLocation.longitude,
                'name': driverName, // ✅ same corresponding user name
                'updatedAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
          // emit via socket if active
          if (_gpsSocket != null && _socketActive) {
            _gpsSocket!.emitLocation({
              'lat': currentLocation.latitude,
              'lon': currentLocation.longitude,
              'timestamp': DateTime.now().toIso8601String(),
            });
          }
        },
        onError: (e) async {
          debugPrint("Live location error: $e");
          await _locationSubscription?.cancel();
          if (mounted) setState(() => _locationSubscription = null);
        },
      );

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Listen location error: $e");
    }
  }

  void _stopLocation() async {
    await _locationSubscription?.cancel();
    if (mounted) setState(() => _locationSubscription = null);
    // stop socket if running
    await _stopSocket();
  }

  Future<void> _startLive() async {
    // If user provided JWT, use socket streaming; otherwise fall back to Firestore updates
    if (_jwtToken != null && _jwtToken!.isNotEmpty) {
      await _startSocket();
      return;
    }

    // else start local listener that writes to Firestore
    await _listenLocation();
  }

  Future<void> _startSocket() async {
    try {
      if (!await _ensureServiceAndPermission()) return;

      if (_gpsSocket == null) {
        _gpsSocket = GpsSocketService(serverUrl: 'http://10.0.2.2:4000');
      }

      if (_jwtToken == null || _jwtToken!.isEmpty) {
        // try to get token from FirebaseAuth custom token (if used)
        final fb = FirebaseAuth.instance.currentUser;
        if (fb != null) {
          // this may not be the backend JWT; prompt instead
        }
        // ask user to paste token
        final token = await _promptForToken();
        if (token == null || token.isEmpty) return;
        _jwtToken = token;
      }

      _gpsSocket!.connect(token: _jwtToken!);
      await _gpsSocket!.startSending();
      if (mounted) setState(() => _socketActive = true);
    } catch (e) {
      debugPrint('Start socket error: $e');
    }
  }

  Future<void> _stopSocket() async {
    try {
      if (_gpsSocket != null) {
        _gpsSocket!.stopSending();
        _gpsSocket!.disconnect();
        _gpsSocket = null;
      }
      if (mounted) setState(() => _socketActive = false);
    } catch (e) {
      debugPrint('Stop socket error: $e');
    }
  }

  Future<String?> _promptForToken() async {
    String? input;
    if (!mounted) return null;
    await showDialog(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Enter backend JWT'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Paste JWT here'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
              },
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
    super.dispose();
  }
}
