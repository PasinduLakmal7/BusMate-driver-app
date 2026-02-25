import 'package:flutter/material.dart';
import '../../Services/auth_service.dart';
import './otp_verfy.dart';

// ✅ ADD THIS (change the path to your HomeScreen file)
import '../home_screen.dart';

class DriverLoginScreen extends StatefulWidget {
  const DriverLoginScreen({super.key});

  @override
  State<DriverLoginScreen> createState() => _DriverLoginScreenState();
}

class _DriverLoginScreenState extends State<DriverLoginScreen> {
  final TextEditingController _nameController = TextEditingController(); //  added
  final TextEditingController _phoneController = TextEditingController();
  bool loading = false;

  // OTP login enabled — uses backend /drivers/request-otp + /drivers/verify-otp
  final bool enableOtpLogin = true;

  @override
  void dispose() {
    _nameController.dispose(); // ✅ added
    _phoneController.dispose();
    super.dispose();
  }

  InputDecoration input(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      );

  void showMsg(String msg, {bool isError = true}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          SizedBox.expand(
            child: Image.asset("assets/login3.webp", fit: BoxFit.cover),
          ),
          // Dark overlay
          Container(color: Colors.black.withOpacity(0.55)),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 50),
                  const Text(
                    "Driver Login",
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Login using your phone number",
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 40),

                  // ✅ NEW: name field
                  TextFormField(
                    controller: _nameController,
                    keyboardType: TextInputType.name,
                    style: const TextStyle(color: Colors.white),
                    decoration: input("Driver Name"),
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: Colors.white),
                    decoration: input("Phone Number").copyWith(
                      prefixText: "+94 ",
                      prefixStyle: const TextStyle(color: Colors.white),
                    ),
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 11, 7, 56),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: loading
                          ? null
                          : () async {
                              final nameRaw = _nameController.text.trim(); // ✅ added
                              if (nameRaw.isEmpty) {
                                showMsg("Enter driver name");
                                return;
                              }

                              final raw = _phoneController.text.trim();
                              if (raw.isEmpty) {
                                showMsg("Enter phone number");
                                return;
                              }

                              // ✅ Make sure user types WITHOUT leading 0.
                              // If user types 0778..., convert it.
                              String clean = raw.replaceAll(" ", "");
                              if (clean.startsWith("0")) clean = clean.substring(1);

                              final phone = "+94$clean";
                              setState(() => loading = true);

                              final auth = AuthService();

                              // ✅ NEW: check name + phone from Firestore before OTP
                              final ok = await auth.verifyDriverNameAndPhone(
                                name: nameRaw,
                                phone: phone,
                              );

                              if (!ok) {
                                if (mounted) {
                                  setState(() => loading = false);
                                  showMsg("Name or phone not registered");
                                }
                                return;
                              }

                              // ✅ ADD THIS: If OTP disabled, go directly to HomeScreen
                              if (!enableOtpLogin) {
                                if (!mounted) return;
                                setState(() => loading = false);

                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const DriverAppHomeScreen(),
                                  ),
                                );
                                return;
                              }

                              // ✅ Your OTP code stays (unchanged)
                              await auth.sendLoginOtp(
                                phone: phone,
                                context: context,
                                onCodeSent: (verificationId) {
                                  if (!mounted) return;
                                  setState(() => loading = false);

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => OtpVerifyScreen(
                                        verificationId: verificationId,
                                        phone: phone,
                                      ),
                                    ),
                                  );
                                },
                              );

                              if (mounted) setState(() => loading = false);
                            },
                      child: Text(loading ? "Sending..." : "Send OTP"),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
