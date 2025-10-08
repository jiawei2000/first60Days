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
    required String dob, // in ISO 8601 format
  }) async {
    try {
      final baby = await _babyService.createBaby(name: name, dob: dob);
      return baby;
    } catch (e) {
      print("❌ Error creating baby: $e");
      return null;
    }
  }
}
