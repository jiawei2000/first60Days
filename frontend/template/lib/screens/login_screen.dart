import 'package:flutter/material.dart';
import 'signin_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/login_bg.jpg', // background asset
              fit: BoxFit.cover,
            ),
          ),

          // Optional overlay for contrast
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black26],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const Spacer(),

                  // App icon + title
                  Column(
                    children: [
                      Image.asset(
                        'assets/images/baby_icon_white.jpg', // <-- white icon
                        height: 110, // 🔥 bigger icon
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Digital Nanny',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 36, // 🔥 larger title
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Bottom buttons
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 60, // 🔥 taller button
                        child: ElevatedButton(
                          onPressed: () {
                            // TODO: push SignUpScreen when ready
                          },
                          style: ElevatedButton.styleFrom(
                            elevation: 4,
                            backgroundColor: const Color(0xFF7EE0D8), // mint
                            foregroundColor: const Color(0xFF0C2F5C),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 18, // 🔥 bigger text
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          child: const Text('Sign Up'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 60, // 🔥 taller button
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SignInScreen(),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white70, width: 2),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 18, // 🔥 bigger text
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          child: const Text('Sign In'),
                        ),
                      ),
                      const SizedBox(height: 28),
                    ],
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
