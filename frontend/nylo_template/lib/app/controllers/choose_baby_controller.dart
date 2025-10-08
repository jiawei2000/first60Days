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
}
