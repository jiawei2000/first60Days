import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';
import '/app/forms/caregiver_form.dart';
import '/app/forms/create_caregiver_form.dart';
import '/resources/widgets/buttons/buttons.dart';
import '/app/networking/caregiver_api_service.dart';
import '/app/controllers/caregiver_controller.dart';

class CaregiverPage extends NyStatefulWidget {
  static RouteView path = ("/caregiver", (_) => CaregiverPage());
  CaregiverPage({super.key}) : super(child: () => _CaregiverPageState());
}

class _CaregiverPageState extends NyPage<CaregiverPage> {
  /// Stubbed data – replace with DB later
  final CaregiverController _controller = CaregiverController();

  final List<Map<String, dynamic>> _caregivers = [];

  Future<void> _loadCaregivers() async {
    try {
      final result = await _controller.fetchCaregivers();
      setState(() {
        _caregivers
          ..clear()
          ..addAll(result.map((c) => {
                "Name": c["username"].toString(),
                "Detail": c["relation"] ?? c["email"] ?? "",
              }));
      });
    } catch (e) {
      print("❌ Error loading caregivers: $e");
      showToastSorry(description: "Failed to load caregivers");
    }
  }

  @override
  get init => () => _loadCaregivers();

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
              subtitle: Text(c["Detail"] ?? "", style: t.bodyMedium),
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
    final isAdd = mode == "add";
    final NyFormData form = isAdd ? CaregiverCreateForm() : CaregiverForm();

    final result = await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: Text(isAdd ? "Create Caregiver Profile" : "Edit Caregiver"),
          content: SingleChildScrollView(
            child: NyForm(
              form: form,
              initialData: isAdd
                  ? const {}
                  : {
                      if (initial?["Name"] != null) "Name": initial!["Name"],
                      if (initial?["Detail"] != null) "Detail": initial!["Detail"],
                    },
              footer: Button.primary(
                text: isAdd ? "Create" : "Save",
submitForm: (form, (data) async {
  try {
    // DEBUG: see exactly what NyForm is giving us
    print("NyForm data => $data");

final username = (data["username"] ?? "").toString().trim();
final email    = (data["email"] ?? "").toString().trim().toLowerCase();
final phone    = (data["phone_number"] ?? "").toString().trim();
final password = (data["password"] ?? "").toString();

    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      showToastSorry(description: "Please fill in Username, Email and Password");
      return;
    }

    print("→ creating caregiver payload: {username: $username, email: $email, phoneNo: $phone}");

    final babyIDs = <String>["W6bOM4UJxxfbo0bktsm0"]; // TODO: use real IDs

    final result = await api<CaregiverApiService>(
      (svc) => svc.registerSub(
        email: email,
        password: password,
        phoneNo: phone,
        username: username,
        babyIDArr: babyIDs,
      ),
      onError: (e) {
        final msg = e.response?.data?['error']?.toString() ??
            e.message ??
            "Create failed";
        showToastSorry(description: msg);
      },
    );

    if (result == null) return;

    final createdId = result['id']?.toString();
    print("✅ created caregiver: id=$createdId, resp=$result");

    Navigator.pop(ctx, {"Name": username, "Detail": email});
    showToastSuccess(description: createdId != null
        ? "Caregiver created (id: $createdId)"
        : "Caregiver created");
  } catch (e, st) {
    print("❌ submit error: $e\n$st");
    showToastSorry(description: e.toString());
  }
}),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ],
        );
      },
    );

    if (!mounted || result == null) return;

    setState(() {
      if (!isAdd && index != null) {
        _caregivers[index] = result;
      } else {
        _caregivers.add(result);
      }
    });
  }
}
