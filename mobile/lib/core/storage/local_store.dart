import 'package:shared_preferences/shared_preferences.dart';

class LocalStore {
  static const _token = 'access_token';
  static const _refresh = 'refresh_token';
  static const _onboarded = 'onboarded';
  static const _apiBase = 'api_base';
  static const _radius = 'radius_km';
  static const _role = 'active_role';
  static const _themeMode = 'theme_mode';
  static const _savedWorkers = 'saved_workers';
  static const _savedJobs = 'saved_jobs';

  Future<SharedPreferences> get _p async => SharedPreferences.getInstance();

  Future<String?> getToken() async => (await _p).getString(_token);
  Future<void> setToken(String? value) async {
    final p = await _p;
    if (value == null || value.isEmpty) {
      await p.remove(_token);
    } else {
      await p.setString(_token, value);
    }
  }

  Future<String?> getRefresh() async => (await _p).getString(_refresh);
  Future<void> setRefresh(String? value) async {
    final p = await _p;
    if (value == null || value.isEmpty) {
      await p.remove(_refresh);
    } else {
      await p.setString(_refresh, value);
    }
  }

  Future<bool> getOnboarded() async => (await _p).getBool(_onboarded) ?? false;
  Future<void> setOnboarded(bool value) async => (await _p).setBool(_onboarded, value);

  Future<String?> getApiBase() async => (await _p).getString(_apiBase);
  Future<void> setApiBase(String? value) async {
    final p = await _p;
    if (value == null || value.isEmpty) {
      await p.remove(_apiBase);
    } else {
      await p.setString(_apiBase, value);
    }
  }

  Future<int> getRadiusKm() async => (await _p).getInt(_radius) ?? 5;
  Future<void> setRadiusKm(int km) async => (await _p).setInt(_radius, km);

  Future<String?> getRole() async => (await _p).getString(_role);
  Future<void> setRole(String? role) async {
    final p = await _p;
    if (role == null) {
      await p.remove(_role);
    } else {
      await p.setString(_role, role);
    }
  }

  Future<void> setProfilePhotoPath(String? path) async {
    final p = await _p;
    if (path == null || path.isEmpty) {
      await p.remove('profile_photo_path');
    } else {
      await p.setString('profile_photo_path', path);
    }
  }

  Future<String?> getProfilePhotoPath() async => (await _p).getString('profile_photo_path');

  Future<void> setAvailableNow(bool value) async => (await _p).setBool('available_now', value);

  Future<bool?> getAvailableNow() async => (await _p).getBool('available_now');

  Future<void> setAreaLabel(String? label) async {
    final p = await _p;
    if (label == null || label.isEmpty) {
      await p.remove('area_label');
    } else {
      await p.setString('area_label', label);
    }
  }

  Future<String?> getAreaLabel() async => (await _p).getString('area_label');

  Future<void> clearSession() async {
    final p = await _p;
    await p.remove(_token);
    await p.remove(_refresh);
  }

  Future<String?> getThemeMode() async => (await _p).getString(_themeMode);
  Future<void> setThemeMode(String mode) async => (await _p).setString(_themeMode, mode);

  Future<List<String>> getSavedWorkerIds() async => (await _p).getStringList(_savedWorkers) ?? [];
  Future<void> toggleSavedWorker(String id) async {
    final p = await _p;
    final list = List<String>.from(await getSavedWorkerIds());
    if (list.contains(id)) {
      list.remove(id);
    } else {
      list.add(id);
    }
    await p.setStringList(_savedWorkers, list);
  }

  Future<List<String>> getSavedJobIds() async => (await _p).getStringList(_savedJobs) ?? [];
  Future<void> toggleSavedJob(String id) async {
    final p = await _p;
    final list = List<String>.from(await getSavedJobIds());
    if (list.contains(id)) {
      list.remove(id);
    } else {
      list.add(id);
    }
    await p.setStringList(_savedJobs, list);
  }
}
