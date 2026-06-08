import 'package:flutter/material.dart';

import '../models/login_type.dart';
import '../models/user_model.dart';

class UserProvider with ChangeNotifier {
  User? _currentUser;
  String? _token;
  LoginType _loginType = LoginType.mongo;

  User? get currentUser => _currentUser;
  String? get token => _token;
  LoginType get loginType => _loginType;
  bool get isLoggedIn => _currentUser != null;

  void setUser(
    User user, {
    String? token,
    LoginType loginType = LoginType.mongo,
  }) {
    _currentUser = user;
    _token = token;
    _loginType = loginType;
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    _token = null;
    _loginType = LoginType.mongo;
    notifyListeners();
  }
}
