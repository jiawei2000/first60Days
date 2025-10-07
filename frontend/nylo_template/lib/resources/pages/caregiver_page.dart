import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';
import '/app/forms/caregiver_form.dart';

class CaregiverPage extends NyStatefulWidget {
  static RouteView path = ("/caregiver", (_) => CaregiverPage());
  CaregiverPage({super.key}) : super(child: () => _CaregiverPageState());
}

class _CaregiverPageState extends NyPage<CaregiverPage> {
  /// Stubbed data – replace with DB later
  final List<Map<String, dynamic>> _caregivers = [
    {"Name": "Jane Doe", "Price": "20.00", "Favourite Color": "Blue", "Bio": "Nanny"},
    {"Name": "Mary Peters", "Price": "0.00", "Favourite Color": "Green", "Bio": "Grandmother"},
  ];

  @override
  get init => () {};

  @override
  Widget view(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2B6BF3),
        centerTitle: true,
        title: const Text("Caregivers", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          itemCount: _caregivers.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, i) {
            final c = _caregivers[i];
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(c["Name"] ?? "", style: t.titleMedium),
              subtitle: Text(
                [
                  if ((c["Bio"] ?? "").toString().isNotEmpty) c["Bio"],
                  if ((c["Favourite Color"] ?? "").toString().isNotEmpty) "Fav: ${c["Favourite Color"]}",
                  if ((c["Price"] ?? "").toString().isNotEmpty) "Rate: \$${c["Price"]}"
                ].join(" • "),
                style: t.bodyMedium,
              ),
              trailing: IconButton(
                tooltip: "Edit",
                icon: const Icon(Icons.edit),
                onPressed: () => _openCaregiverDialog(mode: "edit", index: i, initial: c),
              ),
              onTap: () => _openCaregiverDialog(mode: "edit", index: i, initial: c),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCaregiverDialog(mode: "add"),
        icon: const Icon(Icons.add),
        label: const Text("Add Caregiver"),
      ),
    );
  }

  Future<void> _openCaregiverDialog({
    required String mode, // "add" | "edit"
    int? index,
    Map<String, dynamic>? initial,
  }) async {
    final form = CaregiverForm();

    // Prefill when editing – keys must match your Field labels
    if (initial != null) {
      if (initial["Name"] != null) form.setValue("Name", initial["Name"]);
      if (initial["Price"] != null) form.setValue("Price", initial["Price"]);
      if (initial["Favourite Color"] != null) form.setValue("Favourite Color", initial["Favourite Color"]);
      if (initial["Bio"] != null) form.setValue("Bio", initial["Bio"]);
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(mode == "edit" ? "Edit Caregiver" : "Add Caregiver"),
          content: SingleChildScrollView(
            child: NyForm(form: form),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            FilledButton(
              onPressed: () async {
                final Map<String, dynamic> ok = await form.validate();
                if (ok.isEmpty) return;
                Navigator.pop(context, {
                  "Name": form.value("Name"),
                  "Price": form.value("Price"),
                  "Favourite Color": form.value("Favourite Color"),
                  "Bio": form.value("Bio"),
                });
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );

    if (result == null) return;

    setState(() {
      if (mode == "edit" && index != null) {
        _caregivers[index] = result;
      } else {
        _caregivers.add(result);
      }
    });
  }
}
