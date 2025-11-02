import 'package:nylo_framework/nylo_framework.dart';

class CreateBabyForm extends NyFormData {
  CreateBabyForm() : super("baby_create");

  @override
  fields() => [
    Field.text("Name", validate: FormValidator.rule("not_empty"), style: "compact"),
    Field.text("Date of Birth", validate: FormValidator.rule("not_empty"), style: "compact"), // yyyy-mm-dd
    Field.text("Expected Due Date", validate: FormValidator.rule("not_empty"), style: "compact"), // yyyy-mm-dd
    Field.text("Term (weeks)", validate: FormValidator.rule("not_empty"), style: "compact"),
    Field.text("Weight (kg)", validate: FormValidator.rule("not_empty"), style: "compact"),
    Field.text("Health Conditions", validate: FormValidator.rule("not_empty"), style: "compact"),
  ];
}
