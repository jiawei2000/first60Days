// lib/screens/profile_page.dart
import 'package:flutter/material.dart';
import '../routes.dart';
import 'manage_babies_page.dart';
import 'manage_caregivers_page.dart';
import '../model/profile_models.dart';
import '../model/baby.dart';

class BabyInfo {
  TextEditingController name;
  TextEditingController age; // e.g. "6 Weeks"
  BabyInfo({String name = '', String age = ''})
      : name = TextEditingController(text: name),
        age = TextEditingController(text: age);
}

class CaregiverInfo {
  TextEditingController name;
  TextEditingController detail; // e.g. "Nanny", "Grandmother"
  CaregiverInfo({String name = '', String detail = ''})
      : name = TextEditingController(text: name),
        detail = TextEditingController(text: detail);
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    this.initialName = 'Melissa Peters',
    this.initialEmail = 'melpeters@gmail.com',
    this.initialTrainer = 'Jane Doe',
    this.initialBabies = const [
      ('Chloe Lim', '6 Weeks'),
      ('Justin Lim', '10 Weeks'),
    ],
    this.initialCaregivers = const [
      ('XYZ', 'Nanny'),
      ('XYZ', 'Grandmother'),
    ],
  });

  final String initialName;
  final String initialEmail;
  final String initialTrainer;
  final List<(String, String)> initialBabies;     // (name, age)
  final List<(String, String)> initialCaregivers; // (name, detail)

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _editing = false;

  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _trainerCtrl;

  Widget _navButton(BuildContext context,
      {required String title,
      String? subtitle,
      required IconData icon,
      required VoidCallback onTap}) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              Icon(icon),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    if (subtitle != null)
                      Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  final List<BabyInfo> _babies = [];
  final List<CaregiverInfo> _caregivers = [];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName);
    _emailCtrl = TextEditingController(text: widget.initialEmail);
    _trainerCtrl = TextEditingController(text: widget.initialTrainer);

    for (final b in widget.initialBabies) {
      _babies.add(BabyInfo(name: b.$1, age: b.$2));
    }
    for (final c in widget.initialCaregivers) {
      _caregivers.add(CaregiverInfo(name: c.$1, detail: c.$2));
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _trainerCtrl.dispose();
    for (final b in _babies) {
      b.name.dispose();
      b.age.dispose();
    }
    for (final c in _caregivers) {
      c.name.dispose();
      c.detail.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        centerTitle: true,
        leading: const BackButton(),
        actions: [
          TextButton(
            onPressed: () => setState(() => _editing = !_editing),
            child: Text(_editing ? 'Done' : 'Edit'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 56 + bottomInset + 16),
          children: [
            _labeledBox('Name', _nameCtrl, enabled: _editing),
            const SizedBox(height: 12),
            _labeledBox('Email', _emailCtrl, enabled: _editing, keyboard: TextInputType.emailAddress),
            const SizedBox(height: 12),
            _labeledBox('Trainer', _trainerCtrl, enabled: _editing),
            const SizedBox(height: 16),

            // Baby section header
            _navButton(
              context,
              title: 'Manage Baby Information',
              subtitle: 'Add / edit babies',
              icon: Icons.child_care_outlined,
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ManageBabiesPage(
                      initialBabies: _babies
                          .map((b) => Baby(
                            id: DateTime.now().microsecondsSinceEpoch.toString(),
                            name: b.name.text,
                            age: b.age.text))
                          .toList(),
                    ),
                  ),
                ).then((updated) {
                  if (updated is List<Baby>) {
                    // sync back into controllers
                    for (final b in _babies) { b.name.dispose(); b.age.dispose(); }
                    _babies
                      ..clear()
                      ..addAll(updated.map((b) => BabyInfo(
                                      name: b.name, 
                                      age: b.age ?? '')));
                    setState(() {});
                  }
                });
              },
            ),
            const SizedBox(height: 12),
            _navButton(
              context,
              title: 'Manage Caregivers',
              subtitle: 'Create / edit caregiver profiles',
              icon: Icons.group_outlined,
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ManageCaregiversPage(
                      initialCaregivers: _caregivers
                          .map((c) => Caregiver(
                                username: c.name.text,
                                email: '',
                                phone: '',
                              ))
                          .toList(),
                    ),
                  ),
                ).then((updated) {
                  if (updated is List<Caregiver>) {
                    for (final c in _caregivers) { c.name.dispose(); c.detail.dispose(); }
                    _caregivers
                      ..clear()
                      ..addAll(updated.map((c) => CaregiverInfo(name: c.username, detail: '')));
                    setState(() {});
                  }
                });
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: const _ProfileTabs(),
    );
  }

  Widget _labeledBox(
    String label,
    TextEditingController ctrl, {
    bool enabled = false,
    String? hint,
    TextInputType keyboard = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            label,
            style: const TextStyle(color: Colors.blue),
          ),
        ),
        if (enabled)
          TextField(
            controller: ctrl,
            enabled: true,
            keyboardType: keyboard,
            decoration: InputDecoration(
              hintText: hint,
              isDense: true,
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              ctrl.text.isEmpty ? '-' : ctrl.text,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black, // solid text
              ),
            ),
          ),
      ],
    );
  }
}

class _ProfileTabs extends StatelessWidget {
  const _ProfileTabs();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 4, // Profile active
        onTap: (i) {
          switch (i) {
            case 0:
              // Navigator.pushNamed(context, Routes.plan);
              break;
            case 1:
              Navigator.pushNamed(context, Routes.calendar);
              break;
            case 2:
              Navigator.pushNamed(context, Routes.landing);
              break;
            case 3:
              Navigator.pushNamed(context, Routes.chat);
              break;
            case 4:
              // already on profile
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.event_note_outlined), label: 'Plan'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), label: 'Calendar'),
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
