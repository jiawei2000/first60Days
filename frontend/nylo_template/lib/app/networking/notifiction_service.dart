import 'package:flutter/material.dart';
import '/config/decoders.dart';
import 'package:nylo_framework/nylo_framework.dart';
import '/config/keys.dart';

class NotificationService extends NyApiService {
  NotificationService({BuildContext? buildContext})
      : super(
          buildContext,
          decoders: modelDecoders,
          baseOptions: (BaseOptions baseOptions) {
            return baseOptions
              ..connectTimeout = const Duration(seconds: 5)
              ..sendTimeout = const Duration(seconds: 5)
              ..receiveTimeout = const Duration(seconds: 5);
          },
        );

  @override
  String get baseUrl => "${getEnv('API_BASE_URL')}/notifications";

  Future<dynamic> getAllNotificationsForUser({required String userId}) async {
    String token = await Keys.bearerToken.read() ?? "";
    return await network<dynamic>(
      request: (request) => request.get("/all/$userId"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
  }

  Future<dynamic> getUnreadNotificationsForUser(
      {required String userId}) async {
    String token = await Keys.bearerToken.read() ?? "";
    return await network<dynamic>(
      request: (request) => request.get("/unread/$userId"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
  }
}
