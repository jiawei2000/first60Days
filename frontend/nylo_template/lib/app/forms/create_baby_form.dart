import 'package:nylo_framework/nylo_framework.dart';

class CreateBabyForm extends NyFormData {
  CreateBabyForm() : super("baby_create");
  @override
  fields() => [
    Field.text("Name", validate: FormValidator.rule("not_empty"), style: "compact"),
    Field.text("Date of Birth", validate: FormValidator.rule("not_empty"), style: "compact"), // yyyy-mm-dd
  ];
}

