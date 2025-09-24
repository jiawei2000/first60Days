import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../model/baby.dart';
import 'providers/auth_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ManageBabiesPage extends StatefulWidget {
  const ManageBabiesPage({super.key, required this.initialBabies});
  final List<Baby> initialBabies;

  @override
  State<ManageBabiesPage> createState() => _ManageBabiesPageState();
}

class _ManageBabiesPageState extends State<ManageBabiesPage> {
  late List<Baby> babies;
  final baseURL = dotenv.env['BASE_URL'];

  @override
  void initState() {
    super.initState();
    babies = [...widget.initialBabies];
  }

  Future<void> _deleteBaby(String babyId) async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;

    final url = Uri.parse('$baseURL/babies/deleteProfile');
    final response = await http.delete(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'babyId': babyId}),
    );

    if (response.statusCode == 200) {
      print("Baby deleted");
    } else {
      print("Failed to delete baby: \${response.body}");
    }
  }

  Future<void> _editBaby(Baby baby, String name, String ageInput) async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;

    final dob = _calculateDobFromAge(ageInput);
    
    if (dob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid age format")),
      );
      return;
    }

    final url = Uri.parse('$baseURL/babies/editProfile');
    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'babyId': baby.id,
        'name': name,
        'dob': dob.toIso8601String(),
      }),
    );

    if (response.statusCode == 200) {
      print(" Baby updated");
    } else {
      print(" Failed to update baby: \${response.body}");
    }
  }

  Future<void> _addBaby(String name, String ageInput) async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    final dob = _calculateDobFromAge(ageInput);
    if (dob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid age format")),
      );
      return;
    }

    // Now we know dob is not null, so use ! to assert non-null
    final dobIso = dob.toUtc().toIso8601String().split('.').first + 'Z';
    

    final url = Uri.parse('$baseURL/babies/newProfile');

    final requestBody = {
      'dob': dobIso,
      'name': name,
    };

    print('📤 Sending POST request to $url');
    print('🔑 Token: $token');
    print('📦 Body: $requestBody');

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(requestBody),
    );
    


    if (response.statusCode == 200) {
      print(" Baby added");
    } else {
      print(" Failed to add baby: ${response.statusCode} → ${response.body}");

    }
  }

DateTime? _calculateDobFromAge(String ageInput) {
  final regex = RegExp(r'^(\d+)\s*(day|days|week|weeks|month|months)$', caseSensitive: false);
  final match = regex.firstMatch(ageInput.trim());

  if (match == null) return null;

  final amount = int.tryParse(match.group(1)!);
  final unit = match.group(2)!.toLowerCase();

  if (amount == null) return null;

  final now = DateTime.now();

  switch (unit) {
    case 'day':
    case 'days':
      return now.subtract(Duration(days: amount));
    case 'week':
    case 'weeks':
      return now.subtract(Duration(days: amount * 7));
    case 'month':
    case 'months':
      final month = now.month - amount;
      return DateTime(now.year, month, now.day);
    default:
      return null;
  }
}


  void _addOrEdit({Baby? existing, int? index}) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final ageCtrl  = TextEditingController(text: existing?.age ?? '');

    final res = await showModalBottomSheet<Baby>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          left: 16, right: 16, top: 16,
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(existing == null ? 'Add Baby' : 'Edit Baby',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
          TextField(controller: ageCtrl, decoration: const InputDecoration(labelText: 'Age (e.g. 6 Weeks)')),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final age = ageCtrl.text.trim();
              if (name.isEmpty || age.isEmpty) return;

              final updatedBaby = Baby(
                id: existing?.id ?? '',
                name: name,
                avatarUrl: existing?.avatarUrl,
                age: age,
              );

              Navigator.pop(ctx, updatedBaby);

              if (existing != null) {
                await _editBaby(existing, name, age);
              } else {
                await _addBaby(name, age);
              }
            },
            child: const Text('Save'),
          ),
        ]),
      ),
    );

    if (res != null) {
      setState(() {
        if (index != null) {
          babies[index] = res;
        } else {
          babies.add(res);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Baby Information'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, babies),
            child: const Text('Done'),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: babies.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) => ListTile(
          title: Text(babies[i].name),
          subtitle: Text(
            (babies[i].age == null || babies[i].age!.isEmpty) ? '-' : babies[i].age!,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _addOrEdit(existing: babies[i], index: i),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  await _deleteBaby(babies[i].id);
                  setState(() => babies.removeAt(i));
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEdit(),
        child: const Icon(Icons.add),
      ),
    );
  }
}