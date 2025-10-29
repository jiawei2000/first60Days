import 'package:nylo_framework/nylo_framework.dart';

class EditBabyForm extends NyFormData {
  EditBabyForm() : super("baby_edit");
  @override
  fields() => [
    Field.text("Name", style: "compact"),
    Field.text("Date of Birth", style: "compact"), // optional
  ];
}

