import 'package:flutter/material.dart';

class AuthProvider with ChangeNotifier {
  String? _token;

  String? get token => _token;

  void setToken(String token) {
    _token = token;
    notifyListeners();
  }

  void clearToken() {
    _token = null;
    notifyListeners();
  }
}
