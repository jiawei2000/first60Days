import 'package:nylo_framework/nylo_framework.dart';

class CaregiverForm extends NyFormData {
  CaregiverForm({String? name}) : super(name ?? "caregiver");

  @override
  @override
  fields() => [
    Field.text("Name",
      validate: FormValidator().notEmpty(),
      style: "compact",
    ),
    Field.text("Detail",
      style: "compact",
    ),
  ];
}
