import 'package:flutter/material.dart';
import '../View/Provider/login_or_register.dart';

class LanguageSelectScreen extends StatelessWidget {
  const LanguageSelectScreen({super.key});

  Widget languageButton({
    required String title,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// -------- Background ----------
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Image.asset("assets/lang.webp", fit: BoxFit.cover),
          ),

          /// -------- Dark Overlay ----------
          Container(color: Colors.black.withOpacity(0.65)),

          /// -------- Content ----------
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 80),

                  /// Greeting
                  const Text(
                    "Welcome",
                    style: TextStyle(
                      fontSize: 50,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 196, 196, 197),
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    "Please select your language",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: Colors.white70),
                  ),

                  const Spacer(),

                  /// -------- Language Buttons ----------
                  languageButton(
                    title: "English",
                    gradient: const [Color(0xFF1A2980), Color(0xFF26D0CE)],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AuthSelectScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  languageButton(
                    title: "සිංහල",
                    gradient: const [
                      Color.fromARGB(255, 22, 37, 168),
                      Color.fromARGB(255, 90, 66, 175),
                    ],
                    onTap: () {
                      Navigator.pushReplacementNamed(context, '/driver-login');
                    },
                  ),

                  const SizedBox(height: 16),

                  languageButton(
                    title: "தமிழ்",
                    gradient: const [
                      Color.fromARGB(255, 96, 20, 167),
                      Color.fromARGB(255, 85, 67, 167),
                    ],
                    onTap: () {
                      Navigator.pushReplacementNamed(context, '/driver-login');
                    },
                  ),

                  const Spacer(),

                  /// Footer
                  const Text(
                    "You can change language later in settings",
                    style: TextStyle(color: Colors.white54, fontSize: 12),
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
