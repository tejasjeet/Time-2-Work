import '../core/network/api_client.dart';
import '../core/network/json_helpers.dart';

class PlaceSuggestion {
  final String label;
  final double? lat;
  final double? lng;
  final String? placeId;

  const PlaceSuggestion({
    required this.label,
    this.lat,
    this.lng,
    this.placeId,
  });

  factory PlaceSuggestion.fromJson(Map<String, dynamic> json) {
    return PlaceSuggestion(
      label: readString(json, ['label', 'description']) ?? 'Selected location',
      lat: readDouble(json['lat'] ?? json['latitude']),
      lng: readDouble(json['lng'] ?? json['longitude'] ?? json['lon']),
      placeId: readString(json, ['placeId', 'place_id']),
    );
  }
}

class PlacesRepository {
  PlacesRepository(this._api);

  final ApiClient _api;

  Future<List<PlaceSuggestion>> autocomplete(String query, {double? lat, double? lng}) async {
    final q = query.trim();
    if (q.length < 2) return [];
    final data = await _api.get('/places/autocomplete', query: {
      'q': q,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
    });
    final list = unwrapList(data);
    return list.map((e) => PlaceSuggestion.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<PlaceSuggestion> resolvePlace(String placeId) async {
    final data = await _api.get('/places/details', query: {'placeId': placeId});
    final map = unwrapMap(data);
    return PlaceSuggestion.fromJson(map);
  }

  Future<PlaceSuggestion> reverseGeocode(double lat, double lng) async {
    final data = await _api.get('/places/reverse', query: {'lat': lat, 'lng': lng});
    final map = unwrapMap(data);
    return PlaceSuggestion.fromJson(map);
  }
}
