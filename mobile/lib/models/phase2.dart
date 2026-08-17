import '../core/network/json_helpers.dart';

class ServiceItem {
  final String id;
  final String title;
  final String? description;
  final String? category;
  final double? price;
  final String? address;

  const ServiceItem({
    required this.id,
    required this.title,
    this.description,
    this.category,
    this.price,
    this.address,
  });

  factory ServiceItem.fromJson(Map<String, dynamic> json) {
    return ServiceItem(
      id: readId(json),
      title: readString(json, ['title', 'name']) ?? 'Service',
      description: readString(json, ['description', 'about']),
      category: readString(json, ['category']),
      price: readDouble(json['price'] ?? json['amount']),
      address: readString(json, ['address', 'areaLabel', 'area']),
    );
  }
}

class MarketplaceItem {
  final String id;
  final String title;
  final String? description;
  final double? price;
  final String? category;
  final String? address;
  final List<String> images;

  const MarketplaceItem({
    required this.id,
    required this.title,
    this.description,
    this.price,
    this.category,
    this.address,
    this.images = const [],
  });

  factory MarketplaceItem.fromJson(Map<String, dynamic> json) {
    final rawImages = json['images'];
    final images = rawImages is List
        ? rawImages.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
        : <String>[];
    return MarketplaceItem(
      id: readId(json),
      title: readString(json, ['title', 'name']) ?? 'Listing',
      description: readString(json, ['description']),
      price: readDouble(json['price'] ?? json['amount']),
      category: readString(json, ['category']),
      address: readString(json, ['address', 'areaLabel', 'area']),
      images: images,
    );
  }
}

class SearchResults {
  final List<Map<String, dynamic>> jobs;
  final List<Map<String, dynamic>> users;
  final List<Map<String, dynamic>> raw;

  const SearchResults({this.jobs = const [], this.users = const [], this.raw = const []});

  factory SearchResults.fromJson(dynamic body) {
    if (body is List) {
      return SearchResults(raw: body.whereType<Map>().map((e) => asMap(e)).toList());
    }
    final map = unwrapMap(body);
    List<Map<String, dynamic>> asMaps(dynamic v) {
      if (v is List) return v.whereType<Map>().map((e) => asMap(e)).toList();
      return const [];
    }

    return SearchResults(
      jobs: asMaps(map['jobs'] ?? map['data']),
      users: asMaps(map['users'] ?? map['people']),
      raw: asMaps(map['results'] ?? map['items']),
    );
  }
}
