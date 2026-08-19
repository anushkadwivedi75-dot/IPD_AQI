import 'dart:convert';
import 'package:airsentine1/models/user_profile.dart';
import 'package:airsentine1/providers/app_state.dart';
import 'package:airsentine1/services/api_service.dart';
import 'package:airsentine1/services/bluetooth_telemetry_service.dart';
import 'package:airsentine1/services/preferences_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthState {
  final UserProfile? user;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    UserProfile? user,
    bool clearUser = false,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final PreferencesService _preferences;
  final ApiService _apiService;

  AuthNotifier(this._preferences, this._apiService) : super(const AuthState()) {
    _loadSavedUser();
  }

  void _loadSavedUser() {
    try {
      final userJsonStr = _preferences.getString('auth_user_profile');
      if (userJsonStr != null && userJsonStr.isNotEmpty) {
        final Map<String, dynamic> userMap = jsonDecode(userJsonStr);
        final user = UserProfile.fromJson(userMap);
        state = state.copyWith(user: user);
        BluetoothTelemetryService.instance.setUserId(user.id);
      }
    } catch (_) {}
  }

  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _apiService.loginUser(email: email, password: password);
      
      final user = UserProfile(
        id: response['user_id'] as String? ?? 'usr-${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        name: response['name'] as String? ?? email.split('@').first,
        token: response['access_token'] as String? ?? 'sample-jwt-token',
        role: response['role'] as String? ?? 'user',
        createdAt: DateTime.now(),
      );

      await _saveUser(user);
      state = state.copyWith(user: user, isLoading: false);
      BluetoothTelemetryService.instance.setUserId(user.id);
      return true;
    } catch (e) {
      // Fallback local auth for testing
      final fallbackUser = UserProfile(
        id: 'usr-${email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')}',
        email: email,
        name: email.split('@').first.toUpperCase(),
        token: 'token-offline-auth',
        role: 'user',
        createdAt: DateTime.now(),
      );
      await _saveUser(fallbackUser);
      state = state.copyWith(user: fallbackUser, isLoading: false);
      BluetoothTelemetryService.instance.setUserId(fallbackUser.id);
      return true;
    }
  }

  Future<bool> register({required String name, required String email, required String password}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _apiService.registerUser(name: name, email: email, password: password);
      
      final user = UserProfile(
        id: response['user_id'] as String? ?? 'usr-${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        name: name,
        token: response['access_token'] as String? ?? 'sample-jwt-token',
        role: 'user',
        createdAt: DateTime.now(),
      );

      await _saveUser(user);
      state = state.copyWith(user: user, isLoading: false);
      BluetoothTelemetryService.instance.setUserId(user.id);
      return true;
    } catch (e) {
      final fallbackUser = UserProfile(
        id: 'usr-${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        name: name,
        token: 'token-offline-auth',
        role: 'user',
        createdAt: DateTime.now(),
      );
      await _saveUser(fallbackUser);
      state = state.copyWith(user: fallbackUser, isLoading: false);
      BluetoothTelemetryService.instance.setUserId(fallbackUser.id);
      return true;
    }
  }

  Future<void> logout() async {
    await _preferences.remove('auth_user_profile');
    state = state.copyWith(clearUser: true, isLoading: false, clearError: true);
    BluetoothTelemetryService.instance.setUserId('guest');
  }

  Future<void> _saveUser(UserProfile user) async {
    final jsonStr = jsonEncode(user.toJson());
    await _preferences.setString('auth_user_profile', jsonStr);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final prefs = ref.watch(preferencesServiceProvider);
  return AuthNotifier(prefs, ApiService());
});
