import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../model/baby.dart';
import '../routes.dart';

class ChooseBabyScreen extends StatefulWidget {
  final String token;

  const ChooseBabyScreen({super.key, required this.token});

  @override
  State<ChooseBabyScreen> createState() => _ChooseBabyScreenState();
}

class _ChooseBabyScreenState extends State<ChooseBabyScreen> {
  List<Map<String, String>> babies = [];
  bool isLoading = true;

  // Hardcoded baby images to cycle through
  final List<String> babyImages = [
    'assets/images/baby1.jpg',
    'assets/images/baby2.jpg',
  ];

  @override
  void initState() {
    super.initState();
    fetchBabyProfiles();
  }

  Future<void> fetchBabyProfiles() async {
    final url = Uri.parse('http://10.0.2.2:3000/babyProfiles');

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> profiles = data['babyProfiles'];

        setState(() {
          babies = List<Map<String, String>>.generate(profiles.length, (index) {
            final baby = profiles[index];
            return {
              'name': baby['name'],
              'image': babyImages[index % babyImages.length], // rotate images
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
                                id: index.toString(),
                                name: baby["name"]!,
                                avatarUrl: baby["image"],
                              );

                              Navigator.pushReplacementNamed(
                                context,
                                Routes.landing,
                                arguments: selectedBaby,
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
                                onTap: () {
                                  // TODO: Add baby logic
                                },
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
