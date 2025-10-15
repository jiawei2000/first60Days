import 'package:nylo_framework/nylo_framework.dart';

class EditCaregiverForm extends NyFormData {
  EditCaregiverForm() : super("caregiver_edit");

  @override
  fields() => [
    Field.text(
      "Username",
      validate: FormValidator().notEmpty(),
      style: "compact",
    ),
  ];
}
