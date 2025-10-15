import 'package:flutter/material.dart';
import '/config/decoders.dart';
import 'package:nylo_framework/nylo_framework.dart';
import '/config/keys.dart';

class FeedingScheduleApiService extends NyApiService {
  FeedingScheduleApiService({BuildContext? buildContext})
      : super(buildContext, decoders: modelDecoders);

  @override
  String get baseUrl => getEnv('API_BASE_URL') + "/entryPlanner";

  Future<dynamic> getPlannerByBabyId({required String babyId}) async {
    String token = await Keys.bearerToken.read() ?? "";
    return await network<dynamic>(
      request: (request) => request.get("/$babyId"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
  }

  Future<dynamic> getPlannerById(
      {required String babyId, required String plannerId}) async {
    String token = await Keys.bearerToken.read() ?? "";
    return await network<dynamic>(
      request: (request) => request.get("/$babyId/$plannerId"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
  }

  Future<dynamic> createPlanner(
      {required String babyId, required Map<String, dynamic> data}) async {
    String token = await Keys.bearerToken.read() ?? "";
    return await network<dynamic>(
      request: (request) => request.post("/$babyId", data: data),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
  }

  Future<dynamic> updatePlannerById(
      {required String babyId,
      required String plannerId,
      required Map<String, dynamic> data}) async {
    String token = await Keys.bearerToken.read() ?? "";
    return await network<dynamic>(
      request: (request) => request.put("/$babyId", data: data),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
  }

  Future<dynamic> updateFeedTimingByPlannerId(
      {required String babyId,
      required String plannerId,
      required Map<String, dynamic> data}) async {
    String token = await Keys.bearerToken.read() ?? "";
    return await network<dynamic>(
      request: (request) =>
          request.put("/feedTimings/$babyId/$plannerId", data: data),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
  }
}
