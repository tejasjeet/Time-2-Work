Map<String, dynamic> asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

Map<String, dynamic> unwrapMap(dynamic body) {
  if (body is Map) {
    final map = asMap(body);
    for (final key in ['data', 'result', 'message', 'listing', 'job', 'application', 'chat', 'profile', 'user']) {
      final value = map[key];
      if (value is Map) return asMap(value);
    }
    return map;
  }
  return <String, dynamic>{};
}

List<dynamic> unwrapList(dynamic body) {
  if (body is List) return body;
  if (body is Map) {
    final map = asMap(body);
    for (final key in ['data', 'items', 'results', 'jobs', 'chats', 'messages', 'notifications', 'transactions', 'reviews', 'categories', 'applications', 'services', 'listings']) {
      final value = map[key];
      if (value is List) return value;
    }
    final data = map['data'];
    if (data is Map) {
      final inner = asMap(data);
      for (final key in ['items', 'results', 'jobs', 'chats', 'messages']) {
        if (inner[key] is List) return inner[key] as List;
      }
    }
  }
  return const [];
}

String? readString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value == null) continue;
    if (value is Map) {
      final nested = readId(asMap(value));
      if (nested.isNotEmpty) return nested;
      continue;
    }
    final text = value.toString().trim();
    if (text.isNotEmpty && !text.startsWith('{')) return text;
  }
  return null;
}

String readId(Map<String, dynamic> json) {
  for (final key in ['id', '_id']) {
    final value = json[key];
    if (value == null) continue;
    if (value is Map) {
      final map = asMap(value);
      final nested = map[r'$oid'] ?? map['id'] ?? map['_id'];
      if (nested != null) {
        final text = nested.toString().trim();
        if (text.isNotEmpty) return text;
      }
    } else {
      final text = value.toString().trim();
      if (text.isNotEmpty && !text.startsWith('{')) return text;
    }
  }
  return '';
}

double? readDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

int? readInt(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

bool readBool(dynamic value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value == null) return fallback;
  final text = value.toString().toLowerCase();
  if (text == 'true' || text == '1') return true;
  if (text == 'false' || text == '0') return false;
  return fallback;
}

DateTime? readDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}

/// GeoJSON Point or {lat,lng} / {latitude,longitude}.
({double? lat, double? lng}) readGeo(Map<String, dynamic> json) {
  final loc = json['location'];
  if (loc is Map) {
    final map = asMap(loc);
    if (map['coordinates'] is List && (map['coordinates'] as List).length >= 2) {
      final coords = map['coordinates'] as List;
      return (lat: readDouble(coords[1]), lng: readDouble(coords[0]));
    }
    return (
      lat: readDouble(map['lat'] ?? map['latitude']),
      lng: readDouble(map['lng'] ?? map['longitude']),
    );
  }
  return (
    lat: readDouble(json['lat'] ?? json['latitude']),
    lng: readDouble(json['lng'] ?? json['longitude']),
  );
}
