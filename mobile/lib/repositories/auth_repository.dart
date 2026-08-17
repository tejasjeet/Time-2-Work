import '../core/network/api_client.dart';
import '../core/network/json_helpers.dart';
import '../models/user.dart';

class AuthSession {
  final String accessToken;
  final String? refreshToken;
  final User? user;

  const AuthSession({required this.accessToken, this.refreshToken, this.user});
}

class AuthRepository {
  AuthRepository(this._api);
  final ApiClient _api;

  Future<void> sendOtp(String phone) async {
    await _api.post('/auth/send-otp', data: {'phone': phone});
  }

  Future<AuthSession> verifyOtp(String phone, String otp) async {
    final body = await _api.post('/auth/verify-otp', data: {'phone': phone, 'otp': otp});
    if (body is! Map) throw Exception('Invalid login response');
    final map = asMap(body);
    final nestedTokens = map['tokens'] is Map ? asMap(map['tokens']) : null;
    final access = readString(map, ['accessToken', 'token', 'access']) ??
        (nestedTokens != null ? readString(nestedTokens, ['accessToken', 'access', 'token']) : null) ??
        '';
    final refresh = readString(map, ['refreshToken', 'refresh']) ??
        (nestedTokens != null ? readString(nestedTokens, ['refreshToken', 'refresh']) : null);
    User? user;
    if (map['user'] is Map) {
      user = User.fromJson(asMap(map['user']));
    }
    if (access.isEmpty) {
      throw Exception('Login succeeded but no token was returned');
    }
    return AuthSession(accessToken: access, refreshToken: refresh, user: user);
  }

  Future<User> me() async {
    final body = await _api.get('/auth/me');
    if (body is Map && asMap(body)['user'] is Map) {
      return User.fromJson(asMap(asMap(body)['user']));
    }
    return User.fromJson(unwrapMap(body));
  }
}
