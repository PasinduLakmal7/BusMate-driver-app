import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:driver_app/Utils/colors.dart';
import '../../Services/api_service.dart';
import '../../Services/token_storage.dart';
import '../../Services/auth_service.dart';
import './otp_verfy.dart';
import '../home_screen.dart';

class DriverLoginScreen extends StatefulWidget {
  const DriverLoginScreen({super.key});

  @override
  State<DriverLoginScreen> createState() => _DriverLoginScreenState();
}

class _DriverLoginScreenState extends State<DriverLoginScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool loading = false;
  final bool enableOtpLogin = true;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  InputDecoration inputDecoration(String hint, IconData icon) => InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: Colors.white38, fontSize: 15),
        prefixIcon: Icon(icon, color: Colors.blueAccent.withOpacity(0.7), size: 22),
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: Colors.blueAccent),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      );

  void showMsg(String msg, {bool isError = true}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        content: Text(msg, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        backgroundColor: isError ? Colors.redAccent.withOpacity(0.9) : Colors.greenAccent.withOpacity(0.9),
      ),
    );
  }

  void _showSettingsDialog() {
    final controller = TextEditingController(text: ApiService.baseUrl);
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: const Color(0xFF0F172A).withOpacity(0.9),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text("Connection Settings", style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Ensure your phone and laptop are on the same WiFi. The app tries to find the IP automatically, but you can set it manually here.",
                style: GoogleFonts.inter(fontSize: 13, color: Colors.white70),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Server URL",
                  labelStyle: const TextStyle(color: Colors.blueAccent),
                  hintText: "http://192.168.x.x:4000",
                  hintStyle: const TextStyle(color: Colors.white30),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel", style: GoogleFonts.inter(color: Colors.white38)),
            ),
            ElevatedButton(
              onPressed: () {
                final newUrl = controller.text.trim();
                if (newUrl.isNotEmpty) {
                  setState(() {
                    ApiService.baseUrl = newUrl;
                  });
                  TokenStorage.saveServerUrl(newUrl);
                  Navigator.pop(context);
                  showMsg("Server URL updated!", isError: false);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset("assets/login3.webp", fit: BoxFit.cover),
          ),
          
          // Shader Overlay
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
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(color: Colors.transparent),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  
                  // Header section
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Colors.white, Color(0xFF94A3B8)],
                    ).createShader(bounds),
                    child: Text(
                      "Driver Login",
                      style: GoogleFonts.montserrat(
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Welcome back to BusMate",
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  
                  const SizedBox(height: 30),

                  // Server Settings Indicator
                  GestureDetector(
                    onTap: _showSettingsDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.settings_input_antenna_rounded, size: 16, color: Colors.blueAccent),
                          const SizedBox(width: 10),
                          Text(
                            "Server: ${ApiService.baseUrl.replaceFirst('http://', '')}",
                            style: GoogleFonts.inter(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 50),

                  // Input Fields
                  TextFormField(
                    controller: _nameController,
                    keyboardType: TextInputType.name,
                    style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500),
                    decoration: inputDecoration("Enter Driver Name", Icons.person_outline_rounded),
                  ),

                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500),
                    decoration: inputDecoration("Phone Number", Icons.phone_iphone_rounded).copyWith(
                      prefixText: "+94 ",
                      prefixStyle: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 65,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(35),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blueAccent.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(35),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        onPressed: loading ? null : _handleLogin,
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                            ),
                            borderRadius: BorderRadius.circular(35),
                          ),
                          child: Container(
                            alignment: Alignment.center,
                            child: loading
                                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                                : Text(
                                    "SEND OTP",
                                    style: GoogleFonts.montserrat(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: 2,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                  
                  Text(
                    "Secure driver identification portal",
                    style: GoogleFonts.inter(
                      color: Colors.white24,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
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

  Future<void> _handleLogin() async {
    final nameRaw = _nameController.text.trim();
    if (nameRaw.isEmpty) {
      showMsg("Enter driver name");
      return;
    }

    final raw = _phoneController.text.trim();
    if (raw.isEmpty) {
      showMsg("Enter phone number");
      return;
    }

    String clean = raw.replaceAll(" ", "");
    if (clean.startsWith("0")) clean = clean.substring(1);

    final phone = "+94$clean";
    setState(() => loading = true);

    final auth = AuthService();
    final status = await auth.verifyDriverNameAndPhone(
      name: nameRaw,
      phone: phone,
    );

    if (status != 'approved') {
      if (mounted) {
        setState(() => loading = false);
        if (status == 'pending') {
          showMsg("Registration is pending admin approval.");
        } else if (status == 'not_found') {
          showMsg("Name or phone not registered.");
        } else {
          showMsg("Verification failed. Please try again.");
        }
      }
      return;
    }

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
  }
}
