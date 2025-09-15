import 'package:flutter/material.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  String? _email;
  String? _userId;

  // Getters
  String? get token => _token;
  String? get email => _email;
  String? get userId => _userId;

  // Set user info
  void setUser({
    required String token,
    required String email,
    required String userId,
  }) {
    _token = token;
    _email = email;
    _userId = userId;
    notifyListeners();
  }

void clearToken() {
  _token = null;
  _userId = null;
  _email = null;
  notifyListeners();
}
}
