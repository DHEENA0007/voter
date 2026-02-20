import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

/// Authentication state management
class AuthProvider with ChangeNotifier {
  final ApiService _api = ApiService();
  
  bool _isLoading = false;
  bool _isLoggedIn = false;
  String? _role;
  String? _error;
  Map<String, dynamic>? _voterData;
  Map<String, dynamic>? _userData;

  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  String? get role => _role;
  String? get error => _error;
  Map<String, dynamic>? get voterData => _voterData;
  Map<String, dynamic>? get userData => _userData;

  /// Initialize - check if already logged in
  Future<void> init() async {
    await _api.init();
    _isLoggedIn = _api.isLoggedIn;
    _role = _api.role;
    
    if (_isLoggedIn) {
      final prefs = await SharedPreferences.getInstance();
      final voterIdStored = prefs.getString(AppConstants.voterIdKey);
      if (voterIdStored != null) {
        _voterData = {'voter_id': voterIdStored};
      }
    }
    notifyListeners();
  }

  /// Admin Login
  Future<bool> adminLogin(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _api.adminLogin(username, password);
      await _api.saveAuth(result['token'], 'admin');
      _isLoggedIn = true;
      _role = 'admin';
      _userData = result['user'];
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Connection error. Please check your network.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Voter Login with Voter ID + Passcode
  Future<bool> voterLogin(String voterId, String passcode) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _api.voterLogin(voterId, passcode);
      await _api.saveAuth(result['token'], 'voter');
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.voterIdKey, voterId);
      
      _isLoggedIn = true;
      _role = 'voter';
      _voterData = result['voter'];
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Connection error. Please check your network.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }



  /// Voter Self-Registration
  Future<bool> voterRegister(Map<String, dynamic> data, {File? photo}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _api.voterRegister(data, photo: photo);
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Connection error. Please check your network.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Logout
  Future<void> logout() async {
    await _api.logout();
    _isLoggedIn = false;
    _role = null;
    _voterData = null;
    _userData = null;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
