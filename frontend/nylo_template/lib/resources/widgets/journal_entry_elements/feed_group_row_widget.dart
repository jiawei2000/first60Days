import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';
import 'package:flutter/services.dart';

class FeedGroupRow extends StatefulWidget {
  const FeedGroupRow({super.key});

  @override
  createState() => _FeedGroupRowState();
}

class _FeedGroupRowState extends NyState<FeedGroupRow> {
  final typeController = TextEditingController();
  final valueController = TextEditingController();

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
        typeController.text = typeItems[0].value;
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
                  value: typeController.text,
                  underline: const SizedBox(),
                  onChanged: (selectedValue) {
                    setState(
                      () {
                        typeController.text = selectedValue;
                      },
                    );
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
                        controller: valueController,
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
                      feedUnits[typeController.text] ?? "-",
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
