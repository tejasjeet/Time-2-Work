import '../core/network/json_helpers.dart';

class JobCategory {
  final String id;
  final String slug;
  final String name;
  final String? nameHi;
  final String? icon;

  const JobCategory({
    required this.id,
    required this.slug,
    required this.name,
    this.nameHi,
    this.icon,
  });

  factory JobCategory.fromJson(Map<String, dynamic> json) {
    return JobCategory(
      id: readId(json),
      slug: readString(json, ['slug']) ?? readString(json, ['name']) ?? readId(json),
      name: readString(json, ['name', 'title', 'label']) ?? 'Category',
      nameHi: readString(json, ['nameHi', 'nameHindi', 'hi']),
      icon: readString(json, ['icon', 'emoji']),
    );
  }
}
