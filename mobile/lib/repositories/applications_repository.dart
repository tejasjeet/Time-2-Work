import '../core/network/api_client.dart';
import '../core/network/json_helpers.dart';
import '../models/application.dart';

class ApplicationsRepository {
  ApplicationsRepository(this._api);
  final ApiClient _api;

  Future<List<Application>> mine() async {
    final body = await _api.get('/applications/mine');
    return unwrapList(body).whereType<Map>().map((e) => Application.fromJson(asMap(e))).toList();
  }

  Future<Application> update(String id, String status) async {
    final body = await _api.patch('/applications/$id', data: {'status': status});
    return Application.fromJson(unwrapMap(body));
  }
}
