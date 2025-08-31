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

  void _goToLogin(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: pages.length + 1, // 0 = custom; 1..pages.length = content
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemBuilder: (_, index) {
                if (index == 0) {
                  // ---- Custom first page ----
                  return _OnboardCard(
                    child: Column(
                      children: [
                        const SizedBox(height: 32),
                        Image.asset(
                          'assets/images/baby_icon.jpg',
                          height: 160,
                          color: Colors.blue,
                        ),
                        const SizedBox(height: 28),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 28,
                            horizontal: 20,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.blue, width: 2),
                            color: Colors.white,
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
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text('by',
                                  style: TextStyle(color: Colors.black54)),
                              const SizedBox(height: 10),
                              Image.asset(
                                'assets/images/first60days_logo.jpg',
                                height: 52,
                                fit: BoxFit.contain,
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        _PrimaryButton(
                          label: 'GET STARTED',
                          onPressed: () {
                            _controller.nextPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.ease,
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  );
                }

                // ---- Standard pages (index: 1..pages.length) ----
                final page = pages[index - 1];
                final bool isLast = index == pages.length;

                return _OnboardCard(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.asset(
                              page['image']!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        page["title"]!,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          page["subtitle"]!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            TextButton(
                              onPressed: () => _goToLogin(context),
                              child: const Text(
                                "Skip",
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                            const Spacer(),
                            SizedBox(
                              width: 160,
                              child: _PrimaryButton(
                                label: isLast ? 'Done' : 'Next',
                                onPressed: () {
                                  if (isLast) {
                                    _goToLogin(context);
                                  } else {
                                    _controller.nextPage(
                                      duration:
                                          const Duration(milliseconds: 400),
                                      curve: Curves.ease,
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                );
              },
            ),

            // Page indicator (only for onboarding pages)
            Positioned(
              bottom: 28,
              left: 0,
              right: 0,
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    pages.length + 1, // 0..pages.length
                    (i) {
                      final isActive = _currentPage == i;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        height: 10,
                        width: isActive ? 28 : 10,
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFF2F6BFF)
                              : Colors.black26,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardCard extends StatelessWidget {
  const _OnboardCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFE0E6F5)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: child,
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 3,
          backgroundColor: const Color(0xFF2F6BFF),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}
