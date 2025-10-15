// lib/resources/pages/choose_baby_page.dart

import 'package:flutter/material.dart';
import '/app/models/baby.dart';
import '/app/controllers/choose_baby_controller.dart';
import '/resources/pages/base_navigation_hub.dart';
import '/config/keys.dart';
import 'package:nylo_framework/nylo_framework.dart';
import '/resources/widgets/create_baby_widget.dart';

class ChooseBabyPage extends StatefulWidget {
  static RouteView path = ("/choose-baby", (context) => const ChooseBabyPage());

  const ChooseBabyPage({Key? key}) : super(key: key);

  @override
  State<ChooseBabyPage> createState() => _ChooseBabyPageState();
}

class _ChooseBabyPageState extends State<ChooseBabyPage> {
  final ChooseBabyController _controller = ChooseBabyController();
  List<Baby> _babies = [];

  @override
  void initState() {
    super.initState();
    _loadBabies();
  }

  void _loadBabies() async {
    final babies = await _controller.fetchBabies();
    setState(() => _babies = babies);
  }

  Future<void> _showAddBabyDialog() async {
    showDialog(
      context: context,
      builder: (_) => CreateBabyWidget(
        onBabyCreated: (newBaby) async {
          await Keys.selectedBabyId.save(newBaby.id);
          routeTo(BaseNavigationHub.path, navigationType: NavigationType.pushAndForgetAll);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profiles = [..._babies, null]; // null = add button

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Choose Your Baby",
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: profiles.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(20),
                child: GridView.builder(
                  itemCount: profiles.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.8,
                    mainAxisSpacing: 24,
                    crossAxisSpacing: 24,
                  ),
                  itemBuilder: (context, index) {
                    final baby = profiles[index];

                    if (baby == null) {
                      return GestureDetector(
                        onTap: _showAddBabyDialog,
                        child: Column(
                          children: [
                            Expanded(
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.grey[200],
                                  border: Border.all(color: Colors.grey.shade400, width: 2),
                                ),
                                child: const Icon(Icons.add, size: 48, color: Colors.grey),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              "Add Profile",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    return GestureDetector(
                      onTap: () async {
                        await Keys.selectedBabyId.save(baby.id);
                        routeTo(BaseNavigationHub.path, navigationType: NavigationType.pushAndForgetAll);
                      },
                      child: Column(
                        children: [
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                image: const DecorationImage(
                                  image: AssetImage('public/images/baby_icon_animated.png'),
                                  fit: BoxFit.cover,
                                ),
                                border: Border.all(color: Colors.grey.shade300, width: 2),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 6,
                                    offset: Offset(0, 3),
                                  )
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            baby.name ?? "Unnamed",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (baby.dob != null)
                            Text(
                              "DOB: ${baby.dob!.toLocal().toIso8601String().split('T').first}",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
