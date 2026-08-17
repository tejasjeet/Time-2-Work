import '../core/network/json_helpers.dart';

class Job {
  final String id;
  final String title;
  final String description;
  final String category;
  final String? categoryId;
  final double pay;
  final String payType;
  final int workersRequired;
  final int workersAccepted;
  final String status;
  final DateTime? date;
  final String? address;
  final String? areaLabel;
  final double? distanceKm;
  final double? lat;
  final double? lng;
  final String? posterId;
  final String? posterName;
  final String? posterPhoto;
  final double? posterRating;
  final double? postingFee;
  final bool feePaid;
  final DateTime? createdAt;

  const Job({
    required this.id,
    required this.title,
    this.description = '',
    this.category = '',
    this.categoryId,
    this.pay = 0,
    this.payType = 'fixed',
    this.workersRequired = 1,
    this.workersAccepted = 0,
    this.status = 'draft',
    this.date,
    this.address,
    this.areaLabel,
    this.distanceKm,
    this.lat,
    this.lng,
    this.posterId,
    this.posterName,
    this.posterPhoto,
    this.posterRating,
    this.postingFee,
    this.feePaid = false,
    this.createdAt,
  });

  bool get isOpen => const ['open', 'published', 'active', 'urgent'].contains(status);
  bool get isCompleted => status == 'completed';
  bool get isMine => false;

  factory Job.fromJson(Map<String, dynamic> json) {
    final geo = readGeo(json);
    Map<String, dynamic> poster = {};
    if (json['poster'] is Map) {
      poster = asMap(json['poster']);
    } else if (json['owner'] is Map) {
      poster = asMap(json['owner']);
    } else if (json['postedBy'] is Map) {
      poster = asMap(json['postedBy']);
    }

    final categoryRaw = json['category'];
    String categoryName = '';
    String? categoryId;
    if (categoryRaw is Map) {
      final c = asMap(categoryRaw);
      categoryName = readString(c, ['name', 'title', 'label']) ?? '';
      categoryId = readId(c);
    } else {
      categoryName = categoryRaw?.toString() ?? '';
      categoryId = readString(json, ['categoryId']);
    }

    return Job(
      id: readId(json),
      title: readString(json, ['title', 'name']) ?? 'Untitled job',
      description: readString(json, ['description', 'details']) ?? '',
      category: categoryName,
      categoryId: categoryId,
      pay: readDouble(json['pay'] ?? json['amount'] ?? json['budget'] ?? json['wage']) ?? 0,
      payType: readString(json, ['payType', 'wageType']) ?? 'fixed',
      workersRequired: readInt(json['workersRequired'] ?? json['helpersNeeded']) ?? 1,
      workersAccepted: readInt(json['workersAccepted'] ?? json['acceptedCount']) ?? 0,
      status: (readString(json, ['status']) ?? 'open').toLowerCase(),
      date: readDate(json['date'] ?? json['scheduledAt'] ?? json['workDate']),
      address: readString(json, ['address', 'venue']),
      areaLabel: readString(json, ['areaLabel', 'area', 'locality']),
      distanceKm: readDouble(json['distanceKm'] ?? json['distance']),
      lat: geo.lat,
      lng: geo.lng,
      posterId: readString(poster, ['id', '_id']) ?? readString(json, ['posterId', 'ownerId', 'userId']),
      posterName: readString(poster, ['name', 'displayName']),
      posterPhoto: readString(poster, ['photoUrl', 'avatar']),
      posterRating: readDouble(poster['rating'] ?? json['posterRating']),
      postingFee: readDouble(json['postingFee'] ?? json['fee']),
      feePaid: readBool(json['feePaid'] ?? json['isPaid']),
      createdAt: readDate(json['createdAt']),
    );
  }
}
