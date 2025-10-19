import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';
import '/config/decoders.dart';
import '/config/keys.dart';

class BabyApiService extends NyApiService {
  BabyApiService({BuildContext? buildContext})
      : super(buildContext, decoders: modelDecoders);

  @override
  String get baseUrl => getEnv('API_BASE_URL'); // e.g. http://10.0.2.2:3000/api

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Future<dynamic> createBaby({
    required String name,
    required String dob, // yyyy-mm-dd
  }) async {
    final token = await Keys.bearerToken.read() ?? "";
    final body = {"name": name, "dob": dob};
    NyLogger.info("→ POST /babyProfile/newBaby body=$body");
    return await network<dynamic>(
      request: (r) => r.post("/babyProfile/newBaby", data: body),
      headers: _headers(token),
    );
  }

  Future<dynamic> editBaby({
    required String babyId,
    String? name,
    String? dob,
  }) async {
    final token = await Keys.bearerToken.read() ?? "";
    final body = {"babyId": babyId, if (name != null) "name": name, if (dob != null) "dob": dob};
    NyLogger.info("→ PUT /babyProfile/editBaby body=$body");
    return await network<dynamic>(
      request: (r) => r.put("/babyProfile/editBaby", data: body),
      headers: _headers(token),
    );
  }

  Future<dynamic> deleteBaby({required String babyId}) async {
    final token = await Keys.bearerToken.read() ?? "";
    NyLogger.info("→ DELETE /babyProfile/delete body={babyId:$babyId}");
    return await network<dynamic>(
      request: (r) => r.delete("/babyProfile/delete", data: {"babyId": babyId}),
      headers: _headers(token),
    );
  }

  Future<Map<String, dynamic>> getBabyProfiles() async {
    final token = await Keys.bearerToken.read() ?? "";
    NyLogger.info("→ GET /babyProfiles");
    final res = await network<dynamic>(
      request: (r) => r.get("/babyProfiles"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    // Ensure non-null, correctly typed map
    return (res as Map<String, dynamic>?) ?? <String, dynamic>{};
  }


  Future<dynamic> getBabyById(String babyId) async {
    final token = await Keys.bearerToken.read() ?? "";
    NyLogger.info("→ GET /babyProfile/$babyId");
    return await network<dynamic>(
      request: (r) => r.get("/babyProfile/$babyId"),
      headers: _headers(token),
    );
  }
}
