import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:driver_app/View/Provider/theme_provider.dart';

class DriverAppHomeScreen extends ConsumerStatefulWidget {
  const DriverAppHomeScreen({super.key});

  @override
  ConsumerState<DriverAppHomeScreen> createState() =>
      _DriverAppHomeScreenState();
}


class _DriverAppHomeScreenState
    extends ConsumerState<DriverAppHomeScreen> {

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text("Driver Home"),
      ),
    );
  }
}
