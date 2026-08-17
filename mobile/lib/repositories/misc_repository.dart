import '../core/network/api_client.dart';
import '../core/network/json_helpers.dart';
import '../models/earnings.dart';
import '../models/notification_item.dart';
import '../models/phase2.dart';

class PaymentsRepository {
  PaymentsRepository(this._api);
  final ApiClient _api;

  Future<Map<String, dynamic>> createOrder({required String jobId, String type = 'posting_fee'}) async {
    final body = await _api.post('/payments/create-order', data: {'jobId': jobId, 'type': type});
    return unwrapMap(body);
  }

  Future<void> mockConfirm(String orderId) async {
    await _api.post('/payments/mock-confirm', data: {'orderId': orderId});
  }
}

class EarningsRepository {
  EarningsRepository(this._api);
  final ApiClient _api;

  Future<EarningsSummary> summary() async {
    final body = await _api.get('/earnings');
    return EarningsSummary.fromJson(unwrapMap(body));
  }

  Future<List<Txn>> transactions() async {
    final body = await _api.get('/transactions');
    return unwrapList(body).whereType<Map>().map((e) => Txn.fromJson(asMap(e))).toList();
  }
}

class NotificationsRepository {
  NotificationsRepository(this._api);
  final ApiClient _api;

  Future<List<NotificationItem>> list() async {
    final body = await _api.get('/notifications');
    return unwrapList(body).whereType<Map>().map((e) => NotificationItem.fromJson(asMap(e))).toList();
  }

  Future<void> markRead(String id) async {
    await _api.patch('/notifications/$id/read');
  }

  Future<void> delete(String id) async {
    await _api.delete('/notifications/$id');
  }
}

class SearchRepository {
  SearchRepository(this._api);
  final ApiClient _api;

  Future<SearchResults> search(String q) async {
    final body = await _api.get('/search', query: {'q': q});
    return SearchResults.fromJson(body);
  }
}

class Phase2Repository {
  Phase2Repository(this._api);
  final ApiClient _api;

  Future<List<ServiceItem>> services() async {
    final body = await _api.get('/services');
    return unwrapList(body).whereType<Map>().map((e) => ServiceItem.fromJson(asMap(e))).toList();
  }

  Future<List<MarketplaceItem>> marketplace() async {
    final body = await _api.get('/marketplace');
    return unwrapList(body).whereType<Map>().map((e) => MarketplaceItem.fromJson(asMap(e))).toList();
  }

  Future<MarketplaceItem> createListing({
    required String title,
    String? description,
    double? price,
    String? category,
    double? lat,
    double? lng,
    String? address,
  }) async {
    final body = await _api.post('/marketplace', data: {
      'title': title,
      if (description != null && description.isNotEmpty) 'description': description,
      if (price != null) 'price': price,
      if (category != null && category.isNotEmpty) 'category': category,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (address != null && address.isNotEmpty) 'address': address,
    });
    final map = unwrapMap(body);
    return MarketplaceItem.fromJson(map);
  }
}
