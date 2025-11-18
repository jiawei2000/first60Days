import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';
import '/config/decoders.dart';
import '/config/keys.dart';

class CaregiverApiService extends NyApiService {
  CaregiverApiService({BuildContext? buildContext})
      : super(buildContext, decoders: modelDecoders);

  @override
  String get baseUrl => getEnv('API_BASE_URL') + "/users"; // e.g. http://10.0.2.2:3000/api/users

  /// POST /users/registerSub
  Future<dynamic> registerSub({
    required String email,
    required String password,
    required String phoneNo,
    required String username,
    required List<String> babyIDArr,
    String? relation,
    String? name,
  }) async {
    final token = await Keys.bearerToken.read() ?? "";

    // Backend expects a "name" field; fall back to username if not provided.
    final Map<String, dynamic> body = {
      "email": email,
      "password": password,
      "phoneNo": phoneNo,
      "username": username,
      "name": (name == null || name.trim().isEmpty) ? username : name,
      "babyIDArr": babyIDArr,
      "relation": relation,
    }..removeWhere((k, v) => v == null || (v is String && v.trim().isEmpty));

    NyLogger.info("→ POST /users/registerSub body=$body");

    return await network<dynamic>(
      request: (request) => request.post("/registerSub", data: body),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
  }

  /// GET /users/subAccounts
  Future<List<dynamic>> getSubAccounts() async {
    final token = await Keys.bearerToken.read() ?? "";
    NyLogger.info("→ GET /users/subAccounts");

    final response = await network<dynamic>(
      request: (request) => request.get("/subAccounts"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return (response as List?) ?? [];
  }

  Future<dynamic> updateUsername({
    required String userId,
    required String newUsername,
  }) async {
    final token = await Keys.bearerToken.read() ?? "";
    return await network<dynamic>(
      request: (r) => r.put("/username/$userId", data: {"newUsername": newUsername}),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
  }
}

