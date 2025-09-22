import 'package:flutter/material.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  String? _email;
  String? _userId;

  // ✅ New fields
  String? _username;
  List<String> _babyIds = [];
  List<String> _subAccountIds = [];
  String? _currentBabyId;

  // Getters
  String? get token => _token;
  String? get email => _email;
  String? get userId => _userId;
  String? get username => _username;
  List<String> get babyIds => _babyIds;
  List<String> get subAccountIds => _subAccountIds;
  String? get currentBabyId => _currentBabyId;

  // Set user info (extended but existing args still required)
  void setUser({
    required String token,
    required String email,
    required String userId,
    String? username,
    List<String>? babyIds,
    List<String>? subAccountIds,
  }) {
    _token = token;
    _email = email;
    _userId = userId;

    // ✅ Store new fields
    _username = username;
    _babyIds = babyIds ?? [];
    _subAccountIds = subAccountIds ?? [];

    notifyListeners();
  }
  
  void setCurrentBabyId(String babyId) {
  _currentBabyId = babyId;
  notifyListeners();
  }

  void clearToken() {
    _token = null;
    _userId = null;
    _email = null;

    _username = null;
    _babyIds = [];
    _subAccountIds = [];

    notifyListeners();
  }
}
