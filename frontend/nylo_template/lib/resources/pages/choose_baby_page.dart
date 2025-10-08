import 'package:flutter/material.dart';
import '/app/models/baby.dart';
import '/app/controllers/choose_baby_controller.dart';
import '/resources/pages/base_navigation_hub.dart';
import '/config/keys.dart';
import 'package:nylo_framework/nylo_framework.dart';


class ChooseBabyPage extends StatefulWidget {
  static RouteView path = ("/choose-baby", (context) => ChooseBabyPage());

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
      appBar: AppBar(title: const Text("Choose Baby")),
      body: SafeArea(
        child: _babies.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: _babies.length,
                itemBuilder: (context, index) {
                  final baby = _babies[index];
                  return ListTile(
                    leading: Image.asset(
                      'public/images/baby_icon_animated.png',
                      width: 40,
                      height: 40,
                    ),
                    title: Text(baby.name ?? 'Unnamed Baby'),
                    subtitle: baby.dob != null
                        ? Text("DOB: ${baby.dob!.toLocal().toIso8601String().split('T').first}")
                        : null,
                    onTap: () async {
                      await Keys.selectedBabyId.save(baby.id);
                      routeTo(BaseNavigationHub.path, navigationType: NavigationType.pushAndForgetAll);
                    },
                  );
                },
              ),
      ),
    );
  }
}
