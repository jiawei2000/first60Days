import 'package:flutter/material.dart';
import '/config/decoders.dart';
import 'package:nylo_framework/nylo_framework.dart';
import 'package:flutter/widgets.dart';

class UserApiService extends NyApiService {
  UserApiService({BuildContext? buildContext})
      : super(buildContext, decoders: modelDecoders);

  @override
  String get baseUrl => getEnv('API_BASE_URL');

  Future<dynamic> login(
      {required String email, required String password}) async {
    return await network(
        request: (request) => request.post("/users/login", data: {
              "email": email,
              "password": password,
            }));
  }

  // Future login({required String email, required String password}) async {
  //   return await network(
  //     request: (request) {
  //       return request.post("/users/login", data: {
  //         "email": email,
  //         "password": password,
  //       });
  //     },
  //   );
  // }
}
