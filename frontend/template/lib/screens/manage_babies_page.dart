import 'package:flutter/material.dart';
import '../model/baby.dart'; // uses Baby {id, name, avatarUrl?, age?}

class ManageBabiesPage extends StatefulWidget {
  const ManageBabiesPage({super.key, required this.initialBabies});
  final List<Baby> initialBabies;

  @override
  State<ManageBabiesPage> createState() => _ManageBabiesPageState();
}

class _ManageBabiesPageState extends State<ManageBabiesPage> {
  late List<Baby> babies;

  @override
  void initState() {
    super.initState();
    babies = [...widget.initialBabies];
  }

  void _addOrEdit({Baby? existing, int? index}) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final ageCtrl  = TextEditingController(text: existing?.age ?? '');

    final res = await showModalBottomSheet<Baby>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          left: 16, right: 16, top: 16,
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(existing == null ? 'Add Baby' : 'Edit Baby',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
          TextField(controller: ageCtrl,  decoration: const InputDecoration(labelText: 'Age (e.g. 6 Weeks)')),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) {
                return;
              }
              Navigator.pop(
                ctx,
                Baby(
                  id: existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(), // ✅ required
                  name: name,
                  avatarUrl: existing?.avatarUrl, // keep if editing
                  age: ageCtrl.text.trim(),       // nullable field
                ),
              );
            },
            child: const Text('Save'),
          ),
        ]),
      ),
    );

    if (res != null) {
      setState(() {
        if (index != null) {
          babies[index] = res;
        } else {
          babies.add(res);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Baby Information'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, babies),
            child: const Text('Done'),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: babies.length,
        separatorBuilder: (_, __) => const Divider(height: 1), // ✅ no double-underscore warning
        itemBuilder: (_, i) => ListTile(
          title: Text(babies[i].name),
          subtitle: Text(
            (babies[i].age == null || babies[i].age!.isEmpty) ? '-' : babies[i].age!,
          ), // ✅ guard nullable
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _addOrEdit(existing: babies[i], index: i),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => setState(() => babies.removeAt(i)),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEdit(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
