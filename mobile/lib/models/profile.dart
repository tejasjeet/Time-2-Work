import '../core/network/json_helpers.dart';

class WorkerProfile {
  final String userId;
  final String? name;
  final String? about;
  final String? photoUrl;
  final List<String> skills;
  final bool availableNow;
  final double? rating;
  final int reviewCount;
  final String? areaLabel;

  const WorkerProfile({
    required this.userId,
    this.name,
    this.about,
    this.photoUrl,
    this.skills = const [],
    this.availableNow = false,
    this.rating,
    this.reviewCount = 0,
    this.areaLabel,
  });

  factory WorkerProfile.fromJson(Map<String, dynamic> json) {
    final skillsRaw = json['skills'] ?? json['categories'];
    final skills = <String>[];
    if (skillsRaw is List) {
      for (final s in skillsRaw) {
        if (s is Map) {
          skills.add(readString(asMap(s), ['name', 'title']) ?? '');
        } else {
          skills.add(s.toString());
        }
      }
    }
    return WorkerProfile(
      userId: readString(json, ['userId', 'id', '_id']) ?? '',
      name: readString(json, ['name', 'fullName']),
      about: readString(json, ['about', 'bio']),
      photoUrl: readString(json, ['photoUrl', 'avatar']),
      skills: skills.where((s) => s.isNotEmpty).toList(),
      availableNow: readBool(json['availableNow'] ?? json['isAvailable']),
      rating: readDouble(json['rating'] ?? json['avgRating']),
      reviewCount: readInt(json['reviewCount'] ?? json['reviews']) ?? 0,
      areaLabel: readString(json, ['areaLabel', 'area', 'locality']),
    );
  }
}

class BusinessProfile {
  final String userId;
  final String? name;
  final String? about;
  final String? photoUrl;
  final String? businessName;
  final double? rating;
  final int reviewCount;
  final String? areaLabel;

  const BusinessProfile({
    required this.userId,
    this.name,
    this.about,
    this.photoUrl,
    this.businessName,
    this.rating,
    this.reviewCount = 0,
    this.areaLabel,
  });

  factory BusinessProfile.fromJson(Map<String, dynamic> json) {
    return BusinessProfile(
      userId: readString(json, ['userId', 'id', '_id']) ?? '',
      name: readString(json, ['name', 'fullName']),
      about: readString(json, ['about', 'bio']),
      photoUrl: readString(json, ['photoUrl', 'avatar']),
      businessName: readString(json, ['businessName', 'shopName', 'companyName']),
      rating: readDouble(json['rating'] ?? json['avgRating']),
      reviewCount: readInt(json['reviewCount'] ?? json['reviews']) ?? 0,
      areaLabel: readString(json, ['areaLabel', 'area', 'locality']),
    );
  }
}
