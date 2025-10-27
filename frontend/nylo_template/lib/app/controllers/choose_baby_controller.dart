import '/app/models/baby.dart';
import '/app/networking/baby_service_api_service.dart';

class ChooseBabyController {
  final BabyServiceApiService _babyService = BabyServiceApiService();

  Future<List<Baby>> fetchBabies() async {
    try {
      final result = await _babyService.getAllBabies();
      return result ?? [];
    } catch (e) {
      print("Error fetching babies: $e");
      return [];
    }
  }

  Future<Baby?> createBaby({
    required String name,
    required DateTime dob,
    required DateTime expectedDueDate,
    required int term,
    required double weight,
    String? gender,
    double? height,
    required String healthConditions,
  }) async {
  try {
    final response = await _babyService.createBaby(
      name: name,
      dob: dob,
      expectedDueDate: expectedDueDate,
      term: term,
      weight: weight,
      gender: gender,
      height: height,
      healthConditions: healthConditions,
    );

    if (response != null) {
      return response; // Already returns a Baby from service
    }

    return null;
  } catch (e) {
    print("❌ Error creating baby: $e");
    return null;
  }
}

}
