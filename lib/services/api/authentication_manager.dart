import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthenticationManager extends ChangeNotifier {
  static const _tokenKey = 'auth_token';
  String? _token;
  bool _isSubscribed = false;

  String? get token => _token;
  bool get isAuthenticated => _token != null && !JwtDecoder.isExpired(_token!);

  // A flag to indicate that the initial token load is complete
  bool _isHydrated = false;
  bool get isHydrated => _isHydrated;

  AuthenticationManager() {
    _loadTokenFromStorage();
  }

  Future<void> _loadTokenFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);

    if (_token != null) {
      _checkSubscriptionStatus();
    }

    _isHydrated = true;
    notifyListeners(); // Notify router that initial check is complete
  }

  Future<void> login(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    _token = token;
    _checkSubscriptionStatus();
    notifyListeners(); // Notify listeners that auth state has changed
  }

  void _checkSubscriptionStatus() {
    if (_token == null) {
      _isSubscribed = false;
      return;
    }
    try {
      Map<String, dynamic> decodedToken = JwtDecoder.decode(_token!);
      // IMPORTANT: Adjust the keys based on your actual JWT payload structure
      final user = decodedToken['user'] as Map<String, dynamic>?;
      _isSubscribed = user?['tt_account_subscribed'] as bool? ?? false;
    } catch (e) {
      print("Error decoding JWT: $e");
      _isSubscribed = false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    _token = null;
    _isSubscribed = false;
    notifyListeners(); // Notify listeners of logout
  }
}
