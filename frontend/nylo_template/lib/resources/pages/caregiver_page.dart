import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';
import '/app/forms/caregiver_form.dart';
import '/app/forms/create_caregiver_form.dart';
import '/resources/widgets/buttons/buttons.dart';

class CaregiverPage extends NyStatefulWidget {
  static RouteView path = ("/caregiver", (_) => CaregiverPage());
  CaregiverPage({super.key}) : super(child: () => _CaregiverPageState());
}

class _CaregiverPageState extends NyPage<CaregiverPage> {
  /// Stubbed data – replace with DB later
  final List<Map<String, String>> _caregivers = [
    {"Name": "Jane Doe", "Detail": "Nanny"},
    {"Name": "Mary Peters", "Detail": "Grandmother"},
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
                submitForm: (form, (data) {
                  // map form data -> list item fields
                  final mapped = isAdd
                      ? {
                          "Name":   "${data["Username"] ?? ""}", // show username as title
                          "Detail": "${data["Email"] ?? ""}",    // show email as subtitle
                        }
                      : {
                          "Name":   "${data["Name"] ?? ""}",
                          "Detail": "${data["Detail"] ?? ""}",
                        };
                  Navigator.pop(ctx, mapped);
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
