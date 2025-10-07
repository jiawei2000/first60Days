import 'package:nylo_framework/nylo_framework.dart';

class CaregiverForm extends NyFormData {
  CaregiverForm({String? name}) : super(name ?? "caregiver");

  @override
  fields() => [
        Field.text("Name", style: "compact"),
        [
          Field.currency("Price", currency: "usd", dummyData: "19.99", style: "compact"),
          Field.picker(
            "Favourite Color",
            options: ["Red", "Blue", "Green"],
            validate: FormValidator.contains(["Red", "Blue", "Green"]),
            style: "compact",
          ),
        ],
        Field.textArea("Bio", style: "compact"),
      ];

  value(String s) {}

  void setValue(String s, initial) {}
}
