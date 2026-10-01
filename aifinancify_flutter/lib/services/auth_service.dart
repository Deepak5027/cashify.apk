import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static const String _clientId = '656035624895-lulvg768p4ii532jhqk8a2sb99cr3mt6.apps.googleusercontent.com';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? _clientId : null,
    serverClientId: kIsWeb ? null : _clientId,
    scopes: ['email', 'profile'],
  );

  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      // 1. Show account chooser native Android / Web Google OAuth popup
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null; // User cancelled
      }

      final prefs = await SharedPreferences.getInstance();
      final displayName = googleUser.displayName ?? googleUser.email.split('@')[0];
      final userEmail = googleUser.email.trim().toLowerCase();
      await prefs.setString('user_email', userEmail);
      await prefs.setString('user_name', displayName);

      // 2. Sync account details with cloud / local backend database
      final custom = prefs.getString('custom_server_url');
      final candidates = [
        custom,
        if (kIsWeb) ApiService.defaultLocalUrl,
        if (kIsWeb) ApiService.defaultAdbUrl,
        if (!kIsWeb) ApiService.defaultCloudUrl,
        if (!kIsWeb) ApiService.defaultLocalUrl,
        if (!kIsWeb) ApiService.defaultAdbUrl,
        "http://10.0.2.2:4000",
        "http://127.0.0.1:4000",
        "http://localhost:4000",
        ApiService.defaultCloudUrl,
      ].whereType<String>().toSet().toList();

      for (var url in candidates) {
        try {
          final Dio dio = Dio(BaseOptions(
            baseUrl: url,
            connectTimeout: const Duration(seconds: 3),
            receiveTimeout: const Duration(seconds: 3),
          ));
          final res = await dio.post('/auth/google/native', data: {
            'email': userEmail,
            'name': displayName,
            'image': googleUser.photoUrl,
          });

          if (res.data != null && res.data['token'] != null) {
            await _apiService.updateBaseUrl(url);
            await _apiService.saveToken(res.data['token']);
            return Map<String, dynamic>.from(res.data);
          }
        } catch (_) {
          continue;
        }
      }

      // Offline / Direct Google session fallback
      final fallbackUser = {
        'id': googleUser.id,
        'email': googleUser.email,
        'name': displayName,
        'picture': googleUser.photoUrl,
        'image': googleUser.photoUrl,
      };
      await _apiService.saveToken('google_auth_token_${googleUser.id}');
      return {
        'token': 'google_auth_token_${googleUser.id}',
        'user': fallbackUser,
      };
    } catch (e) {
      throw Exception('Google Sign-In failed: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _apiService.clearToken();
  }
}
