import 'package:flutter/material.dart';

class ChooseBabyScreen extends StatelessWidget {
  const ChooseBabyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> babies = [
      {"name": "Chloe", "image": "assets/images/baby1.jpg"},
      {"name": "Justin", "image": "assets/images/baby2.jpg"},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Which Baby?"),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text("Edit", style: TextStyle(color: Colors.blue)),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            GridView.builder(
              shrinkWrap: true,
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
                  return Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: AssetImage(baby["image"]!),
                      ),
                      const SizedBox(height: 8),
                      Text(baby["name"]!),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      InkWell(
                        onTap: () {
                          // TODO: Add profile flow
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
          ],
        ),
      ),
    );
  }
}
