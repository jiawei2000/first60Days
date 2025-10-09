import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';
import '/config/decoders.dart';
import '/config/keys.dart';

class CaregiverApiService extends NyApiService {
  CaregiverApiService({BuildContext? buildContext})
      : super(buildContext, decoders: modelDecoders);

  @override
  String get baseUrl => getEnv('API_BASE_URL') + "/users"; // http://10.0.2.2:3000/api/users

  /// POST /users/registerSub
  Future<dynamic> registerSub({
    required String email,
    required String password,
    required String phoneNo,
    required String username,
    required List<String> babyIDArr,
  }) async {
    final token = await Keys.bearerToken.read() ?? "";
    final body = {
      "email": email,
      "password": password,
      "phoneNo": phoneNo,
      "username": username,
      "babyIDArr": babyIDArr,
    };
    NyLogger.info("→ POST /users/registerSub body=$body"); // DEBUG

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

}
