import 'package:flutter/widgets.dart';
import '/app/controllers/controller.dart';
import '/app/networking/baby_service_api_service.dart';

class BabyController extends Controller {
  final BabyServiceApiService _svc = BabyServiceApiService();

  @override
  construct(BuildContext context) async {
    super.construct(context);
  }

  Future<List<dynamic>> fetchBabyProfiles() async {
    try {
      final babies = await _svc.getAllBabies();
      if (babies == null) return <dynamic>[];
      return babies
          .map((b) => {
                "id": b.id,
                "name": b.name,
                "dob": b.dob?.toIso8601String(),
                "term": b.term,
                "weight": b.weight,
                "healthConditions": b.healthConditions,
              })
          .toList();
    } catch (_) {
      return <dynamic>[];
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
    try {
      final created = await _svc.createBaby(
        name: name,
        dob: DateTime.parse(dob),
        expectedDueDate: DateTime.parse(expectedDueDate),
        term: term,
        weight: weight,
        healthConditions: healthConditions,
      );
      return created != null;
    } catch (_) {
      return false;
    }
  }

  Future<bool> editBaby({
    required String babyId,
    String? name,
    DateTime? dob,
  }) async {
    try {
      final updated = await _svc.updateBaby(
        babyId: babyId,
        name: name,
        dob: dob,
      );
      return updated != null;
    } catch (_) {
      return false;
    }
  }

  Future<void> deleteBaby({required String babyId}) async {
    await _svc.deleteBaby(babyId: babyId);
  }
}
