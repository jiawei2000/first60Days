import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';
import '/app/controllers/baby_controller.dart';
import '/app/forms/create_baby_form.dart';
import '/app/forms/edit_baby_form.dart';
import '/resources/widgets/buttons/buttons.dart';

class BabyPage extends NyStatefulWidget {
  static RouteView path = ("/babies", (_) => BabyPage());
  BabyPage({super.key}) : super(child: () => _BabyPageState());
}

class _BabyPageState extends NyPage<BabyPage> {
  final BabyController _controller = BabyController();
  final List<Map<String, dynamic>> _babies = [];

  Future<void> _load() async {
    try {
      final profiles = await _controller.fetchBabyProfiles();
      setState(() {
        _babies
          ..clear()
          ..addAll(profiles.map((b) => {
                "Id": b["id"].toString(),
                "Name": (b["name"] ?? "").toString(),
                "DOB": _formatDate(b["dob"]),
                "Term": (b["term"]?.toString() ?? ""),
                "Weight": (b["weight"]?.toString() ?? ""),
              }));
      });
    } catch (e) {
      NyLogger.error("❌ load babies: $e");
      showToastSorry(description: "Failed to load babies");
    }
  }

  static String _formatDate(dynamic dob) {
    // Handles Firestore Timestamp, millis, or ISO string
    try {
      if (dob == null) return "";
      if (dob is Map && dob["_seconds"] != null) {
        return DateTime.fromMillisecondsSinceEpoch((dob["_seconds"] as int) * 1000)
            .toIso8601String()
            .substring(0, 10);
      }
      if (dob is int) {
        return DateTime.fromMillisecondsSinceEpoch(dob).toIso8601String().substring(0, 10);
      }
      return DateTime.parse(dob.toString()).toIso8601String().substring(0, 10);
    } catch (_) {
      return dob.toString();
    }
  }

  @override
  get init => () => _load();

  @override
  Widget view(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Babies", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: _babies.isEmpty
            ? const Center(child: Text("No baby profiles yet"))
            : ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                itemCount: _babies.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (_, i) {
                  final b = _babies[i];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(b["Name"] ?? "", style: t.titleMedium),
                    subtitle: Text(
                      [
                        if ((b["DOB"] ?? "").toString().isNotEmpty) "DOB: ${b["DOB"]}",
                        if ((b["Term"] ?? "").toString().isNotEmpty) "Term: ${b["Term"]}",
                        if ((b["Weight"] ?? "").toString().isNotEmpty) "Weight: ${b["Weight"]} kg",
                      ].join(" • "),
                      style: t.bodyMedium,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: "Edit",
                          icon: const Icon(Icons.edit),
                          onPressed: () => _openBabyDialog(mode: "edit", initial: b),
                        ),
                        IconButton(
                          tooltip: "Delete",
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _confirmDelete(b["Id"]!, b["Name"] ?? "this baby"),
                        ),
                      ],
                    ),
                    onTap: () => _openBabyDialog(mode: "edit", initial: b),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openBabyDialog(mode: "add"),
        icon: const Icon(Icons.add),
        label: const Text("Add Baby"),
      ),
    );
  }

  Future<void> _confirmDelete(String id, String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete baby"),
        content: Text("Are you sure you want to delete \"$name\"?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete")),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await _controller.deleteBaby(babyId: id);
      showToastSuccess(description: "Baby deleted");
      await _load();
    } catch (e) {
      showToastSorry(description: e.toString());
    }
  }

  Future<void> _openBabyDialog({required String mode, Map<String, dynamic>? initial}) async {
    final isAdd = mode == "add";
    final form = isAdd ? CreateBabyForm() : EditBabyForm();

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: Text(isAdd ? "Create Baby Profile" : "Edit Baby Profile"),
          content: SingleChildScrollView(
            child: NyForm(
              form: form,
              initialData: isAdd
                  ? const {}
                  : {
                      "Name": initial?["Name"] ?? "",
                      "Date of Birth": initial?["DOB"] ?? "",
                      if ((initial?["Term"] ?? "").toString().isNotEmpty) "Term (weeks)": initial?["Term"],
                      if ((initial?["Weight"] ?? "").toString().isNotEmpty) "Weight (kg)": initial?["Weight"],
                    },
              footer: Button.primary(
                text: isAdd ? "Create" : "Save",
                submitForm: (form, (data) async {
                  try {
                    final name = (data["Name"] ?? "").toString().trim();
                    final dob  = (data["Date of Birth"] ?? "").toString().trim(); // yyyy-mm-dd

                    if (isAdd) {
                      if (name.isEmpty || dob.isEmpty) {
                        showToastSorry(description: "Please fill all fields");
                        return;
                      }
                      await _controller.createBaby(name: name, dob: dob);
                      if (context.mounted) Navigator.pop(ctx);
                      showToastSuccess(description: "Baby created");
                      await _load();
                    } else {
                      final id = (initial?["Id"] ?? "").toString();
                      if (id.isEmpty) { showToastSorry(description: "Missing baby ID"); return; }
                      await _controller.editBaby(
                        babyId: id,
                        name: name.isEmpty ? null : name,
                        dob: dob.isEmpty ? null : dob,
                      );
                      if (context.mounted) Navigator.pop(ctx);
                      showToastSuccess(description: "Baby updated");
                      await _load();
                    }
                  } catch (e, st) {
                    NyLogger.error("❌ baby submit: $e\n$st");
                    showToastSorry(description: e.toString());
                  }
                }),
              ),
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel"))],
        );
      },
    );
  }
}
