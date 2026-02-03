import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../Services/auth_service.dart';

class OtpVerifyScreen extends StatefulWidget {
  final String verificationId;
  final String phone;

  const OtpVerifyScreen({
    super.key,
    required this.verificationId,
    required this.phone,
  });

  @override
  State<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends State<OtpVerifyScreen> {
  static const int otpLength = 6;

  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  bool loading = false;

  int resendSeconds = 30;
  Timer? _timer;

  // ✅ this must be updated when resend sends a new verificationId
  late String _verificationId;

  @override
  void initState() {
    super.initState();
    _verificationId = widget.verificationId;
    _controllers = List.generate(otpLength, (_) => TextEditingController());
    _focusNodes = List.generate(otpLength, (_) => FocusNode());
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => resendSeconds = 30);

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (resendSeconds <= 1) {
        t.cancel();
        setState(() => resendSeconds = 0);
      } else {
        setState(() => resendSeconds--);
      }
    });
  }

  void showMsg(String msg, {bool isError = true}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  String get otp => _controllers.map((c) => c.text).join();

  bool get isOtpComplete =>
      otp.length == otpLength && !_controllers.any((c) => c.text.isEmpty);

  void _onChanged(int index, String value) {
    if (value.length > 1) {
      _controllers[index].text = value[value.length - 1];
      _controllers[index].selection = TextSelection.fromPosition(
        TextPosition(offset: _controllers[index].text.length),
      );
    }

    if (value.isNotEmpty) {
      if (index < otpLength - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    } else {
      if (index > 0) _focusNodes[index - 1].requestFocus();
    }
    setState(() {});
  }

  Future<void> _verify() async {
    if (!isOtpComplete || loading) return;

    setState(() => loading = true);

    final auth = AuthService();

    // ✅ Correct method name
    await auth.verifyLoginOtp(
      verificationId: _verificationId,
      otp: otp,
      context: context,
    );

    if (mounted) setState(() => loading = false);
  }

  Future<void> _resend() async {
    if (resendSeconds != 0) return;

    _startTimer();
    showMsg("Sending new OTP...", isError: false);

    final auth = AuthService();

    await auth.sendLoginOtp(
      phone: widget.phone,
      context: context,
      onCodeSent: (newVerificationId) {
        if (!mounted) return;
        setState(() {
          _verificationId = newVerificationId;
        });
        showMsg("✅ OTP resent!", isError: false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(
            child: Image.asset("assets/login3.webp", fit: BoxFit.cover),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(color: Colors.black.withOpacity(0.35)),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Column(
                children: [
                  const SizedBox(height: 18),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(height: 30),

                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Icon(Icons.verified_user, color: Colors.white),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    "Verify Your Account",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "OTP sent to: ${widget.phone}",
                    style: const TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 26),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(otpLength, (i) {
                      return _OtpBox(
                        controller: _controllers[i],
                        focusNode: _focusNodes[i],
                        onChanged: (v) => _onChanged(i, v),
                      );
                    }),
                  ),

                  const SizedBox(height: 26),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color.fromARGB(255, 35, 29, 95), Color(0xFF050724)],
                        ),
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: (!isOtpComplete || loading) ? null : _verify,
                        child: Text(
                          loading ? "Verifying..." : "Verification",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't received code? ",
                        style: TextStyle(color: Colors.white70),
                      ),
                      GestureDetector(
                        onTap: resendSeconds == 0 ? _resend : null,
                        child: Text(
                          resendSeconds == 0
                              ? "Resend Now"
                              : "Resend in ${resendSeconds}s",
                          style: TextStyle(
                            color: resendSeconds == 0
                                ? Colors.white
                                : Colors.white54,
                            fontWeight: FontWeight.w700,
                            decoration: resendSeconds == 0
                                ? TextDecoration.underline
                                : TextDecoration.none,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),
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

class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 54,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        decoration: InputDecoration(
          counterText: "",
          filled: true,
          fillColor: Colors.white.withOpacity(0.10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
