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
    // Normalize to a fixed display timezone (SGT, UTC+8) to avoid off-by-one issues
    const int tzOffsetHours = 8; // Adjust if your app uses a different region
    try {
      if (dob == null) return "";
      DateTime dtUtc;
      if (dob is Map && (dob["_seconds"] != null || dob["seconds"] != null)) {
        final sec = (dob["_seconds"] ?? dob["seconds"]) as int;
        final nanos = dob["_nanoseconds"] ?? dob["nanoseconds"] ?? 0;
        final ms = sec * 1000 + ((nanos is int) ? (nanos ~/ 1000000) : 0);
        dtUtc = DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toUtc();
      } else if (dob is int) {
        // Treat epoch millis as UTC
        dtUtc = DateTime.fromMillisecondsSinceEpoch(dob, isUtc: true).toUtc();
      } else {
        final parsed = DateTime.tryParse(dob.toString());
        if (parsed == null) return dob.toString();
        dtUtc = parsed.toUtc();
      }
      final dtSgt = dtUtc.add(const Duration(hours: tzOffsetHours));
      final y = dtSgt.year.toString().padLeft(4, '0');
      final m = dtSgt.month.toString().padLeft(2, '0');
      final d = dtSgt.day.toString().padLeft(2, '0');
      return "$y-$m-$d";
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
                          onPressed: () => _openEditBabyDialogWithPicker(initial: b),
                        ),
                        IconButton(
                          tooltip: "Delete",
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _confirmDelete(b["Id"]!, b["Name"] ?? "this baby"),
                        ),
                      ],
                    ),
                    onTap: () => _openEditBabyDialogWithPicker(initial: b),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddBabyDialogWithPickers(),
        icon: const Icon(Icons.add),
        label: const Text("Add Baby"),
      ),
    );
  }

  // Local helpers for date handling (keep consistent within this file)
  String _fmtDate(DateTime d) => "${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
  DateTime? _tryParseIso(String s) => s.isEmpty ? null : DateTime.tryParse(s);
  
  Future<void> _openAddBabyDialogWithPickers() async {
    final nameCtrl = TextEditingController();
    final dobCtrl = TextEditingController();
    final eddCtrl = TextEditingController();
    final termCtrl = TextEditingController();
    final weightCtrl = TextEditingController();
    final healthCtrl = TextEditingController();

    Future<void> pickDate(TextEditingController c, {DateTime? first, DateTime? last, DateTime? initial}) async {
      final now = DateTime.now();
      final init = initial ?? _tryParseIso(c.text) ?? now;
      final picked = await showDatePicker(
        context: context,
        initialDate: init,
        firstDate: first ?? DateTime(2000),
        lastDate: last ?? DateTime(2100),
      );
      if (picked != null) c.text = _fmtDate(picked);
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Create Baby Profile"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: "Name"),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: dobCtrl,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: "Date of Birth",
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  onTap: () => pickDate(dobCtrl, last: DateTime.now()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: eddCtrl,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: "Expected Due Date",
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  onTap: () => pickDate(eddCtrl, first: DateTime(2000)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: termCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Term (weeks)"),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: weightCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: "Weight (kg)"),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: healthCtrl,
                  decoration: const InputDecoration(labelText: "Health Conditions"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
            FilledButton(
              onPressed: () async {
                try {
                  final name = nameCtrl.text.trim();
                  final dob = dobCtrl.text.trim();
                  final eDD = eddCtrl.text.trim();
                  final termS = termCtrl.text.trim();
                  final wtS = weightCtrl.text.trim();
                  final health = healthCtrl.text.trim();

                  if (name.isEmpty) { showToastSorry(description: "Please enter a name"); return; }
                  if (dob.isEmpty) { showToastSorry(description: "Please pick Date of Birth"); return; }
                  if (eDD.isEmpty) { showToastSorry(description: "Please pick Expected Due Date"); return; }
                  final term = int.tryParse(termS); if (term == null) { showToastSorry(description: "Term must be a whole number"); return; }
                  final weight = double.tryParse(wtS); if (weight == null) { showToastSorry(description: "Weight must be a number"); return; }

                  final ok = await _controller.createBaby(
                    name: name,
                    dob: dob,
                    expectedDueDate: eDD,
                    term: term,
                    weight: weight,
                    healthConditions: health,
                  );
                  if (!ok) {
                    showToastSorry(description: "Failed to create baby");
                    return;
                  }
                  if (context.mounted) Navigator.pop(ctx);
                  showToastSuccess(description: "Baby created");
                  await _load();
                } catch (e, st) {
                  NyLogger.error("Create baby error: $e\n$st");
                  showToastSorry(description: e.toString());
                }
              },
              child: const Text("Create"),
            ),
          ],
        );
      },
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

  String _toIsoDate(dynamic v) {
    if (v == null) return "";
    if (v is DateTime) return v.toIso8601String().substring(0, 10);

    final s = v.toString().trim();
    if (s.isEmpty) return "";

    // Already yyyy-MM-dd
    final iso10 = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (iso10.hasMatch(s)) return s;

    // yyyy/MM/dd
    final ymdSlash = RegExp(r'^(\d{4})\/(\d{2})\/(\d{2})$');
    final m1 = ymdSlash.firstMatch(s);
    if (m1 != null) {
      final yr = int.parse(m1.group(1)!);
      final mo = int.parse(m1.group(2)!);
      final dy = int.parse(m1.group(3)!);
      return DateTime(yr, mo, dy).toIso8601String().substring(0, 10);
    }

    // dd/MM/yyyy
    final dmySlash = RegExp(r'^(\d{1,2})\/(\d{1,2})\/(\d{4})$');
    final m2 = dmySlash.firstMatch(s);
    if (m2 != null) {
      final dy = int.parse(m2.group(1)!);
      final mo = int.parse(m2.group(2)!);
      final yr = int.parse(m2.group(3)!);
      return DateTime(yr, mo, dy).toIso8601String().substring(0, 10);
    }

    // dd-MM-yyyy
    final dmyDash = RegExp(r'^(\d{1,2})-(\d{1,2})-(\d{4})$');
    final m3 = dmyDash.firstMatch(s);
    if (m3 != null) {
      final dy = int.parse(m3.group(1)!);
      final mo = int.parse(m3.group(2)!);
      final yr = int.parse(m3.group(3)!);
      return DateTime(yr, mo, dy).toIso8601String().substring(0, 10);
    }

    // dd/MM/yyyy, HH:mm -> take date part
    if (s.contains(", ")) {
      final head = s.split(", ").first;
      final mm = dmySlash.firstMatch(head);
      if (mm != null) {
        final dy = int.parse(mm.group(1)!);
        final mo = int.parse(mm.group(2)!);
        final yr = int.parse(mm.group(3)!);
        return DateTime(yr, mo, dy).toIso8601String().substring(0, 10);
      }
    }

    // 19 Oct 2025 or 19 October 2025
    final monthMap = <String, int>{
      'jan': 1, 'january': 1,
      'feb': 2, 'february': 2,
      'mar': 3, 'march': 3,
      'apr': 4, 'april': 4,
      'may': 5,
      'jun': 6, 'june': 6,
      'jul': 7, 'july': 7,
      'aug': 8, 'august': 8,
      'sep': 9, 'sept': 9, 'september': 9,
      'oct': 10, 'october': 10,
      'nov': 11, 'november': 11,
      'dec': 12, 'december': 12,
    };
    final words = RegExp(r'^(\d{1,2})\s+([A-Za-z]+)\s+(\d{4})$').firstMatch(s);
    if (words != null) {
      final dy = int.parse(words.group(1)!);
      final monName = words.group(2)!.toLowerCase();
      final yr = int.parse(words.group(3)!);
      final mo = monthMap[monName];
      if (mo != null) {
        return DateTime(yr, mo, dy).toIso8601String().substring(0, 10);
      }
    }

    // Last resort: DateTime.parse (handles full ISO strings)
    final dt = DateTime.tryParse(s);
    return dt == null ? "" : dt.toIso8601String().substring(0, 10);
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
                    final name  = (data["Name"] ?? "").toString().trim();
                    final dob   = (data["Date of Birth"] ?? "").toString().trim();
                    if (isAdd) {
                      final name   = (data["Name"] ?? data["name"] ?? "").toString().trim();
                      final dob    = _toIsoDate(data["Date of Birth"] ?? data["dob"]);
                      final eDD    = _toIsoDate(data["Expected Due Date"] ?? data["expectedDueDate"]);
                      final termS  = (data["Term (weeks)"] ?? data["term"] ?? "").toString().trim();
                      final wtS    = (data["Weight (kg)"] ?? data["weight"] ?? "").toString().trim();
                      final health = (data["Health Conditions"] ?? data["healthConditions"] ?? "").toString().trim();

                      if (name.isEmpty) { showToastSorry(description: "Please enter a name"); return; }
                      if (dob.isEmpty) { showToastSorry(description: "Please enter a valid Date of Birth (e.g. 2025-10-19)"); return; }
                      if (eDD.isEmpty) { showToastSorry(description: "Please enter a valid Expected Due Date (e.g. 2025-10-19)"); return; }
                      if (termS.isEmpty) { showToastSorry(description: "Please enter term (weeks)"); return; }
                      if (wtS.isEmpty) { showToastSorry(description: "Please enter weight (kg)"); return; }
                      if (health.isEmpty) { showToastSorry(description: "Please enter health conditions (if none, type 'none')"); return; }

                      final term = int.tryParse(termS);
                      if (term == null) { showToastSorry(description: "Term must be a whole number"); return; }
                      final weight = double.tryParse(wtS);
                      if (weight == null) { showToastSorry(description: "Weight must be a number (e.g. 3.2)"); return; }

                      await _controller.createBaby(
                        name: name,
                        dob: dob,
                        expectedDueDate: eDD,
                        term: term,
                        weight: weight,
                        healthConditions: health,
                      );
                      if (context.mounted) Navigator.pop(ctx);
                      showToastSuccess(description: "Baby created");
                      await _load();
                    } else {
                      final id = (initial?["Id"] ?? "").toString();
                      if (id.isEmpty) { showToastSorry(description: "Missing baby ID"); return; }
                      final ok = await _controller.editBaby(
                        babyId: id,
                        name: name.isEmpty ? null : name,
                        dob:  dob.isEmpty  ? null : DateTime.tryParse(dob),
                      );
                      if (!ok) { showToastSorry(description: "Failed to update baby"); return; }
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

  Future<void> _openEditBabyDialogWithPicker({required Map<String, dynamic> initial}) async {
    final nameCtrl = TextEditingController(text: (initial["Name"] ?? "").toString());
    final dobCtrl = TextEditingController(text: (initial["DOB"] ?? "").toString());

    Future<void> pickDate(TextEditingController c, {DateTime? first, DateTime? last, DateTime? initial}) async {
      final now = DateTime.now();
      final init = initial ?? _tryParseIso(c.text) ?? now;
      final picked = await showDatePicker(
        context: context,
        initialDate: init,
        firstDate: first ?? DateTime(2000),
        lastDate: last ?? DateTime(2100),
      );
      if (picked != null) c.text = _fmtDate(picked);
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Edit Baby Profile"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: "Name"),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: dobCtrl,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: "Date of Birth",
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  onTap: () => pickDate(dobCtrl, last: DateTime.now()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
            FilledButton(
              onPressed: () async {
                try {
                  final id = (initial["Id"] ?? "").toString();
                  if (id.isEmpty) { showToastSorry(description: "Missing baby ID"); return; }

                  final name = nameCtrl.text.trim();
                  final dobText = dobCtrl.text.trim();
                  final dob = dobText.isEmpty ? null : DateTime.tryParse(dobText);

                  await _controller.editBaby(
                    babyId: id,
                    name: name.isEmpty ? null : name,
                    dob: dob,
                  );
                  if (context.mounted) Navigator.pop(ctx);
                  showToastSuccess(description: "Baby updated");
                  await _load();
                } catch (e, st) {
                  NyLogger.error("Edit baby error: $e\n$st");
                  showToastSorry(description: e.toString());
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }
}
