import 'package:flutter/widgets.dart';
import '/app/controllers/controller.dart';
import '/app/networking/baby_api_service.dart';
import '/app/networking/baby_service_api_service.dart';

class BabyController extends Controller {
  final BabyApiService _api = BabyApiService();
  final BabyServiceApiService _svc = BabyServiceApiService();

  @override
  construct(BuildContext context) async {
    super.construct(context);
  }

  Future<List<dynamic>> fetchBabyProfiles() async {
    try {
      // Prefer /babies endpoint which your backend exposes
      final babies = await _svc.getAllBabies();
      if (babies == null) return <dynamic>[];
      return babies.map((b) => {
            "id": b.id,
            "name": b.name,
            "dob": b.dob?.toIso8601String(),
            "term": b.term,
            "weight": b.weight,
            "healthConditions": b.healthConditions,
          }).toList();
    } catch (_) {
      // Fallback to older endpoint if available
      try {
        final res = await _api.getBabyProfiles(); // { babyProfiles: [...] }
        return (res["babyProfiles"] as List?) ?? <dynamic>[];
      } catch (_) {
        return <dynamic>[];
      }
    }
  }

  Future<bool> createBaby({
    required String name,
    required String dob,
    required String expectedDueDate,
    required int term,
    required double weight,
    required String healthConditions,
  }) async {
    // Try the /babies endpoint first (expects DateTime)
    try {
      final created = await _svc.createBaby(
        name: name,
        dob: DateTime.parse(dob),
        expectedDueDate: DateTime.parse(expectedDueDate),
        term: term,
        weight: weight,
        healthConditions: healthConditions,
      );
      if (created != null) return true;
    } catch (_) {
      // fall through to legacy endpoint
    }

    // Fallback to legacy babyProfile endpoints (strings yyyy-MM-dd)
    try {
      final res = await _api.createBaby(
        name: name,
        dob: dob,
        expectedDueDate: expectedDueDate,
        term: term,
        weight: weight,
        healthConditions: healthConditions,
      );
      return res != null;
    } catch (_) {
      return false;
    }
  }

  Future<bool> editBaby({
    required String babyId,
    String? name,
    DateTime? dob,
  }) async {
    // Try modern /babies/:id endpoint first
    try {
      final updated = await _svc.updateBaby(
        babyId: babyId,
        name: name,
        dob: dob,
      );
      if (updated != null) return true;
    } catch (_) {
      // fall through to legacy endpoint
    }

    // Fallback to legacy endpoint
    final dobStr = dob == null ? null : dob.toIso8601String().substring(0, 10);
    try {
      final res = await _api.editBaby(babyId: babyId, name: name, dob: dobStr);
      return res != null;
    } catch (_) {
      return false;
    }
  }

  Future<void> deleteBaby({required String babyId}) async {
    await _api.deleteBaby(babyId: babyId);
  }
}
