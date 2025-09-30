import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';

class ReadonlyTextField extends StatefulWidget {
  final TextEditingController textController;

  const ReadonlyTextField({super.key, required this.textController});

  @override
  createState() => _ReadonlyTextFieldState();
}

class _ReadonlyTextFieldState extends NyState<ReadonlyTextField> {
  @override
  get init => () {};

  @override
  Widget view(BuildContext context) {
    return Container(
      // height: 48,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Text(
        widget.textController.text,
        style: const TextStyle(fontSize: 20),
      ),
    );
  }
}
