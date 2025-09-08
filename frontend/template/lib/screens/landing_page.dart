import 'package:flutter/material.dart';
import '../routes.dart';

class LandingPage extends StatefulWidget {
  final String babyName;
  final String? avatarUrl;
  final int currentWeek;
  final int totalWeeks;

  const LandingPage({
    super.key,
    required this.babyName,
    this.avatarUrl,
    this.currentWeek = 8,
    this.totalWeeks = 10,
  });

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  static const double _tabBarHeight = 56;
  bool _showTip = true;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            _tabBarHeight + bottomInset + 16,
          ),
          children: [
            _header(context),
            const SizedBox(height: 16),
            if (_showTip) ...[
              _tipBanner(onClose: () => setState(() => _showTip = false)),
              const SizedBox(height: 24),
            ],
            _progressSection(
              week: widget.currentWeek,
              total: widget.totalWeeks,
            ),
            const SizedBox(height: 32),
            _primaryCta(
              label: 'Log Baby Journal Entry',
              onPressed: () => Navigator.pushNamed(context, Routes.journal),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: const _HomeTabs(),
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
          backgroundImage:
              widget.avatarUrl == null ? null : NetworkImage(widget.avatarUrl!),
          child: widget.avatarUrl == null
              ? const Icon(Icons.child_care, color: Colors.blue)
              : null,
        ),
      ],
    );
  }
}

Widget _tipBanner({required VoidCallback onClose}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      boxShadow: const [
        BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
      ],
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CircleAvatar(
          radius: 14,
          backgroundColor: Color(0xFFEAF0FF),
          child: Icon(Icons.chat_bubble, size: 16, color: Color(0xFF6C8FF5)),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'This week your baby will learn to…..',
            style: TextStyle(fontSize: 14),
          ),
        ),
        InkWell(onTap: onClose, child: const Icon(Icons.close, size: 18)),
      ],
    ),
  );
}

Widget _progressSection({required int week, required int total}) {
  final pct = total == 0 ? 0.0 : (week / total).clamp(0.0, 1.0);
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Progression',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 8),
      Text('Week $week / $total', style: TextStyle(color: Colors.grey[700])),
      const SizedBox(height: 8),
      ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: LinearProgressIndicator(
          value: pct,
          minHeight: 14,
          backgroundColor: const Color(0xFFE6EAF2),
          valueColor: const AlwaysStoppedAnimation(Color(0xFF2F80ED)),
        ),
      ),
    ],
  );
}

Widget _primaryCta({required String label, required VoidCallback onPressed}) {
  return SizedBox(
    height: 56,
    width: double.infinity,
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2F80ED),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
    ),
  );
}

class _HomeTabs extends StatelessWidget {
  const _HomeTabs();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 2, // Home
        onTap: (i) {
          switch (i) {
            case 0:
              break;
            case 1:
              Navigator.pushNamed(context, Routes.calendar);
              break;
            case 2:
              //home
              break;
            case 3:
              Navigator.pushNamed(context, Routes.chat);
              break;
            case 4:
              Navigator.pushNamed(context, Routes.profile);
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.event_note_outlined), label: 'Plan'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined), label: 'Calendar'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline), label: 'Chat'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}
