import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../services/api_service.dart';

class ProfileProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  static const String _profileCacheKey = 'cached_user_profile';

  UserProfileModel? _profile;
  bool _isLoading = false;
  String? _errorMessage;

  UserProfileModel? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String get currency => _profile?.currency ?? '₹';
  String get timezone => _profile?.timezone ?? 'UTC+5:30';

  ProfileProvider() {
    _loadLocalProfile();
  }

  Future<void> _loadLocalProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_profileCacheKey);
      if (jsonStr != null) {
        final map = jsonDecode(jsonStr);
        _profile = UserProfileModel.fromJson(Map<String, dynamic>.from(map));
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> fetchProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final remote = await _api.getProfile();
      if (remote != null) {
        _profile = remote;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_profileCacheKey, jsonEncode(remote.toJson()));
      }
    } catch (e) {
      _errorMessage = e.toString();
      // Keep local profile on network error
      await _loadLocalProfile();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> updates) async {
    try {
      // 1. Immediately update local state & SharedPreferences for guaranteed UI responsiveness
      final currentMap = _profile?.toJson() ?? {};
      final mergedMap = {...currentMap, ...updates};
      _profile = UserProfileModel.fromJson(mergedMap);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_profileCacheKey, jsonEncode(mergedMap));
      notifyListeners();

      // 2. Attempt remote sync with backend API
      try {
        await _api.updateProfile(updates);
      } catch (remoteErr) {
        // If remote fails, enqueue for offline sync
        await _api.syncOfflineRequest(
          url: '/api/profile',
          method: 'PUT',
          body: updates,
        );
      }

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
