import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:driver_app/Utils/colors.dart';

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
          // Background Image restored
          Positioned.fill(
            child: Image.asset(
              "assets/login3.webp",
              fit: BoxFit.cover,
            ),
          ),

          // Gradient Overlay & Shader logic
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.4),
                    backgroundColor.withOpacity(0.8),
                    backgroundColor,
                  ],
                ),
              ),
            ),
          ),

          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: Container(color: Colors.transparent),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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

                  const SizedBox(height: 30),

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

                  const SizedBox(height: 30),

                  Text(
                    "Quick Actions",
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),

                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      _ActionTile(
                        icon: Icons.route_rounded,
                        title: "My Trips",
                        subtitle: "History & schedule",
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Open Trips")),
                          );
                        },
                      ),
                      _ActionTile(
                        icon: Icons.account_balance_wallet_rounded,
                        title: "Earnings",
                        subtitle: "Daily income",
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Open Earnings")),
                          );
                        },
                      ),
                      _ActionTile(
                        icon: Icons.headset_mic_rounded,
                        title: "Support",
                        subtitle: "Contact help",
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Open Support")),
                          );
                        },
                      ),
                      _ActionTile(
                        icon: Icons.settings_suggest_rounded,
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

                  const SizedBox(height: 30),

                  const _StatusCard(),

                  const SizedBox(height: 40),
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
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF3B82F6), Color(0xFF1E3A8A)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.blueAccent.withOpacity(0.3),
                blurRadius: 10,
              ),
            ],
          ),
          child: const Icon(Icons.person, color: Colors.white, size: 28),
        ),
        const SizedBox(width: 14),

        // Name + status
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Hi, $driverName 👋",
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.greenAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "Status: Online",
                    style: GoogleFonts.inter(
                      color: Colors.white60,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Profile Button
        IconButton(
          onPressed: onProfile,
          icon: const Icon(Icons.account_circle_outlined, color: Colors.white70, size: 30),
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.12),
            Colors.white.withOpacity(0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Ready to start?",
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Turn on GPS and start your trip to begin tracking your route in real-time.",
            style: GoogleFonts.inter(
              color: Colors.white70,
              height: 1.5,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),

          GestureDetector(
            onTap: onStart,
            child: Container(
              width: double.infinity,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF1E3A8A)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blueAccent.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.gps_fixed_rounded, color: Colors.white),
                  const SizedBox(width: 12),
                  Text(
                    "Start GPS / Trip",
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: Colors.white.withOpacity(0.06),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: Colors.white.withOpacity(0.08),
                ),
                child: Icon(icon, color: Colors.blueAccent, size: 26),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  color: Colors.white54,
                  fontSize: 11,
                ),
              ),
            ],
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.amberAccent.withOpacity(0.05),
        border: Border.all(color: Colors.amberAccent.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline_rounded, color: Colors.amberAccent),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              "Keep GPS ON during the trip for accurate route tracking and better results.",
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
