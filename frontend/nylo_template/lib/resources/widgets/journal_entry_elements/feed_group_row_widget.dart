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
  List<DropdownMenuItem> typeItems = [
    const DropdownMenuItem(value: "EBM", child: Text("EBM")),
    const DropdownMenuItem(value: "Formula", child: Text("Formula")),
    const DropdownMenuItem(
        value: "Breast (Left)", child: Text("Breast (Left)")),
    const DropdownMenuItem(
        value: "Breast (Right)", child: Text("Breast (Right)")),
  ];

  Map<String, String> feedUnits = {
    "EBM": "ml",
    "Formula": "ml",
    "Breast (Left)": "min",
    "Breast (Right)": "min",
  };

  @override
  get init => () {
        widget.typeController.text = typeItems[0].value;
        widget.unitController.text =
            feedUnits[widget.typeController.text] ?? "-";
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
                child: DropdownButton(
                  items: typeItems,
                  value: widget.typeController.text,
                  underline: const SizedBox(),
                  onChanged: (selectedValue) {
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
