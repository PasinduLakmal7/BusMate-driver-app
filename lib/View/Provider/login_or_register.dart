import 'package:flutter/material.dart';
import '../Auth/login.dart';
import '../Auth/register.dart';

class AuthSelectScreen extends StatelessWidget {
  const AuthSelectScreen({super.key});

  Widget optionCard({
    required String title,
    required String subtitle,
    required List<Color> gradient,
    required VoidCallback onTap,
    Color titleColor = Colors.white,        // <-- add optional title color
    Color subtitleColor = Colors.white70,  // <-- add optional subtitle color
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 160,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: titleColor, // <-- use parameter
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: subtitleColor, // <-- use parameter
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Image.asset(
              "assets/1.webp",
              fit: BoxFit.cover,
            ),
          ),
          // Dark overlay
          Container(color: Colors.black.withOpacity(0.6)),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 60),
                const Center(
                  child: Text(
                    "Welcome",
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 165, 164, 164),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    "Let's get started with your account",
                    style: TextStyle(
                      fontSize: 18,
                      color: Color.fromARGB(179, 204, 203, 203),
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Horizontal login/register options
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: optionCard(
                          title: "Login",
                          subtitle: "Already have an account",
                          gradient: const [
                            Color.fromARGB(255, 20, 14, 85),
                            Color.fromARGB(255, 20, 30, 59)
                          ],
                          titleColor: const Color.fromARGB(255, 190, 190, 189),       // <-- set title color
                          subtitleColor: Colors.white,     // <-- set subtitle color
                          onTap: () {
                            Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const DriverLoginScreen(),
                            ),
                          );
                          },
                        ),
                      ),
                      Expanded(
                        child: optionCard(
                          title: "Register",
                          subtitle: "Create new account",
                          gradient: const [
                            Color(0xFF1A2980),
                            Color.fromARGB(255, 22, 21, 54)
                          ],
                          titleColor: const Color.fromARGB(255, 190, 190, 189),       // <-- set title color
                          subtitleColor: Colors.white70,   // <-- set subtitle color
                          onTap: () {
                            Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const DriverRegisterScreen(),
                            ),
                          );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    "You can change your preferences later in settings",
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
