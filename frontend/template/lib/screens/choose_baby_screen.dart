import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../model/baby.dart';
import '../routes.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'providers/auth_provider.dart';

class ChooseBabyScreen extends StatefulWidget {
  const ChooseBabyScreen({super.key});

  @override
  State<ChooseBabyScreen> createState() => _ChooseBabyScreenState();
}

class _ChooseBabyScreenState extends State<ChooseBabyScreen> {
  List<Map<String, String>> babies = [];
  bool isLoading = true;

  final List<String> babyImages = [
    'assets/images/baby1.jpg',
    'assets/images/baby_2.jpg',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => fetchBabyProfiles());
  }

  Future<void> fetchBabyProfiles() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;

    if (token == null) {
      print(' No token found');
      return;
    }

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

        setState(() {
          babies = List<Map<String, String>>.generate(profiles.length, (index) {
            final baby = profiles[index];
            return {
              'id': baby['id'], // baby id stored now, i think 
              'name': baby['name'],
              'image': babyImages[index % babyImages.length],
            };
          });
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load baby profiles');
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _showAddBabyDialog() async {
    final nameController = TextEditingController();
    DateTime? selectedDate;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Baby Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Baby Name'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    selectedDate != null
                        ? 'DOB: ${selectedDate!.toLocal().toString().split(" ")[0]}'
                        : 'Select Date of Birth',
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (pickedDate != null) {
                      setState(() => selectedDate = pickedDate);
                    }
                  },
                )
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final token = Provider.of<AuthProvider>(context, listen: false).token;
              final name = nameController.text.trim();

              if (name.isEmpty || selectedDate == null || token == null) return;

              final body = {
                'name': name,
                'dob': selectedDate!.toUtc().toIso8601String(),
              };

              final baseURL = dotenv.env['BASE_URL'];
              final url = Uri.parse('$baseURL/babies/newProfile');

              try {
                final response = await http.post(
                  url,
                  headers: {
                    'Authorization': 'Bearer $token',
                    'Content-Type': 'application/json',
                  },
                  body: jsonEncode(body),
                );

                if (response.statusCode == 200 || response.statusCode == 201) {
                  Navigator.pop(ctx);
                  fetchBabyProfiles();
                } else {
                  print('Failed to create baby: ${response.body}');
                }
              } catch (e) {
                print('❌ Error creating baby: $e');
              }
            },
            child: const Text('Create'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Which Baby?"),
        actions: [
          TextButton(
            onPressed: () {
              // TODO: Add edit functionality
            },
            child: const Text("Edit", style: TextStyle(color: Colors.blue)),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Expanded(
                    child: GridView.builder(
                      itemCount: babies.length + 1,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 20,
                        crossAxisSpacing: 20,
                        childAspectRatio: 0.75,
                      ),
                      itemBuilder: (_, index) {
                        if (index < babies.length) {
                          final baby = babies[index];
                          return InkWell(
                            onTap: () {
                              final selectedBaby = Baby(
                                id: baby["id"]!, //selected baby id
                                name: baby["name"]!,
                                avatarUrl: baby["image"],
                              );

                              
                              Provider.of<AuthProvider>(context, listen: false)
                                  .setCurrentBabyId(baby["id"]!);

                              Navigator.pushReplacementNamed(
                                context,
                                Routes.landing,
                                arguments: {
                                  'baby': selectedBaby,
                                  'token': Provider.of<AuthProvider>(context, listen: false).token!,
                                },
                              );
                            },
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 40,
                                  backgroundImage: AssetImage(baby["image"]!),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  baby["name"]!,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          );
                        } else {
                          return Column(
                            children: [
                              InkWell(
                                onTap: _showAddBabyDialog,
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.blue),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.add, color: Colors.blue, size: 30),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text("Add Profile"),
                            ],
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}