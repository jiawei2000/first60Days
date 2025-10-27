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
  final _heightController = TextEditingController();
  final _termController = TextEditingController();
  final _healthConditionsController = TextEditingController();

  DateTime? _dob;
  DateTime? _expectedDueDate;
  String? _gender; // 'Male' | 'Female' | 'Other'

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

    if (name.isEmpty || _expectedDueDate == null || _dob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please provide Name, Expected Due Date, and DOB.")),
      );
      return;
    }

    final height = _heightController.text.trim().isEmpty
        ? null
        : double.tryParse(_heightController.text.trim());
    if (_heightController.text.trim().isNotEmpty && height == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Height must be a number")),
      );
      return;
    }

    final newBaby = await _controller.createBaby(
      name: name,
      dob: _dob!,
      expectedDueDate: _expectedDueDate!,
      term: term,
      weight: weight,
      gender: _gender,
      height: height,
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
      title: const Text("Add Baby"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Name"),
            ),
            const SizedBox(height: 12),
            // EDD before DOB, change to read-only fields
            TextField(
              readOnly: true,
              decoration: InputDecoration(
                labelText: "Expected Due Date",
                suffixIcon: const Icon(Icons.calendar_today),
                hintText: _expectedDueDate == null
                    ? null
                    : DateFormat('yyyy-MM-dd').format(_expectedDueDate!),
              ),
              controller: TextEditingController(
                text: _expectedDueDate == null
                    ? ''
                    : DateFormat('yyyy-MM-dd').format(_expectedDueDate!),
              ),
              onTap: () => _pickDate(
                title: "Expected Due Date",
                onPicked: (date) => setState(() => _expectedDueDate = date),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              readOnly: true,
              decoration: InputDecoration(
                labelText: "Date of Birth",
                suffixIcon: const Icon(Icons.calendar_today),
                hintText:
                    _dob == null ? null : DateFormat('yyyy-MM-dd').format(_dob!),
              ),
              controller: TextEditingController(
                text:
                    _dob == null ? '' : DateFormat('yyyy-MM-dd').format(_dob!),
              ),
              onTap: () => _pickDate(
                title: "Select DOB",
                onPicked: (date) => setState(() => _dob = date),
              ),
            ),
            const SizedBox(height: 12),
            Theme(
              data: Theme.of(context).copyWith(
                highlightColor: Colors.transparent,
                hoverColor: Colors.transparent,
                focusColor: Colors.transparent,
                splashColor: Colors.transparent,
                canvasColor: Theme.of(context).colorScheme.surface,
              ),
              child: DropdownButtonFormField<String>(
                value: _gender,
                isExpanded: true,
                menuMaxHeight: 280,
                borderRadius: const BorderRadius.all(Radius.circular(12)),
                dropdownColor: Theme.of(context).colorScheme.surface,
                items: const [
                  DropdownMenuItem(value: 'Male', child: Text('Male')),
                  DropdownMenuItem(value: 'Female', child: Text('Female')),
                  DropdownMenuItem(
                      value: 'Other', child: Text('Other / Prefer not to say')),
                ],
                onChanged: (v) => setState(() => _gender = v),
                decoration: const InputDecoration(labelText: 'Gender'),
              ),
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
              controller: _heightController,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: "Height (cm) - optional"),
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
