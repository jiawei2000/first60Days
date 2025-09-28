import 'package:intl/intl.dart';
import 'package:nylo_framework/nylo_framework.dart';
import 'package:flutter/material.dart';
import '/resources/widgets/buttons/buttons.dart';

/* JournalEntry Form
|--------------------------------------------------------------------------
| Usage: https://nylo.dev/docs/6.x/forms#how-it-works
| Casts: https://nylo.dev/docs/6.x/forms#form-casts
| Validation Rules: https://nylo.dev/docs/6.x/validation#validation-rules
|-------------------------------------------------------------------------- */

class JournalEntryForm extends NyFormData {
  JournalEntryForm({String? name}) : super(name ?? "journal_entry");

  @override
  fields() => [
        Field.text("Test", style: "default"),
        Field.text("Name",
            style: "default".extend(
              labelText: "Taking Outside",
              hintText: "Taking outside too",
              labelStyle: TextStyle(color: Colors.green, fontSize: 20),
              hintStyle: TextStyle(color: Colors.orange, fontSize: 20),
              decoration: (data, inputDecoration) {
                return inputDecoration.copyWith(
                  // labelStyle: TextStyle(color: Colors.blue, fontSize: 50),
                  hintStyle: TextStyle(color: Colors.red, fontSize: 50),
                  hintText: "Taking inside too",
                  // labelText: "Taking inside"
                );
              },
            )),
        Field(
          "Wake up Time",
          value: "",
          style: "default".extend(
            labelText: ("Wake Up Time"),
            decoration: (data, inputDecoration) {
              return inputDecoration.copyWith(
                labelStyle: TextStyle(color: Colors.blue, fontSize: 30),
              );
            },
          ),
          // style: TextStyle(fontSize: 50, color: Colors.blue),
          cast: FormCast.datetime(
            dateFormat: DateFormat("dd-MM-yyyy hh:mm"),
            pickerPlatform: DateTimeFieldPickerPlatform.cupertino,
            firstDate: DateTime.now().add(Duration(days: -365)),
            lastDate: DateTime.now().add(Duration(days: 365)),
            style: TextStyle(fontSize: 50, color: Colors.blue),
          ),
        ),
        [
          Field.currency(
            "Price",
            currency: "usd",
            dummyData: "19.99",
            style: "compact",
          ),
          Field.picker(
            "Favourite Color",
            options: ["Red", "Blue", "Green"],
            validate: FormValidator.contains(["Red", "Blue", "Green"]),
            style: "compact",
          ),
        ],
        Field.textArea("Bio", style: "compact"),
      ];
}
