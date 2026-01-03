import 'package:flutter/material.dart';

/// Manages the global state of whether the user is actively controlling a match.
///
/// This allows widgets like the AppDrawer to dynamically change their UI
/// without needing direct access to a MatchController.
class MatchStateManager with ChangeNotifier {
  bool _isControllingMatch = false;

  /// Returns true if the user is currently in a controller role for a match.
  bool get isControllingMatch => _isControllingMatch;

  /// Sets the state to "controlling a match" and notifies listeners.
  ///
  /// This should be called when a match is created or resumed in controller mode.
  void startControlling() {
    if (!_isControllingMatch) {
      _isControllingMatch = true;
      notifyListeners();
    }
  }

  /// Sets the state to "not controlling a match" and notifies listeners.
  ///
  /// This should be called when a match is finished, deleted, or the
  /// controller screen is disposed.
  void stopControlling() {
    if (_isControllingMatch) {
      _isControllingMatch = false;
      notifyListeners();
    }
  }
}
