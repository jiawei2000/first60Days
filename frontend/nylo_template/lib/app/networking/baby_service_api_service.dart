import 'package:flutter/material.dart';
import '/config/decoders.dart';
import 'package:nylo_framework/nylo_framework.dart';
import '/app/models/baby.dart';
import '/config/keys.dart';

class BabyServiceApiService extends NyApiService {
  BabyServiceApiService({BuildContext? buildContext})
      : super(buildContext, decoders: modelDecoders);

  @override
  String get baseUrl => getEnv('API_BASE_URL');

  /// ✅ Get all baby profiles
  Future<List<Baby>?> getAllBabies() async {
    String token = await Keys.bearerToken.read() ?? "";

    final response = await network<dynamic>(
      request: (request) => request.get("/babies"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response != null && response['babyProfiles'] != null) {
      return List<Baby>.from(
        (response['babyProfiles'] as List).map((e) => Baby.fromJson(e)),
      );
    }

    return null;
  }

  /// ✅ Get baby by ID
  Future<Baby?> getBabyById(String babyId) async {
    String token = await Keys.bearerToken.read() ?? "";

    final response = await network<dynamic>(
      request: (request) => request.get("/babies/$babyId"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response != null) {
      return Baby.fromJson(response);
    }

    return null;
  }

/// ✅ Create a new baby
Future<Baby?> createBaby({
  required String name,
  required DateTime dob,
  required DateTime expectedDueDate,
  required int term,
  required double weight,
  required String healthConditions,
}) async {
  String token = await Keys.bearerToken.read() ?? "";

  final response = await network<dynamic>(
    request: (request) => request.post("/babies", data: {
      "name": name,
      "dob": dob.toIso8601String(),
      "expectedDueDate": expectedDueDate.toIso8601String(),
      "term": term,
      "weight": weight,
      "healthConditions": healthConditions,
    }),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  if (response != null) {
    return Baby.fromJson(response);
  }

  return null;
}

  /// Update an existing baby
  Future<Baby?> updateBaby({
    required String babyId,
    String? name,
    DateTime? dob,
    DateTime? expectedDueDate,
    int? term,
    double? weight,
    String? healthConditions,
  }) async {
    String token = await Keys.bearerToken.read() ?? "";
    final Map<String, dynamic> body = {
      if (name != null) "name": name,
      if (dob != null) "dob": dob.toIso8601String(),
      if (expectedDueDate != null) "expectedDueDate": expectedDueDate.toIso8601String(),
      if (term != null) "term": term,
      if (weight != null) "weight": weight,
      if (healthConditions != null) "healthConditions": healthConditions,
    };

    final response = await network<dynamic>(
      request: (request) => request.put("/babies/$babyId", data: body),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response != null) {
      return Baby.fromJson(response);
    }

    return null;
  }

/// ✅ Get current week number for a baby by babyId
Future<int?> getWeekNo(String babyId) async {
  String token = await Keys.bearerToken.read() ?? "";

  final response = await network<dynamic>(
    request: (request) => request.get("/babies/weekNo/$babyId"),
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
