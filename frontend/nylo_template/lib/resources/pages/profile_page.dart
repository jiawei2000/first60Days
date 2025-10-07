import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';
import '/resources/widgets/buttons/buttons.dart';
// import 'caregiver_page.dart'; // <-- add this import
// If you want a Babies page later, create it similarly and import here.

class ProfilePage extends NyStatefulWidget {
  static RouteView path = ("/profile", (_) => ProfilePage());
  ProfilePage({super.key}) : super(child: () => _ProfilePageState());
}

class _ProfilePageState extends NyPage<ProfilePage> {
  String accountName = "Melissa Peters";
  String currentBabyName = "Baby Noah"; // update when you switch babies

  @override
  get init => () {};

  @override
  Widget view(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2B6BF3),
        centerTitle: true,
        title: const Text("My Profile",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          children: [
            // Account name (read-only)
            Text("Name", style: t.labelLarge),
            const SizedBox(height: 6),
            TextFormField(
              initialValue: accountName,
              readOnly: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              ),
            ),
            const SizedBox(height: 16),

            // Current baby name (read-only)
            Text("Current Baby", style: t.labelLarge),
            const SizedBox(height: 6),
            TextFormField(
              initialValue: currentBabyName,
              readOnly: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              ),
            ),
            const SizedBox(height: 16),

            // Switch baby (functionality later)
            Button.outlined(
              text: "Switch Baby",
              onPressed: () {
                // TODO: open switcher (bottom sheet / page) and update `currentBabyName`
              },
            ),

            const SizedBox(height: 24),
            const Divider(),

            // Manage Babies (expandable -> will navigate to list page later)
            FilledButton.tonalIcon(
              onPressed: () {
                // TODO: routeTo(BabyPage.path.name);
              },
              icon: const Icon(Icons.child_care_outlined),
              label: const Text("Manage Babies"),
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const Divider(),

            // Manage Caregivers (expandable & visible by default)
            // FilledButton.tonalIcon(
            //   // onPressed: () => routeTo(CaregiverPage.path),
            //   icon: const Icon(Icons.elderly_outlined),
            //   label: const Text("Manage Caregivers"),
            //   style: FilledButton.styleFrom(
            //     padding:
            //         const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            //     shape: RoundedRectangleBorder(
            //       borderRadius: BorderRadius.circular(12),
            //     ),
            //   ),
            // ),

            const SizedBox(height: 16),
            const Divider(),

            // Logout
            const SizedBox(height: 8),
            Button.primary(
              text: "Logout",
              onPressed: () async {
                // TODO: sign out; then route to login
              },
            ),
          ],
        ),
      ),
    );
  }
}
