import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';
import 'package:flutter/services.dart';

class FeedGroupRow extends StatefulWidget {
  final TextEditingController typeController;
  final TextEditingController valueController;
  final TextEditingController unitController;

  const FeedGroupRow(
      {super.key,
      required this.typeController,
      required this.valueController,
      required this.unitController});

  @override
  createState() => _FeedGroupRowState();
}

class _FeedGroupRowState extends NyState<FeedGroupRow> {
  final List<DropdownMenuItem<String>> typeItems = const [
    DropdownMenuItem(value: "EBM", child: Text("EBM")),
    DropdownMenuItem(value: "Formula", child: Text("Formula")),
    DropdownMenuItem(value: "Breast (Left)", child: Text("Breast (Left)")),
    DropdownMenuItem(value: "Breast (Right)", child: Text("Breast (Right)")),
  ];

  Map<String, String> feedUnits = {
    "EBM": "ml",
    "Formula": "ml",
    "Breast (Left)": "min",
    "Breast (Right)": "min",
  };

  @override
  get init => () {
        if (widget.typeController.text.isEmpty) {
          widget.typeController.text = typeItems.first.value ?? "";
        }

        final mappedUnit = feedUnits[widget.typeController.text];
        if (mappedUnit != null) {
          widget.unitController.text = mappedUnit;
        } else if (widget.unitController.text.isEmpty) {
          widget.unitController.text = "-";
        }
      };

  @override
  Widget view(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 6,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Theme.of(context).dividerColor),
                  color: Theme.of(context).colorScheme.surface,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: DropdownButton<String>(
                  items: typeItems,
                  value: widget.typeController.text.isEmpty
                      ? null
                      : widget.typeController.text,
                  underline: const SizedBox(),
                  onChanged: (selectedValue) {
                    if (selectedValue == null) {
                      return;
                    }
                    setState(() {
                      widget.typeController.text = selectedValue;
                      widget.unitController.text =
                          feedUnits[selectedValue] ?? "-";
                    });
                  },
                ),
              ),
            ),
            Expanded(
              flex: 7,
              child: Container(
                margin: const EdgeInsets.only(left: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Theme.of(context).dividerColor),
                  color: Theme.of(context).colorScheme.surface,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: widget.valueController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Value',
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Unit label
                    Text(
                      widget.unitController.text,
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),
          ],
        )
      ],
    );
  }
}
