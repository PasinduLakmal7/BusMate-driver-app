import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:location/location.dart' as loc;
import 'package:firebase_auth/firebase_auth.dart';

import 'map.dart';

class GpsHaddlePage extends StatefulWidget {
  const GpsHaddlePage({super.key});

  @override
  State<GpsHaddlePage> createState() => _GpsHaddlePageState();
}

class _GpsHaddlePageState extends State<GpsHaddlePage> {
  final loc.Location location = loc.Location();
  StreamSubscription<loc.LocationData>? _locationSubscription;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: _getLocation,
                child: const Text("Add once"),
              ),
              ElevatedButton(
                onPressed: _listenLocation,
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
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }
}
