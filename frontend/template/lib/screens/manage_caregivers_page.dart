import 'package:flutter/material.dart';
import '../model/profile_models.dart';

class ManageCaregiversPage extends StatefulWidget {
  const ManageCaregiversPage({super.key, required this.initialCaregivers});
  final List<Caregiver> initialCaregivers;

  @override
  State<ManageCaregiversPage> createState() => _ManageCaregiversPageState();
}

class _ManageCaregiversPageState extends State<ManageCaregiversPage> {
  late List<Caregiver> caregivers;

  @override
  void initState() {
    super.initState();
    caregivers = [...widget.initialCaregivers];
  }

  void _addOrEdit({Caregiver? existing, int? index}) async {
    final formKey = GlobalKey<FormState>();
    final username = TextEditingController(text: existing?.username ?? '');
    final email    = TextEditingController(text: existing?.email ?? '');
    final phone    = TextEditingController(text: existing?.phone ?? '');
    final pwd      = TextEditingController();
    final pwd2     = TextEditingController();

    final res = await showModalBottomSheet<Caregiver>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          left: 16, right: 16, top: 16,
        ),
        child: Form(
          key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(existing == null ? 'Create Caregiver Profile' : 'Edit Caregiver',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextFormField(
              controller: username,
              decoration: const InputDecoration(labelText: 'Username*'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            TextFormField(
              controller: email,
              decoration: const InputDecoration(labelText: 'Email*'),
              keyboardType: TextInputType.emailAddress,
              validator: (v) => (v != null && v.contains('@')) ? null : 'Enter a valid email',
            ),
            TextFormField(
              controller: phone,
              decoration: const InputDecoration(labelText: 'Phone Number'),
              keyboardType: TextInputType.phone,
            ),
            TextFormField(
              controller: pwd,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password*'),
              validator: (v) => existing == null
                  ? ((v == null || v.length < 6) ? 'Min 6 chars' : null)
                  : null,
            ),
            TextFormField(
              controller: pwd2,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirm password*'),
              validator: (v) => existing == null
                  ? (v != pwd.text ? 'Passwords do not match' : null)
                  : null,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(
                  ctx,
                  Caregiver(
                    username: username.text.trim(),
                    email: email.text.trim(),
                    phone: phone.text.trim(),
                    password: pwd.text.isEmpty ? existing?.password : pwd.text,
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ]),
        ),
      ),
    );

    if (res != null) {
      setState(() {
        if (index != null) caregivers[index] = res; else caregivers.add(res);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Caregivers'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, caregivers),
            child: const Text('Done'),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: caregivers.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final cg = caregivers[i];
          return ListTile(
            title: Text(cg.username),
            subtitle: Text('${cg.email}${cg.phone.isEmpty ? '' : ' · ${cg.phone}'}'),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(icon: const Icon(Icons.edit), onPressed: () => _addOrEdit(existing: cg, index: i)),
              IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => setState(() => caregivers.removeAt(i))),
            ]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEdit(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
