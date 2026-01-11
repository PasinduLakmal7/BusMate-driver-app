import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../Services/auth_service.dart';
import '../home_screen.dart'; // make sure the path is correct
import 'dart:io';


class DriverLoginScreen extends ConsumerStatefulWidget {
  const DriverLoginScreen({super.key});

  @override
  ConsumerState<DriverLoginScreen> createState() => _DriverLoginScreenState();
}

class _DriverLoginScreenState extends ConsumerState<DriverLoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  String? _verificationId;
  bool _otpSent = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Driver Login')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                prefixText: '+94', // Sri Lanka country code example
              ),
            ),
            const SizedBox(height: 20),
            if (_otpSent)
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Enter OTP',
                ),
              ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () async {
                final auth = AuthService();

                if (!_otpSent) {
                  // Step 1: Send OTP
                  await auth.registerDriver(
                    name: 'dummy', // only phone required for login
                    birth: DateTime.now(),
                    driverPhoto: File(''), // dummy
                    phone: '+94${_phoneController.text}',
                    vehicleType: 'dummy',
                    vehicleNum: 'dummy',
                    licenseNum: 'dummy',
                    licensePhoto: File(''), // dummy
                    context: context,
                    onCodeSent: (verificationId) {
                      setState(() {
                        _otpSent = true;
                        _verificationId = verificationId;
                      });
                    },
                  );
                } else {
                  // Step 2: Verify OTP
                  if (_verificationId != null) {
                    await AuthService().verifyOtpAndSaveDriver(
                      verificationId: _verificationId!,
                      otp: _otpController.text,
                      name: 'dummy',
                      birth: DateTime.now(),
                      driverPhoto: File(''),
                      phone: '+94${_phoneController.text}',
                      vehicleType: 'dummy',
                      vehicleNum: 'dummy',
                      licenseNum: 'dummy',
                      licensePhoto: File(''),
                      context: context,
                    );
                  }
                }
              },
              child: Text(_otpSent ? 'Verify OTP' : 'Send OTP'),
            ),
          ],
        ),
      ),
    );
  }
}
