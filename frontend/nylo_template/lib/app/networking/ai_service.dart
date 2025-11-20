import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';
import '/config/decoders.dart';
import '/config/keys.dart';

class AiService extends NyApiService {
  AiService({BuildContext? buildContext})
      : super(
          buildContext,
          decoders: modelDecoders,
          baseOptions: (BaseOptions baseOptions) {
            return baseOptions
              ..connectTimeout = const Duration(seconds: 10)
              ..sendTimeout = const Duration(seconds: 10)
              ..receiveTimeout = const Duration(seconds: 10);
          },
        );

  @override
  String get baseUrl => "${getEnv('API_BASE_URL')}/assistant";

  Future<dynamic> queryBabyAssistant({
    required String question,
    required String babyId,
  }) async {
    final token = await Keys.bearerToken.read() ?? "";
    return await network<dynamic>(
      request: (request) => request.post(
        "/babies/query/$babyId",
        data: {
          "question": question,
        },
      ),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
  }
}
