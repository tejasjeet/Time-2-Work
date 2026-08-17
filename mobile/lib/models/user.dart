import '../core/network/json_helpers.dart';

class User {
  final String id;
  final String? phone;
  final String? name;
  final String? about;
  final String? photoUrl;
  final String role;
  final bool profileComplete;
  final bool locationSet;
  final double? lat;
  final double? lng;
  final String? areaLabel;

  const User({
    required this.id,
    this.phone,
    this.name,
    this.about,
    this.photoUrl,
    this.role = 'worker',
    this.profileComplete = false,
    this.locationSet = false,
    this.lat,
    this.lng,
    this.areaLabel,
  });

  bool get isWorker => role == 'worker';
  bool get isBusiness => role == 'business';
  bool get hasName => name != null && name!.trim().isNotEmpty;

  factory User.fromJson(Map<String, dynamic> json) {
    final geo = readGeo(json);
    final profile = json['profile'] is Map ? asMap(json['profile']) : <String, dynamic>{};
    return User(
      id: readId(json),
      phone: readString(json, ['phone', 'phoneNumber', 'mobile']),
      name: readString(json, ['name', 'fullName', 'displayName']) ?? readString(profile, ['name']),
      about: readString(json, ['about', 'bio']) ?? readString(profile, ['about', 'bio']),
      photoUrl: readString(json, ['photoUrl', 'avatar', 'photo', 'imageUrl']) ??
          readString(profile, ['photoUrl', 'avatar']),
      role: (readString(json, ['role', 'activeRole']) ?? 'worker').toLowerCase(),
      profileComplete: readBool(json['profileComplete'] ?? json['isProfileComplete'], fallback: false) ||
          ((readString(json, ['name']) ?? '').trim().isNotEmpty),
      locationSet: readBool(json['locationSet'] ?? json['hasLocation'], fallback: false) ||
          geo.lat != null,
      lat: geo.lat,
      lng: geo.lng,
      areaLabel: readString(json, ['areaLabel', 'area', 'locality', 'city']),
    );
  }

  User copyWith({
    String? id,
    String? phone,
    String? name,
    String? about,
    String? photoUrl,
    String? role,
    bool? profileComplete,
    bool? locationSet,
    double? lat,
    double? lng,
    String? areaLabel,
  }) {
    return User(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      name: name ?? this.name,
      about: about ?? this.about,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      profileComplete: profileComplete ?? this.profileComplete,
      locationSet: locationSet ?? this.locationSet,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      areaLabel: areaLabel ?? this.areaLabel,
    );
  }
}
