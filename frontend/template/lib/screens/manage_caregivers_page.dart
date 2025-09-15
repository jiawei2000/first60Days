import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../model/profile_models.dart';
import 'providers/auth_provider.dart';

class ManageCaregiversPage extends StatefulWidget {
  const ManageCaregiversPage({super.key, required this.initialCaregivers});
  final List<Caregiver> initialCaregivers;

  @override
  State<ManageCaregiversPage> createState() => _ManageCaregiversPageState();
}

class _ManageCaregiversPageState extends State<ManageCaregiversPage> {
  late List<Caregiver> caregivers;

  @override
  void initState() {
    super.initState();
    caregivers = [...widget.initialCaregivers];
  }

  void _addCaregiver() async {
    final formKey = GlobalKey<FormState>();
    final username = TextEditingController();
    final email = TextEditingController();
    final phone = TextEditingController();
    final pwd = TextEditingController();
    final pwd2 = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Create Caregiver Profile',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: username,
                  decoration: const InputDecoration(labelText: 'Username*'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: email,
                  decoration: const InputDecoration(labelText: 'Email*'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => (v != null && v.contains('@'))
                      ? null
                      : 'Enter a valid email',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phone,
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: pwd,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password*'),
                  validator: (v) =>
                      (v == null || v.length < 6) ? 'Min 6 characters' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: pwd2,
                  obscureText: true,
                  decoration:
                      const InputDecoration(labelText: 'Confirm Password*'),
                  validator: (v) =>
                      (v != pwd.text) ? 'Passwords do not match' : null,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;

                      final token = Provider.of<AuthProvider>(
                        context,
                        listen: false,
                      ).token;

                      if (token == null) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('User not authenticated')),
                          );
                        }
                        return;
                      }

                      final caregiverData = {
                        "email": email.text.trim(),
                        "password": pwd.text.trim(),
                        "phoneNo": phone.text.trim(),
                        "username": username.text.trim(),
                        "babyIDArr": ["W6b0M4UJxxfbo0bktsm0"], // Replace with actual baby ID
                      };

                      final url =
                          Uri.parse('http://10.0.2.2:3000/users/registerSub');

                      print("📤 API CALL to: $url");
                      print("📦 Request Body: ${jsonEncode(caregiverData)}");

                      try {
                        final response = await http.post(
                          url,
                          headers: {
                            'Content-Type': 'application/json',
                            'Authorization': 'Bearer $token',
                          },
                          body: jsonEncode(caregiverData),
                        );

                        print("📥 Response: ${response.statusCode} - ${response.body}");

                        if (response.statusCode == 200 ||
                            response.statusCode == 201) {
                          if (!mounted) return;
                          Navigator.pop(ctx); // close the modal
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Caregiver added successfully')),
                          );
                          setState(() {
                            caregivers.add(Caregiver(
                              username: username.text.trim(),
                              email: email.text.trim(),
                              phone: phone.text.trim(),
                            ));
                          });
                        } else {
                          final error = jsonDecode(response.body);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(error['error'] ?? 'Failed to create caregiver'),
                            ),
                          );
                        }
                      } catch (e) {
                        if (!mounted) return;
                        print('❌ Error: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Network error. Please try again.')),
                        );
                      }
                    },
                    child: const Text('Create'),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Caregivers'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, caregivers),
            child: const Text('Done'),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: caregivers.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final cg = caregivers[i];
          return ListTile(
            title: Text(cg.username),
            subtitle:
                Text('${cg.email}${cg.phone.isEmpty ? '' : ' · ${cg.phone}'}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    // TODO: handle edit
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => setState(() => caregivers.removeAt(i)),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCaregiver,
        child: const Icon(Icons.add),
      ),
    );
  }
}
