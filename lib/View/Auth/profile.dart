import 'package:flutter/material.dart';

class DriverProfileScreen extends StatelessWidget {
  const DriverProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Driver Profile")),
      body: const Center(
        child: Text("Your profile details here"),
      ),
    );
  }
}
