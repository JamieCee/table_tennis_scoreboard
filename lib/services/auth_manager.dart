import 'package:flutter/material.dart';
import 'package:table_tennis_scoreboard/services/secure_storage.dart';

class AuthManager with ChangeNotifier {
  final SecureStorage _secureStorage = SecureStorage();

  // A private variable to hold the state.
  bool _isAuthenticated = false;
  bool _isSubscribed = false;

  // A public getter for the state.
  bool get isAuthenticated => _isAuthenticated;
  bool get isSubscribed => _isSubscribed;

  Future<void> _loadInitialState() async {
    final token = await _secureStorage.getAccessToken();
    _isAuthenticated = token != null;
    if (_isAuthenticated) {
      _isSubscribed = await _secureStorage.isSubscribed();
    }
    notifyListeners();
  }

  AuthManager() {
    // Check the status immediately when the manager is created.
    checkAuthStatus();
  }

  // This method checks the token from storage and updates the state.
  Future<void> checkAuthStatus() async {
    final token = await _secureStorage.getAccessToken();
    _isAuthenticated = token != null;
    _isSubscribed = await _secureStorage.isSubscribed();
    // Notify any listeners (like our router) that the auth state has changed.
    notifyListeners();
  }

  // A method to call when the user logs in.
  Future<void> login(bool isSubscribed) async {
    // The actual token saving would happen elsewhere (e.g., your AuthController).
    // This method just updates the state and notifies listeners.
    _isAuthenticated = true;
    _isSubscribed = isSubscribed;

    notifyListeners();
  }

  // A method to call when the user logs out.
  Future<void> logout() async {
    await _secureStorage.clear();
    _isAuthenticated = false;
    _isSubscribed = false;
    notifyListeners();
  }
}
