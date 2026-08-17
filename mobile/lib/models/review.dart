import '../core/network/json_helpers.dart';

class Review {
  final String id;
  final String? fromName;
  final int rating;
  final String text;
  final DateTime? createdAt;

  const Review({
    required this.id,
    this.fromName,
    this.rating = 5,
    this.text = '',
    this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    String? fromName;
    if (json['from'] is Map) {
      fromName = readString(asMap(json['from']), ['name']);
    } else if (json['reviewer'] is Map) {
      fromName = readString(asMap(json['reviewer']), ['name']);
    } else {
      fromName = readString(json, ['fromName', 'reviewerName']);
    }
    return Review(
      id: readId(json),
      fromName: fromName,
      rating: readInt(json['rating'] ?? json['stars']) ?? 5,
      text: readString(json, ['text', 'review', 'comment', 'body']) ?? '',
      createdAt: readDate(json['createdAt']),
    );
  }
}
