import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '/app/controllers/choose_baby_controller.dart';
import '/app/models/baby.dart';

class CreateBabyWidget extends StatefulWidget {
  final Function(Baby)? onBabyCreated;

  const CreateBabyWidget({Key? key, this.onBabyCreated}) : super(key: key);

  @override
  State<CreateBabyWidget> createState() => _CreateBabyWidgetState();
}

class _CreateBabyWidgetState extends State<CreateBabyWidget> {
  final _controller = ChooseBabyController();
  final _nameController = TextEditingController();
  final _weightController = TextEditingController();
  final _termController = TextEditingController();
  final _healthConditionsController = TextEditingController();

  DateTime? _dob;
  DateTime? _expectedDueDate;

  Future<void> _pickDate({
    required String title,
    required Function(DateTime) onPicked,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) onPicked(picked);
  }

  void _submit() async {
    final name = _nameController.text.trim();
    final weight = double.tryParse(_weightController.text.trim()) ?? 0;
    final term = int.tryParse(_termController.text.trim()) ?? 0;
    final healthConditions = _healthConditionsController.text.trim();

    if (name.isEmpty || _dob == null || _expectedDueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please provide Name, DOB, and Expected Due Date.")),
      );
      return;
    }

    final newBaby = await _controller.createBaby(
      name: name,
      dob: _dob!,
      expectedDueDate: _expectedDueDate!,
      term: term,
      weight: weight,
      healthConditions: healthConditions,
    );

    if (newBaby != null) {
      widget.onBabyCreated?.call(newBaby);
      Navigator.pop(context); // Close dialog
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to create baby")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Add Baby Profile"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Name"),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _pickDate(
                title: "Select DOB",
                onPicked: (date) => setState(() => _dob = date),
              ),
              child: Text(_dob == null
                  ? "Select DOB"
                  : "DOB: ${DateFormat('yyyy-MM-dd').format(_dob!)}"),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _pickDate(
                title: "Expected Due Date",
                onPicked: (date) => setState(() => _expectedDueDate = date),
              ),
              child: Text(_expectedDueDate == null
                  ? "Select Expected Due Date"
                  : "Due: ${DateFormat('yyyy-MM-dd').format(_expectedDueDate!)}"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _termController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Term (weeks)"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _weightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Weight (kg)"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _healthConditionsController,
              decoration: const InputDecoration(labelText: "Health Conditions"),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text("Add"),
        ),
      ],
    );
  }
}
