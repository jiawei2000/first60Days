import 'package:nylo_framework/nylo_framework.dart';

class CaregiverCreateForm extends NyFormData {
  CaregiverCreateForm({String? name}) : super(name ?? "caregiver_create");

  dynamic formValue(String fieldName) {
    return this.data()[fieldName];
  }

  @override
  fields() => [
        Field.text("Username", validate: FormValidator().notEmpty(), style: "compact"),
        Field.email("Email",   validate: FormValidator.email().notEmpty(),       style: "compact"),
        Field.text("Phone Number", validate: FormValidator().notEmpty(), style: "compact"),
        Field.password("Password",
            validate: FormValidator().notEmpty().minLength(8), style: "compact"),
        Field.password("Confirm password",
            validate: FormValidator.custom((value) {
              return value == formValue("Password");
            }, message: "Passwords do not match"),
            style: "compact"),
      ];
}
