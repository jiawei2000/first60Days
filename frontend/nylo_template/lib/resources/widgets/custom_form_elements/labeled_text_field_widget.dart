import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';
import 'labeled_field_widget.dart';

class LabeledTextField extends StatefulWidget {
  final String label;
  final TextEditingController textController;
  final String? hintText;
  final IconData? icon;

  const LabeledTextField(
      {super.key,
      required this.label,
      required this.textController,
      this.hintText,
      this.icon});

  @override
  createState() => _LabeledTextFieldState();
}

class _LabeledTextFieldState extends NyState<LabeledTextField> {
  @override
  get init => () {};

  @override
  Widget view(BuildContext context) {
    return Container(
      child: LabeledField(
        label: widget.label,
        icon: widget.icon,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Theme.of(context).dividerColor),
            color: Theme.of(context).colorScheme.surface,
          ),
          child: TextFormField(
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              hintText: widget.hintText ?? "",
            ),
            style: const TextStyle(fontSize: 18),
            controller: widget.textController,
          ),
        ),
      ),
    );
  }
}
