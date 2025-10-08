import 'package:flutter/material.dart';
import '/app/models/baby.dart';
import '/app/controllers/choose_baby_controller.dart';
import '/resources/pages/base_navigation_hub.dart';
import '/config/keys.dart';
import 'package:nylo_framework/nylo_framework.dart';

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
    setState(() {
      _babies = babies;
    });
  }

  @override
  Widget build(BuildContext context) {
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
        child: _babies.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(20),
                child: GridView.builder(
                  itemCount: _babies.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.8,
                    mainAxisSpacing: 24,
                    crossAxisSpacing: 24,
                  ),
                  itemBuilder: (context, index) {
                    final baby = _babies[index];
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
