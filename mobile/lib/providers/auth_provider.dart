import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/api_constants.dart';
import '../core/location/location_places.dart';
import '../core/network/api_client.dart';
import '../core/network/socket_service.dart';
import '../models/user.dart';
import '../repositories/auth_repository.dart';
import '../repositories/user_repository.dart';

enum AuthGate {
  unknown,
  needsOnboarding,
  unauthenticated,
  needsProfile,
  needsRole,
  needsLocation,
  ready,
}

class AuthState {
  final AuthGate gate;
  final User? user;
  final String? token;
  final String? error;
  final bool busy;
  final String? pendingPhone;

  const AuthState({
    this.gate = AuthGate.unknown,
    this.user,
    this.token,
    this.error,
    this.busy = false,
    this.pendingPhone,
  });

  AuthState copyWith({
    AuthGate? gate,
    User? user,
    String? token,
    String? error,
    bool? busy,
    String? pendingPhone,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return AuthState(
      gate: gate ?? this.gate,
      user: clearUser ? null : (user ?? this.user),
      token: token ?? this.token,
      error: clearError ? null : (error ?? this.error),
      busy: busy ?? this.busy,
      pendingPhone: pendingPhone ?? this.pendingPhone,
    );
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._ref) : super(const AuthState()) {
    bootstrap();
  }

  final Ref _ref;

  AuthRepository get _auth => AuthRepository(_ref.read(apiClientProvider));
  UserRepository get _users => UserRepository(_ref.read(apiClientProvider));

  Future<void> bootstrap() async {
    AuthGate nextGate = AuthGate.needsOnboarding;
    User? user;
    String? token;
    try {
      final store = _ref.read(localStoreProvider);
      final savedBase = await store.getApiBase();
      final resolvedBase = ApiConstants.resolveBaseUrl(saved: savedBase);
      _ref.read(apiBaseProvider.notifier).state = resolvedBase;
      final onboarded = await store.getOnboarded();
      token = await store.getToken();
      if (token == null || token.isEmpty) {
        nextGate = onboarded ? AuthGate.unauthenticated : AuthGate.needsOnboarding;
      } else {
        final me = await _auth.me();
        user = me;
        final storedRole = await store.getRole();
        var next = me;
        if (storedRole != null && storedRole.isNotEmpty) {
          next = next.copyWith(role: storedRole);
        }
        nextGate = _gateFor(next, storedRole: storedRole);
        _ref.read(socketServiceProvider).connect();
      }
    } catch (e) {
      debugPrint('bootstrap: $e');
      await _ref.read(localStoreProvider).clearSession();
      final onboarded = await _ref.read(localStoreProvider).getOnboarded();
      nextGate = onboarded ? AuthGate.unauthenticated : AuthGate.needsOnboarding;
      user = null;
      token = null;
    }

    await Future.delayed(const Duration(milliseconds: 800));
    state = AuthState(gate: nextGate, user: user, token: token, busy: false);
  }

  Future<void> completeOnboarding() async {
    await _ref.read(localStoreProvider).setOnboarded(true);
    state = const AuthState(gate: AuthGate.unauthenticated);
  }

  Future<void> sendOtp(String phone) async {
    state = state.copyWith(busy: true, clearError: true, pendingPhone: phone);
    try {
      await _auth.sendOtp(phone);
    } catch (e) {
      state = state.copyWith(error: e.toString(), pendingPhone: phone);
      rethrow;
    } finally {
      state = state.copyWith(busy: false);
    }
  }

  Future<void> verifyOtp(String otp) async {
    final phone = state.pendingPhone;
    if (phone == null) throw Exception('Enter your phone number first');
    state = state.copyWith(busy: true, clearError: true);
    try {
      final session = await _auth.verifyOtp(phone, otp);
      await _ref.read(localStoreProvider).setToken(session.accessToken);
      await _ref.read(localStoreProvider).setRefresh(session.refreshToken);
      final user = session.user ?? await _auth.me();
      await _applyUser(user, session.accessToken);
      _ref.read(socketServiceProvider).connect();
    } catch (e) {
      state = state.copyWith(busy: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> saveProfile({required String name, String? about, String? photoUrl}) async {
    state = state.copyWith(busy: true, clearError: true);
    try {
      final user = await _users.updateMe(name: name, about: about, photoUrl: photoUrl);
      await _applyUser(user.copyWith(name: name, about: about, photoUrl: photoUrl), state.token);
    } catch (e) {
      // Keep local progress so onboarding is not blocked if PATCH shape differs.
      final local = (state.user ?? User(id: 'me')).copyWith(
        name: name,
        about: about,
        photoUrl: photoUrl,
        profileComplete: true,
      );
      await _applyUser(local, state.token);
    }
  }

  Future<void> selectRole(String role) async {
    state = state.copyWith(busy: true, clearError: true);
    try {
      final updated = await _users.updateRole(role);
      await _ref.read(localStoreProvider).setRole(role);
      final merged = (state.user ?? updated).copyWith(role: role);
      state = AuthState(gate: AuthGate.ready, user: merged, token: state.token, busy: false);
    } catch (e) {
      await _ref.read(localStoreProvider).setRole(role);
      final merged = (state.user ?? const User(id: 'me')).copyWith(role: role);
      state = AuthState(gate: AuthGate.ready, user: merged, token: state.token, busy: false);
    }
  }

  Future<void> saveLocation({required double lat, required double lng, String? areaLabel}) async {
    state = state.copyWith(busy: true, clearError: true);
    try {
      await _users.updateLocation(lat: lat, lng: lng);
    } catch (_) {}
    if (areaLabel != null && areaLabel.isNotEmpty) {
      await _ref.read(localStoreProvider).setAreaLabel(areaLabel);
    }
    final merged = (state.user ?? const User(id: 'me')).copyWith(
      lat: lat,
      lng: lng,
      locationSet: true,
      areaLabel: areaLabel ?? state.user?.areaLabel ?? cityLabelFor(lat, lng),
    );
    await _applyUser(merged, state.token);
  }

  Future<void> switchRole(String role) async {
    await selectRole(role);
  }

  Future<void> logout() async {
    _ref.read(socketServiceProvider).dispose();
    await _ref.read(localStoreProvider).clearSession();
    state = const AuthState(gate: AuthGate.unauthenticated);
  }

  Future<void> refreshMe() async {
    try {
      final user = await _auth.me();
      await _applyUser(user, state.token);
    } catch (_) {}
  }

  Future<void> _applyUser(User user, String? token) async {
    final storedRole = await _ref.read(localStoreProvider).getRole();
    var next = user;
    if (storedRole != null && storedRole.isNotEmpty) {
      next = next.copyWith(role: storedRole);
    }
    final gate = _gateFor(next, storedRole: storedRole);
    state = AuthState(gate: gate, user: next, token: token, busy: false);
  }

  AuthGate _gateFor(User user, {String? storedRole}) {
    if (!user.hasName) return AuthGate.needsProfile;
    if (storedRole == null || storedRole.isEmpty) return AuthGate.needsRole;
    if (!user.locationSet) return AuthGate.needsLocation;
    return AuthGate.ready;
  }
}
