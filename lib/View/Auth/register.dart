import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DriverRegisterScreen extends StatefulWidget {
  const DriverRegisterScreen({super.key});

  @override
  State<DriverRegisterScreen> createState() => _DriverRegisterScreenState();
}

class _DriverRegisterScreenState extends State<DriverRegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers (keep only needed)
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();

  bool loading = false;

  InputDecoration input(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.25),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      );

  @override
  void dispose() {
    nameCtrl.dispose();
    phoneCtrl.dispose();
    emailCtrl.dispose();
    passwordCtrl.dispose();
    super.dispose();
  }

  void showMsg(String msg, {bool ok = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: ok ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: ShaderMask(
              shaderCallback: (rect) {
                return LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.9),
                    Colors.black.withOpacity(0.5),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ).createShader(rect);
              },
              blendMode: BlendMode.darken,
              child: Image.asset("assets/regi3.avif", fit: BoxFit.cover),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Text(
                        "Register Here",
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    section("Quick Register (Firestore)"),
                    field(nameCtrl, "Full Name"),
                    const SizedBox(height: 12),
                    field(phoneCtrl, "Phone Number"),
                    const SizedBox(height: 12),
                    field(emailCtrl, "Email"),
                    const SizedBox(height: 12),
                    field(passwordCtrl, "Password", obscure: true),
                    const SizedBox(height: 24),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 9, 7, 41),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: const StadiumBorder(),
                      ),
                      onPressed: loading ? null : submit,
                      child: Text(loading ? "Saving..." : "Register"),
                    ),

                    const SizedBox(height: 16),

                    Center(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: RichText(
                          text: const TextSpan(
                            text: "Already have an account? ",
                            style: TextStyle(color: Colors.white70),
                            children: [
                              TextSpan(
                                text: "Login here",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Widgets ----------
  Widget section(String title) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );

  Widget field(TextEditingController c, String hint, {bool obscure = false}) {
    return TextFormField(
      controller: c,
      obscureText: obscure,
      decoration: input(hint),
      validator: (v) => v!.trim().isEmpty ? "Required" : null,
      style: const TextStyle(color: Colors.white),
    );
  }

  // ---------- Submit Function ----------
  void submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    try {
      print("DEBUG: Starting registration...");

      // Format Sri Lanka phone to +94XXXXXXXXX (match your login flow)
      String clean = phoneCtrl.text.trim().replaceAll(" ", "");
      if (clean.startsWith("0")) clean = clean.substring(1);
      final phone = "+94$clean";

      // 1) Create user in Firebase Auth (email+password)
      UserCredential userCred =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailCtrl.text.trim(),
        password: passwordCtrl.text.trim(),
      );

      String uid = userCred.user!.uid;
      print("DEBUG: Auth success. UID = $uid");

      // 2) Save driver data in Firestore (use SAME collection you will check later)
      final Map<String, dynamic> driverData = <String, dynamic>{
        "uid": uid,
        "name": nameCtrl.text.trim(),
        "phone": phone,
        "email": emailCtrl.text.trim(),
        "createdAt": FieldValue.serverTimestamp(),
      };

      print("DEBUG: Writing to Firestore collection drivers...");
      await FirebaseFirestore.instance.collection("drivers").doc(uid).set(
            driverData,
            SetOptions(merge: true),
          );

      print("✅ DEBUG: Firestore write success!");
      showMsg("✅ Saved to Firestore (drivers)!", ok: true);

      if (mounted) Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      print("❌ DEBUG: Firebase Auth error: ${e.code} - ${e.message}");
      String errorMsg = "Registration failed";
      if (e.code == 'weak-password') {
        errorMsg = "❌ Password too weak (min 6 chars)";
      } else if (e.code == 'email-already-in-use') {
        errorMsg = "❌ Email already registered";
      } else if (e.code == 'invalid-email') {
        errorMsg = "❌ Invalid email format";
      } else {
        errorMsg = "❌ ${e.message}";
      }
      showMsg(errorMsg, ok: false);
    } catch (e) {
      print("❌ DEBUG: Firestore/Other error: $e");
      showMsg("❌ Firestore error: $e", ok: false);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }
}
