import '/app/models/baby.dart';
import '/app/networking/baby_service_api_service.dart';
import '/app/controllers/choose_baby_controller.dart';
import '/app/models/entry_planner.dart';
import '/app/networking/feeding_schedule_api_service.dart';
import '../app/controllers/feeding_schedule_controller.dart';
import '/app/networking/user_api_service.dart';
import '/app/controllers/login_controller.dart';
import '/app/networking/journal_api_service.dart';
import '/app/controllers/home_controller.dart';
import '/app/models/user.dart';
import '/app/networking/api_service.dart';
import '/app/models/journal_entry.dart';
import '/app/networking/caregiver_api_service.dart';

/* Model Decoders
|--------------------------------------------------------------------------
| Model decoders are used in 'app/networking/' for morphing json payloads
| into Models.
|
| Learn more https://nylo.dev/docs/6.x/decoders#model-decoders
|-------------------------------------------------------------------------- */

final Map<Type, dynamic> modelDecoders = {
  Map<String, dynamic>: (data) => Map<String, dynamic>.from(data),
  List<User>: (data) =>
      List.from(data).map((json) => User.fromJson(json)).toList(),
  List<JournalEntry>: (data) =>
      List.from(data).map((json) => JournalEntry.fromJson(json)).toList(),
  //
  User: (data) => User.fromJson(data),
  

  // User: (data) => User.fromJson(data),

  List<EntryPlanner>: (data) => List.from(data).map((json) => EntryPlanner.fromJson(json)).toList(),

  EntryPlanner: (data) => EntryPlanner.fromJson(data),

  List<Baby>: (data) => List.from(data).map((json) => Baby.fromJson(json)).toList(),

  Baby: (data) => Baby.fromJson(data),
};

/* API Decoders
| -------------------------------------------------------------------------
| API decoders are used when you need to access an API service using the
| 'api' helper. E.g. api<MyApiService>((request) => request.fetchData());
|
| Learn more https://nylo.dev/docs/6.x/decoders#api-decoders
|-------------------------------------------------------------------------- */

final Map<Type, dynamic> apiDecoders = {
  ApiService: () => ApiService(),

  // ...

  JournalApiService: JournalApiService(),

  UserApiService: UserApiService(),

  FeedingScheduleApiService: FeedingScheduleApiService(),

  CaregiverApiService: CaregiverApiService(), // ← add

  BabyServiceApiService: BabyServiceApiService(),
};

/* Controller Decoders
| -------------------------------------------------------------------------
| Controller are used in pages.
|
| Learn more https://nylo.dev/docs/6.x/controllers
|-------------------------------------------------------------------------- */
final Map<Type, dynamic> controllers = {
  HomeController: () => HomeController(),

  // ...

  LoginController: () => LoginController(),

  FeedingScheduleController: () => FeedingScheduleController(),

  ChooseBabyController: () => ChooseBabyController(),
};
