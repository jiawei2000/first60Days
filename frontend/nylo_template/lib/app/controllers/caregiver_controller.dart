import 'package:flutter/widgets.dart';
import '/app/controllers/controller.dart';
import '/app/networking/caregiver_api_service.dart';

class CaregiverController extends Controller {
  final CaregiverApiService _caregiverApiService = CaregiverApiService();

  @override
  construct(BuildContext context) async {
    super.construct(context);
  }

  /// Get all caregivers (sub-accounts) linked to the logged-in user
  Future<List<dynamic>> fetchCaregivers() async {
    try {
      final result = await _caregiverApiService.getSubAccounts();
      return result;
    } catch (e) {
      print("❌ Error fetching caregivers: $e");
      return [];
    }
  }

  /// Create a new caregiver (sub-account)
  Future<dynamic> createCaregiver({
    required String email,
    required String password,
    required String phoneNo,
    required String username,
    required List<String> babyIDArr,
    String? relation, // ← add
  }) async {
    try {
      final result = await _caregiverApiService.registerSub(
        email: email,
        password: password,
        phoneNo: phoneNo,
        username: username,
        babyIDArr: babyIDArr,
        relation: relation, // ← add
      );
      print("✅ Created caregiver: $result");
      return result;
    } catch (e) {
      print("❌ Error creating caregiver: $e");
      rethrow;
    }
  }

  Future<void> updateCaregiverUsername({
    required String userId,
    required String newUsername,
  }) async {
    await _caregiverApiService.updateUsername(
      userId: userId,
      newUsername: newUsername,
    );
  }
}
