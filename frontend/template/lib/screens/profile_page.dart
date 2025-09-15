import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../routes.dart';
import 'manage_babies_page.dart';
import 'manage_caregivers_page.dart';
import '../model/profile_models.dart';
import '../model/baby.dart';
import 'providers/auth_provider.dart';
import 'signin_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class BabyInfo {
  String id;
  TextEditingController name;
  TextEditingController age;
  BabyInfo({this.id = '', String name = '', String age = ''})
      : name = TextEditingController(text: name),
        age = TextEditingController(text: age);
}

class CaregiverInfo {
  TextEditingController name;
  TextEditingController detail;
  CaregiverInfo({String name = '', String detail = ''})
      : name = TextEditingController(text: name),
        detail = TextEditingController(text: detail);
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _editing = false;

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _trainerCtrl = TextEditingController(text: 'Jane Doe');

  final List<BabyInfo> _babies = [];
  final List<CaregiverInfo> _caregivers = [];

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    _emailCtrl.text = auth.email ?? 'Unknown';
    _nameCtrl.text = auth.username ?? 'unknown';

    // ✅ Load caregivers from provider (IDs only)
    _caregivers.addAll(
      auth.subAccountIds.map((id) => CaregiverInfo(name: id, detail: '')),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchBabyProfiles());
  }

  Future<void> _fetchBabyProfiles() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;

    final baseURL = dotenv.env['BASE_URL'];
    final url = Uri.parse('$baseURL/babies/getProfiles');
    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> profiles = data['babyProfiles'];

        for (final baby in profiles) {
          final id = baby['id'] ?? '';
          final name = baby['name'] ?? '-';
          final dobMap = baby['dob'];
          DateTime dob = DateTime.now();
          if (dobMap != null && dobMap is Map && dobMap['_seconds'] != null) {
            dob = DateTime.fromMillisecondsSinceEpoch(dobMap['_seconds'] * 1000);
          }
          final ageWeeks = DateTime.now().difference(dob).inDays ~/ 7;
          _babies.add(BabyInfo(id: id, name: name, age: '$ageWeeks Weeks'));
        }

        setState(() {});
      } else {
        print('Failed to fetch babies');
      }
    } catch (e) {
      print('Error: $e');
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
            _labeledBox('Email', _emailCtrl, enabled: false, keyboard: TextInputType.emailAddress),
            const SizedBox(height: 12),
            _labeledBox('Trainer', _trainerCtrl, enabled: _editing),
            const SizedBox(height: 16),
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
                                id: b.id,
                                name: b.name.text,
                                age: b.age.text,
                              ))
                          .toList(),
                    ),
                  ),
                ).then((updated) {
                  if (updated is List<Baby>) {
                    for (final b in _babies) {
                      b.name.dispose();
                      b.age.dispose();
                    }
                    _babies
                      ..clear()
                      ..addAll(updated.map((b) => BabyInfo(id: b.id, name: b.name, age: b.age ?? '')));
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
                    for (final c in _caregivers) {
                      c.name.dispose();
                      c.detail.dispose();
                    }
                    _caregivers
                      ..clear()
                      ..addAll(updated.map((c) => CaregiverInfo(name: c.username, detail: '')));
                    setState(() {});
                  }
                });
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Provider.of<AuthProvider>(context, listen: false).clearToken();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const SignInScreen()),
                  (route) => false,
                );
              },
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const _ProfileTabs(),
    );
  }

  Widget _labeledBox(String label, TextEditingController ctrl, {bool enabled = false, String? hint, TextInputType keyboard = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(label, style: const TextStyle(color: Colors.blue)),
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
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(ctrl.text.isEmpty ? '-' : ctrl.text, style: const TextStyle(fontSize: 16, color: Colors.black)),
          ),
      ],
    );
  }

  Widget _navButton(BuildContext context, {required String title, String? subtitle, required IconData icon, required VoidCallback onTap}) {
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
}

class _ProfileTabs extends StatelessWidget {
  const _ProfileTabs();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 4,
        onTap: (i) {
          switch (i) {
            case 0:
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
