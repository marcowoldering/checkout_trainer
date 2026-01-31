import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CustomCheckoutRepository extends ChangeNotifier {
  Map<int, List<String>> _checkouts = {};

  CustomCheckoutRepository() {
    // _initCheckouts will be called in initState of the CheckoutsPage.
  }

  Map<int, List<String>> get checkouts => _checkouts;

  // Public method to initialize checkouts asynchronously
  Future<void> initCheckouts() async {
    await _initCheckouts();
    notifyListeners(); // Notify listeners after data is loaded.
  }

  // Private method to load checkouts from shared preferences
  Future<void> _initCheckouts() async {
    _checkouts = await _loadCheckouts();
  }

  Future<Map<int, List<String>>> _loadCheckouts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final checkoutsString = prefs.getString('checkouts');

      if (checkoutsString != null) {
        final decoded = jsonDecode(checkoutsString) as Map<String, dynamic>;
        return decoded.map((key, value) => MapEntry(
              int.parse(key),
              List<String>.from(value),
            ));
      }
    } catch (e) {
      // Silently fail and return empty map on error
    }

    return {}; // Return an empty map if no data exists or on error.
  }

  Future<void> addCheckout(int score, List<String> checkout) async {
    _checkouts[score] = checkout;

    await _saveCheckouts();
    notifyListeners();
  }

  Future<void> _saveCheckouts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_checkouts.map(
        (key, value) => MapEntry(key.toString(), value),
      ));
      await prefs.setString('checkouts', encoded);
    } catch (e) {
      // Silently fail on save error
    }
  }

  Future<void> removeCheckout(int score) async {
    _checkouts.remove(score);

    await _saveCheckouts();
    notifyListeners();
  }

  Future<void> clearCheckouts() async {
    _checkouts = {};

    await _saveCheckouts();
    notifyListeners();
  }

  Future<void> updateCheckout(int score, List<String> checkout) async {
    _checkouts[score] = checkout;

    await _saveCheckouts();
    notifyListeners();
  }
}