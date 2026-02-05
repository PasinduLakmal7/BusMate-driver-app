import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:location/location.dart' as loc;



class GpsHaddlePage extends StatefulWidget {
  const GpsHaddlePage({super.key});

  @override
  State<GpsHaddlePage> createState() => _GpsHaddlePageState();
}

class _GpsHaddlePageState extends State<GpsHaddlePage> {
  final loc.Location location = loc.Location();
  StreamSubscription<loc.LocationData>? _locationSubscription;

  @override
  void initState() {
    super.initState();
    _requestPermissionOnce();
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
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('location').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No locations yet"));
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final data = doc.data() as Map<String, dynamic>;

                    final name = data['name']?.toString() ?? "unknown";
                    final lat = data['latitude']?.toString() ?? "-";
                    final lng = data['longitude']?.toString() ?? "-";

                    return ListTile(
                      title: Text(name),
                      subtitle: Text("Lat: $lat   Lng: $lng"),
                    );
                  },
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

      await FirebaseFirestore.instance.collection('location').doc('user1').set({
        'latitude': locationResult.latitude,
        'longitude': locationResult.longitude,
        'name': 'pasindu',
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Get location error: $e");
    }
  }

  Future<void> _listenLocation() async {
    try {
      if (!await _ensureServiceAndPermission()) return;

      await _locationSubscription?.cancel();

      _locationSubscription = location.onLocationChanged.listen((currentLocation) async {
        await FirebaseFirestore.instance.collection('location').doc('user1').set({
          'latitude': currentLocation.latitude,
          'longitude': currentLocation.longitude,
          'name': 'pasindu',
        }, SetOptions(merge: true));
      }, onError: (e) async {
        debugPrint("Live location error: $e");
        await _locationSubscription?.cancel();
        if (mounted) setState(() => _locationSubscription = null);
      });

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
