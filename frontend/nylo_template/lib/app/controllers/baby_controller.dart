import 'package:flutter/widgets.dart';
import '/app/controllers/controller.dart';
import '/app/networking/baby_api_service.dart';

class BabyController extends Controller {
  final BabyApiService _api = BabyApiService();

  @override
  construct(BuildContext context) async {
    super.construct(context);
  }

  Future<List<dynamic>> fetchBabyProfiles() async {
    try {
      final res = await _api.getBabyProfiles(); // { babyProfiles: [...] }
      return (res["babyProfiles"] as List?) ?? <dynamic>[];
    } catch (_) {
      return <dynamic>[];
    }
  }

  Future<void> createBaby({
    required String name,
    required String dob,
  }) async {
    await _api.createBaby(name: name, dob: dob);
  }

  Future<void> editBaby({
    required String babyId,
    String? name,
    String? dob,
  }) async {
    await _api.editBaby(babyId: babyId, name: name, dob: dob);
  }

  Future<void> deleteBaby({required String babyId}) async {
    await _api.deleteBaby(babyId: babyId);
  }
}
