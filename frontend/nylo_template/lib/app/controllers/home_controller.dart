import 'controller.dart';
import '/app/models/baby.dart';
import '/app/networking/baby_service_api_service.dart';

class HomeController extends Controller {
  final BabyServiceApiService _babyService = BabyServiceApiService();

  /// ✅ Get baby's current week number
  Future<int?> fetchWeekNo(String babyId) async {
    try {
      final weekNo = await _babyService.getWeekNo(babyId);
      return weekNo;
    } catch (e) {
      print("Error fetching week number: $e");
      return null;
    }
  }

  /// ✅ Get full baby profile by ID
  Future<Baby?> fetchBabyById(String babyId) async {
    try {
      final baby = await _babyService.getBabyById(babyId);
      return baby;
    } catch (e) {
      print("Error fetching baby: $e");
      return null;
    }
  }
}
