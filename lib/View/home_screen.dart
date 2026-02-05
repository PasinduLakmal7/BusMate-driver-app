import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ✅ CHANGE THIS IMPORT to your real profile file path/class
import './Auth/profile.dart'; // example: lib/View/Auth/profile_screen.dart

import '../Services/gps_haddle.dart';

class DriverAppHomeScreen extends ConsumerStatefulWidget {
  const DriverAppHomeScreen({super.key});

  @override
  ConsumerState<DriverAppHomeScreen> createState() => _DriverAppHomeScreenState();
}

class _DriverAppHomeScreenState extends ConsumerState<DriverAppHomeScreen> {
  String driverName = "Driver";

  @override
  void initState() {
    super.initState();
    _loadDriverName();
  }

  Future<void> _loadDriverName() async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // 1) Try drivers/{uid}
    final doc1 = await FirebaseFirestore.instance
        .collection('drivers')
        .doc(user.uid)
        .get();

    if (doc1.exists) {
      final name = (doc1.data()?['name'] ?? 'Driver').toString().trim();
      if (mounted) {
        setState(() => driverName = name.isEmpty ? "Driver" : name);
      }
      return;
    }

    // 2) Try drivers_test/{uid}
    final doc2 = await FirebaseFirestore.instance
        .collection('drivers_test')
        .doc(user.uid)
        .get();

    if (doc2.exists) {
      final name = (doc2.data()?['name'] ?? 'Driver').toString().trim();
      if (mounted) {
        setState(() => driverName = name.isEmpty ? "Driver" : name);
      }
      return;
    }

    // 3) Fallback: search by phone (if phone OTP login)
    final phone = user.phoneNumber;
    if (phone != null && phone.isNotEmpty) {
      final snap = await FirebaseFirestore.instance
          .collection('drivers')
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        final name = (snap.docs.first.data()['name'] ?? 'Driver').toString().trim();
        if (mounted) {
          setState(() => driverName = name.isEmpty ? "Driver" : name);
        }
        return;
      }
    }
  } catch (e) {
    debugPrint("Failed to load driver name: $e");
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image (optional)
          SizedBox.expand(
            child: Image.asset("assets/login3.webp", fit: BoxFit.cover),
          ),

          // Dark overlay
          Container(color: Colors.black.withOpacity(0.65)),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TopBar(
                    driverName: driverName,
                    onProfile: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DriverProfileScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 18),

                  _MainActionCard(
                    onStart: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const GpsHaddlePage(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    "Quick Actions",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),

                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    children: [
                      _ActionTile(
                        icon: Icons.route,
                        title: "My Trips",
                        subtitle: "History & schedule",
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Open Trips")),
                          );
                        },
                      ),
                      _ActionTile(
                        icon: Icons.attach_money,
                        title: "Earnings",
                        subtitle: "Daily income",
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Open Earnings")),
                          );
                        },
                      ),
                      _ActionTile(
                        icon: Icons.support_agent,
                        title: "Support",
                        subtitle: "Contact help",
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Open Support")),
                          );
                        },
                      ),
                      _ActionTile(
                        icon: Icons.settings,
                        title: "Settings",
                        subtitle: "App preferences",
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Open Settings")),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  const _StatusCard(),

                  const SizedBox(height: 26),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback onProfile;
  final String driverName;

  const _TopBar({required this.onProfile, required this.driverName});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Avatar
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.15),
            border: Border.all(color: Colors.white24),
          ),
          child: const Icon(Icons.person, color: Colors.white),
        ),
        const SizedBox(width: 12),

        // Name + status
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Hi, $driverName 👋",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                "Status: Online",
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),

        // View profile button
        OutlinedButton.icon(
          onPressed: onProfile,
          icon: const Icon(Icons.account_circle, color: Colors.white),
          label: const Text(
            "View Profile",
            style: TextStyle(color: Colors.white),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.white24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}

class _MainActionCard extends StatelessWidget {
  final VoidCallback onStart;
  const _MainActionCard({required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Colors.white.withOpacity(0.10),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Ready to start?",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Turn on GPS and start your trip to track the route.",
            style: TextStyle(color: Colors.white70, height: 1.4),
          ),
          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.fromARGB(255, 51, 43, 126),
                    Color(0xFF050724),
                  ],
                ),
              ),
              child: ElevatedButton.icon(
                onPressed: onStart,
                icon: const Icon(Icons.gps_fixed, color: Colors.white),
                label: const Text(
                  "Start GPS / Trip",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.white.withOpacity(0.10),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: Colors.white.withOpacity(0.12),
              ),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withOpacity(0.10),
        border: Border.all(color: Colors.white24),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Colors.white),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              "Tip: Keep GPS ON during the trip for accurate route tracking.",
              style: TextStyle(color: Colors.white70, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
