import '../core/network/api_client.dart';
import '../core/network/json_helpers.dart';
import '../models/profile.dart';
import '../models/review.dart';
import '../models/user.dart';

class UserRepository {
  UserRepository(this._api);
  final ApiClient _api;

  Future<User> updateMe({String? name, String? about, String? photoUrl}) async {
    final body = await _api.patch('/users/me', data: {
      if (name != null) 'name': name,
      if (about != null) 'about': about,
      if (photoUrl != null) 'photoUrl': photoUrl,
    });
    return User.fromJson(unwrapMap(body));
  }

  Future<void> updateLocation({required double lat, required double lng}) async {
    await _api.post('/users/me/location', data: {
      'lat': lat,
      'lng': lng,
      'location': {
        'type': 'Point',
        'coordinates': [lng, lat],
      },
    });
  }

  Future<User> updateRole(String role) async {
    final body = await _api.post('/users/me/role', data: {'role': role});
    final map = unwrapMap(body);
    if (map.isEmpty) return User(id: '', role: role);
    return User.fromJson(map);
  }

  Future<void> blockUser(String userId) async {
    await _api.post('/users/$userId/block');
  }

  Future<void> reportUser(String userId, String reason) async {
    await _api.post('/users/$userId/report', data: {'reason': reason});
  }

  Future<WorkerProfile> getWorkerProfile() async {
    final body = await _api.get('/profiles/worker');
    return WorkerProfile.fromJson(unwrapMap(body));
  }

  Future<WorkerProfile> putWorkerProfile(Map<String, dynamic> data) async {
    final payload = Map<String, dynamic>.from(data);
    if (payload.containsKey('about') && !payload.containsKey('bio')) {
      payload['bio'] = payload.remove('about');
    }
    final body = await _api.put('/profiles/worker', data: payload);
    return WorkerProfile.fromJson(unwrapMap(body));
  }

  Future<BusinessProfile> getBusinessProfile() async {
    final body = await _api.get('/profiles/business');
    return BusinessProfile.fromJson(unwrapMap(body));
  }

  Future<BusinessProfile> putBusinessProfile(Map<String, dynamic> data) async {
    final body = await _api.put('/profiles/business', data: data);
    return BusinessProfile.fromJson(unwrapMap(body));
  }

  Future<Map<String, dynamic>> getPublicProfile(String userId) async {
    final body = await _api.get('/profiles/$userId');
    return unwrapMap(body);
  }

  Future<void> setAvailability(bool availableNow) async {
    await _api.patch('/profiles/worker/availability', data: {'availableNow': availableNow});
  }

  Future<List<Review>> reviews(String userId) async {
    final body = await _api.get('/users/$userId/reviews');
    return unwrapList(body).whereType<Map>().map((e) => Review.fromJson(asMap(e))).toList();
  }

  Future<void> sos({required double lat, required double lng, String? note}) async {
    await _api.post('/sos', data: {'lat': lat, 'lng': lng, if (note != null) 'note': note});
  }
}
