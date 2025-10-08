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
}
