import 'dart:async'; // ✅ needed for StreamSubscription

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:permission_handler/permission_handler.dart';
import 'firebase_options.dart';
import 'package:location/location.dart' as loc;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

// ✅ Must be Stateful because you use setState + subscription
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final loc.Location location = loc.Location();
  StreamSubscription<loc.LocationData>? _locationSubscription;

  @override
  initState() {
    super.initState();
    _requestPermission();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Live Location")),
      body: Column(
        children: [
          TextButton(
            onPressed: () {
              _getLocation();
            },
            child: const Text("add my location"),
          ),
          TextButton(
            onPressed: () {
              _listenLocation();
            },
            child: const Text("enable live location"),
          ),
          TextButton(
            onPressed: () {
              _stopLocation();
            },
            child: const Text("stop live location"),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('location')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];

                    return ListTile(
                      title: Text(doc['name'].toString()),
                      subtitle: Row(
                        children: [
                          Text(doc['latitude'].toString()),
                          const SizedBox(width: 20),
                          Text(doc['longitude'].toString()),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.directions),
                        onPressed: () {},
                      ),
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

  Future<void> _getLocation() async {
    try {
      final loc.LocationData locationResult = await location.getLocation();

      await FirebaseFirestore.instance.collection('location').doc('user1').set({
        'latitude': locationResult.latitude,
        'longitude': locationResult.longitude,
        'name': 'pasindu',
      }, SetOptions(merge: true));
    } catch (e) {
      print(e);
    }
  }

  Future<void> _listenLocation() async {
    _locationSubscription = location.onLocationChanged
        .handleError((onError) {
          print(onError);
          _locationSubscription?.cancel();
          setState(() {
            _locationSubscription = null;
          });
        })
        .listen((loc.LocationData currentLocation) async {
          await FirebaseFirestore.instance
              .collection('location')
              .doc('user1')
              .set({
                'latitude': currentLocation.latitude,
                'longitude': currentLocation.longitude,
                'name': 'pasindu',
              }, SetOptions(merge: true));
        });
  }

  void _stopLocation() {
    _locationSubscription?.cancel();
    setState(() {
      _locationSubscription = null;
    });
  }

  _requestPermission() async {
    var status = await Permission.location.request();
    if (status.isGranted) {
      print('done');
    } else if (status.isDenied) {
      _requestPermission();
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
    }
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }
}
