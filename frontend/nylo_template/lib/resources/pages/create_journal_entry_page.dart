import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';

import '/app/forms/journal_entry_form.dart';

class CreateJournalEntryPage extends NyStatefulWidget {
  static RouteView path =
      ("/create-journal-entry", (_) => CreateJournalEntryPage());

  CreateJournalEntryPage({super.key})
      : super(child: () => _CreateJournalEntryPageState());
}

class _CreateJournalEntryPageState extends NyPage<CreateJournalEntryPage> {
  JournalEntryForm form = JournalEntryForm();

  @override
  get init => () {};

  @override
  Widget view(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Create Journal Entry")),
      body: SafeArea(
        child: NyForm(
          form: form, 
          initialData: {
            "wake_up_time": DateTime.now(),
          },
        ),
      ),
    );
  }
}
