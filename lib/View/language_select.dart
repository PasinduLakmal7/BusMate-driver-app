import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:driver_app/Utils/colors.dart';
import '../View/Provider/login_or_register.dart';

class LanguageSelectScreen extends StatelessWidget {
  const LanguageSelectScreen({super.key});

  Widget languageButton({
    required BuildContext context,
    required String title,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 62,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(35),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withOpacity(0.4),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: Text(
            title,
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
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
            child: Image.asset(
              "assets/lang.webp",
              fit: BoxFit.cover,
            ),
          ),

          // Gradient Overlay & Blur (Shader effect)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.5),
                    backgroundColor.withOpacity(0.85),
                    backgroundColor,
                  ],
                ),
              ),
            ),
          ),

          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
              child: Container(color: Colors.transparent),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Colors.white, Color(0xFFCBD5E1)],
                    ).createShader(bounds),
                    child: Text(
                      "Welcome",
                      style: GoogleFonts.montserrat(
                        fontSize: 52,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -2,
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  Text(
                    "Please select your language",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      color: Colors.white.withOpacity(0.6),
                      letterSpacing: 1,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 60),

                  languageButton(
                    context: context,
                    title: "ENGLISH",
                    gradient: const [Color(0xFF1E40AF), Color(0xFF3B82F6)],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AuthSelectScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 25),

                  languageButton(
                    context: context,
                    title: "සිංහල",
                    gradient: const [
                      Color(0xFF312E81),
                      Color(0xFF4338CA),
                    ],
                    onTap: () {
                      Navigator.pushNamed(context, '/driver-login');
                    },
                  ),

                  const SizedBox(height: 25),

                  languageButton(
                    context: context,
                    title: "தமிழ்",
                    gradient: const [
                      Color(0xFF4338CA),
                      Color(0xFF6366F1),
                    ],
                    onTap: () {
                      Navigator.pushNamed(context, '/driver-login');
                    },
                  ),

                  const SizedBox(height: 60),

                  Text(
                    "You can change language later in settings",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: Colors.white38,
                      fontSize: 13,
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
}
