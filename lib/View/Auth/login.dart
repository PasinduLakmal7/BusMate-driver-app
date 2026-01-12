import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import '../../Services/auth_service.dart';
import '../auth/register.dart';

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
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  InputDecoration input(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Colors.white70),
    filled: true,
    fillColor: Colors.white.withOpacity(0.25),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(50),
      borderSide: BorderSide.none,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// Background Image
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: ShaderMask(
              shaderCallback: (rect) => LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.9),
                  Colors.black.withOpacity(0.5),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ).createShader(rect),
              blendMode: BlendMode.darken,
              child: Image.asset("assets/login3.webp", fit: BoxFit.cover),
            ),
          ),

          /// Login Form
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 60),
                  const Text(
                    "Driver Login",
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Login using your phone number",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 40),

                  /// Phone Number
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: input("Phone Number").copyWith(
                      prefixText: "+94 ",
                      prefixStyle: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 20),

                  /// OTP Field
                  if (_otpSent)
                    TextFormField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      decoration: input("Enter OTP"),
                    ),
                  const SizedBox(height: 30),

                  /// Button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 11, 7, 56),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 52),
                      shape: const StadiumBorder(),
                    ),
                    onPressed: () async {
                      final auth = AuthService();
                      final phone = "+94${_phoneController.text}";

                      if (!_otpSent) {
                        // Send OTP
                        await auth.registerDriver(
                          name: "dummy",
                          nic: "N/A",
                          email: "",
                          password: "",
                          birth: DateTime.now(),
                          driverPhoto: File(''),
                          phone: phone,
                          vehicleType: "dummy",
                          vehicleNum: "dummy",
                          licenseNum: "dummy",
                          licenseExpiry: DateTime.now(),
                          licensePhoto: File(''),
                          conductorName: "",
                          conductorPhone: "",
                          conductorPhoto: File(''),
                          busNo: "",
                          routeNo: "",
                          routeName: "",
                          depot: "",
                          tripsPerDay: 0,
                          trips: [],
                          context: context,
                          onCodeSent: (verificationId) {
                            setState(() {
                              _otpSent = true;
                              _verificationId = verificationId;
                            });
                          },
                        );
                      } else {
                        // Verify OTP
                        if (_verificationId != null) {
                          await auth.verifyOtpAndSaveDriver(
                            verificationId: _verificationId!,
                            otp: _otpController.text,
                            name: "dummy",
                            nic: "N/A",
                            email: "",
                            password: "",
                            birth: DateTime.now(),
                            driverPhoto: File(''),
                            phone: phone,
                            vehicleType: "dummy",
                            vehicleNum: "dummy",
                            licenseNum: "dummy",
                            licenseExpiry: DateTime.now(),
                            licensePhoto: File(''),
                            conductorName: "",
                            conductorPhone: "",
                            conductorPhoto: File(''),
                            busNo: "",
                            routeNo: "",
                            routeName: "",
                            depot: "",
                            tripsPerDay: 0,
                            trips: [],
                            context: context,
                          );
                        }
                      }
                    },

                    child: Text(_otpSent ? "Verify OTP" : "Send OTP"),
                  ),

                  const SizedBox(height: 25),

                  /// Register Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don’t have an account? ",
                        style: TextStyle(color: Colors.white70),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const DriverRegisterScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          "Register here",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
