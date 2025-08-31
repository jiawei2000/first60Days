import 'package:flutter/material.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> pages = [
    {
      "title": "Digital Nanny",
      "subtitle": "Update the baby journal online",
      "image": "assets/images/onboard1.jpg"
    },
    {
      "title": "Digital Nanny",
      "subtitle": "Receive real-time notifications",
      "image": "assets/images/onboard2.jpg"
    },
    {
      "title": "Digital Nanny",
      "subtitle": "Communicate with your trainer",
      "image": "assets/images/onboard3.jpg"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView.builder(
        controller: _controller,
        itemCount: pages.length + 2, // +2: one for custom start, one for login
        onPageChanged: (index) {
          setState(() => _currentPage = index);
        },
        itemBuilder: (_, index) {
          if (index == 0) {
            // ✅ Custom first page (Start 2 style)
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),
                  Image.asset(
                    'assets/images/baby_icon.jpg',
                    height: 120,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue, width: 2),
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(60),
                        bottomLeft: Radius.circular(60),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Digital Nanny',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text('by'),
                        const SizedBox(height: 8),
                        Image.asset(
                          'assets/images/first60days_logo.jpg', 
                          height: 40,
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.ease,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'GET STARTED',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            );
          }

          if (index == pages.length + 1) {
            // ✅ Final page — go to Login screen
            return const LoginScreen();
          }

          final page = pages[index - 1]; // shift index by 1 due to custom page
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(page["image"]!, height: 250),
                const SizedBox(height: 32),
                Text(
                  page["title"]!,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  page["subtitle"]!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {
                        _controller.jumpToPage(pages.length + 1);
                      },
                      child: const Text("Skip"),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.ease,
                        );
                      },
                      child: const Text("Next"),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
