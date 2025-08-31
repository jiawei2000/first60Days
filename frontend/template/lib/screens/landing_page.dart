import 'package:flutter/material.dart';
import '../routes.dart';

/// Landing / Home page matching the provided mock.
/// - Header: Baby name + circular avatar
/// - 3 big CTAs: Log Entry, View Calendar, Chat with Trainer
/// - FAQ carousel with dots
/// - Minimal bottom bar with "Home"
class LandingPage extends StatefulWidget {
  final String babyName;
  final String? avatarUrl;
  final VoidCallback? onLogEntry;
  final VoidCallback? onViewCalendar;
  final VoidCallback? onChatWithTrainer;
  final List<FaqItem> faqs;

  const LandingPage({
    super.key,
    this.babyName = 'Baby Chloe',
    this.avatarUrl,
    this.onLogEntry,
    this.onViewCalendar,
    this.onChatWithTrainer,
    this.faqs = kDummyFaqs,
  });

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  late final PageController _pageController;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.82);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          children: [
            _header(context),
            const SizedBox(height: 16),
            _ctaButton(
              context,
              label: 'Log Baby Journal Entry',
              onPressed: () {
                  Navigator.pushNamed(context, Routes.journal);
                },
            ),
            const SizedBox(height: 12),
            _ctaButton(
              context,
              label: 'View Calendar',
              onPressed: () {
                Navigator.pushNamed(context, Routes.calendar);
              },
            ),
            const SizedBox(height: 12),
            _ctaButton(
              context,
              label: 'Chat with Trainer',
              onPressed: widget.onChatWithTrainer ?? () => _fallbackSnack('Chat with Trainer'),
            ),
            const SizedBox(height: 20),
            _faqHeader(context),
            const SizedBox(height: 12),
            _faqCarousel(context),
            const SizedBox(height: 8),
            _dotIndicator(),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: const _HomeBar(),
    );
  }

  Widget _header(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            widget.babyName,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        CircleAvatar(
          radius: 18,
          backgroundColor: Colors.blue.shade50,
          backgroundImage: widget.avatarUrl == null
              ? null
              : NetworkImage(widget.avatarUrl!),
          child: widget.avatarUrl == null
              ? const Icon(Icons.child_care, color: Colors.blue)
              : null,
        ),
      ],
    );
  }

  Widget _ctaButton(BuildContext context, {required String label, required VoidCallback onPressed}) {
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(label, style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  Widget _faqHeader(BuildContext context) {
    return Row(
      children: [
        Text('FAQ', style: Theme.of(context).textTheme.titleMedium),
        const Spacer(),
        IconButton(
          onPressed: () => _fallbackSnack('Open all FAQs'),
          icon: const Icon(Icons.chevron_right),
        )
      ],
    );
  }

  Widget _faqCarousel(BuildContext context) {
    final items = widget.faqs;
    return SizedBox(
      height: 190,
      child: PageView.builder(
        controller: _pageController,
        itemCount: items.length,
        onPageChanged: (i) => setState(() => _page = i),
        itemBuilder: (context, i) => _FaqCard(item: items[i]),
      ),
    );
  }

  Widget _dotIndicator() {
    final len = widget.faqs.length;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(len, (i) {
        final active = i == _page;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          height: 6,
          width: active ? 18 : 6,
          decoration: BoxDecoration(
            color: active ? Colors.blue : Colors.blue.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
        );
      }),
    );
  }

  void _fallbackSnack(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature tapped')),
    );
  }
}

class _HomeBar extends StatelessWidget {
  const _HomeBar();
  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      height: 64,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.home_outlined),
            SizedBox(height: 4),
            Text('Home', style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

// ---------------- FAQ ----------------
class FaqItem {
  final String title;
  final String imageUrl;
  const FaqItem({required this.title, required this.imageUrl});
}

const kDummyFaqs = <FaqItem>[
  FaqItem(
    title: 'What to do if my baby is not sleeping?',
    imageUrl: '',
  ),
  FaqItem(
    title: 'Play time activities for 2 month olds',
    imageUrl: '',
  ),
  FaqItem(
    title: 'How often should I feed?',
    imageUrl: '',
  ),
];

class _FaqCard extends StatelessWidget {
  final FaqItem item;
  const _FaqCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Open: ${item.title}')),
        ),
        child: Material(
          elevation: 1,
          borderRadius: BorderRadius.circular(14),
          color: Theme.of(context).colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      item.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(
                        color: Colors.grey.shade200,
                        child: const Center(child: Icon(Icons.image_not_supported)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------- Quick demo scaffold ----------------
/// OPTIONAL: run this widget as your home to preview quickly.
class DemoApp extends StatelessWidget {
  const DemoApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: LandingPage(
        onLogEntry: () {
          // TODO: Navigate to your JournalEntryPage()
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
