import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';
import '/config/decoders.dart';
import '/config/keys.dart';
import '/app/models/baby.dart';

class BabyServiceApiService extends NyApiService {
  BabyServiceApiService({BuildContext? buildContext})
      : super(buildContext, decoders: modelDecoders);

  @override
  String get baseUrl => getEnv('API_BASE_URL');

  // Get all baby profiles
  Future<List<Baby>?> getAllBabies() async {
    final token = await Keys.bearerToken.read() ?? '';
    final response = await network<dynamic>(
      request: (r) => r.get('/babies'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response != null) {
      // Accept either { babyProfiles: [...] } or a raw list
      final list = response is Map && response['babyProfiles'] is List
          ? response['babyProfiles'] as List
          : (response is List ? response : null);
      if (list != null) {
        return List<Baby>.from(list.map((e) => Baby.fromJson(e)));
      }
    }
    return null;
  }

  // Get baby by ID
  Future<Baby?> getBabyById(String babyId) async {
    final token = await Keys.bearerToken.read() ?? '';
    final response = await network<dynamic>(
      request: (r) => r.get('/babies/$babyId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response != null) return Baby.fromJson(response);
    return null;
  }

  // Create a new baby
  Future<Baby?> createBaby({
    required String name,
    required DateTime dob,
    required DateTime expectedDueDate,
    required int term,
    required double weight,
    required String healthConditions,
  }) async {
    final token = await Keys.bearerToken.read() ?? '';
    final response = await network<dynamic>(
      request: (r) => r.post('/babies', data: {
        'name': name,
        'dob': dob.toIso8601String(),
        'expectedDueDate': expectedDueDate.toIso8601String(),
        'term': term,
        'weight': weight,
        'healthConditions': healthConditions,
      }),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response != null) return Baby.fromJson(response);
    return null;
  }

  // Update an existing baby
  Future<Baby?> updateBaby({
    required String babyId,
    String? name,
    DateTime? dob,
    DateTime? expectedDueDate,
    int? term,
    double? weight,
    String? healthConditions,
  }) async {
    final token = await Keys.bearerToken.read() ?? '';
    final Map<String, dynamic> body = {
      if (name != null) 'name': name,
      if (dob != null) 'dob': dob.toIso8601String(),
      if (expectedDueDate != null) 'expectedDueDate': expectedDueDate.toIso8601String(),
      if (term != null) 'term': term,
      if (weight != null) 'weight': weight,
      if (healthConditions != null) 'healthConditions': healthConditions,
    };
    final response = await network<dynamic>(
      request: (r) => r.put('/babies/$babyId', data: body),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response != null) return Baby.fromJson(response);
    return null;
  }

  // Delete a baby by id
  Future<void> deleteBaby({required String babyId}) async {
    final token = await Keys.bearerToken.read() ?? '';
    await network<dynamic>(
      request: (r) => r.delete('/babies/$babyId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
  }

  // Get current week number for a baby by babyId
  Future<int?> getWeekNo(String babyId) async {
    final token = await Keys.bearerToken.read() ?? '';
    final response = await network<dynamic>(
      request: (r) => r.get('/babies/weekNo/$babyId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response != null && response['weekNo'] != null) {
      return response['weekNo'] as int;
    }
    return null;
  }
}
