import '../core/network/api_client.dart';
import '../core/network/json_helpers.dart';
import '../models/application.dart';
import '../models/category.dart';
import '../models/job.dart';

class JobFilters {
  final int? radiusKm;
  final String? category;
  final double? minPay;
  final double? maxPay;
  final DateTime? date;

  const JobFilters({
    this.radiusKm,
    this.category,
    this.minPay,
    this.maxPay,
    this.date,
  });

  bool get hasActiveFilters =>
      radiusKm != null || (category != null && category!.isNotEmpty) || minPay != null || date != null;

  JobFilters copyWith({
    int? radiusKm,
    String? category,
    double? minPay,
    double? maxPay,
    DateTime? date,
    bool clearRadius = false,
    bool clearCategory = false,
    bool clearDate = false,
    bool clearPay = false,
  }) {
    return JobFilters(
      radiusKm: clearRadius ? null : (radiusKm ?? this.radiusKm),
      category: clearCategory ? null : (category ?? this.category),
      minPay: clearPay ? null : (minPay ?? this.minPay),
      maxPay: clearPay ? null : (maxPay ?? this.maxPay),
      date: clearDate ? null : (date ?? this.date),
    );
  }
}

class JobsRepository {
  JobsRepository(this._api);
  final ApiClient _api;

  Future<List<Job>> list({
    required double lat,
    required double lng,
    JobFilters filters = const JobFilters(),
  }) async {
    final query = <String, dynamic>{
      'lat': lat,
      'lng': lng,
      if (filters.radiusKm != null) 'radiusKm': filters.radiusKm,
      if (filters.category != null && filters.category!.isNotEmpty) 'category': filters.category,
      if (filters.minPay != null) 'minPay': filters.minPay,
      if (filters.maxPay != null) 'maxPay': filters.maxPay,
      if (filters.date != null) 'date': filters.date!.toIso8601String().split('T').first,
    };
    final body = await _api.get('/jobs', query: query);
    return unwrapList(body).whereType<Map>().map((e) => Job.fromJson(asMap(e))).toList();
  }

  Future<Job> getById(String id) async {
    final body = await _api.get('/jobs/$id');
    return Job.fromJson(unwrapMap(body));
  }

  Future<Job> create(Map<String, dynamic> data) async {
    final body = await _api.post('/jobs', data: data);
    return Job.fromJson(unwrapMap(body));
  }

  Future<Job> publish(String id) async {
    final body = await _api.post('/jobs/$id/publish');
    return Job.fromJson(unwrapMap(body));
  }

  Future<void> payFee(String id) async {
    await _api.post('/jobs/$id/pay-fee');
  }

  Future<List<Job>> mine() async {
    final body = await _api.get('/jobs/mine');
    return unwrapList(body).whereType<Map>().map((e) => Job.fromJson(asMap(e))).toList();
  }

  Future<Job> updateStatus(String id, String status) async {
    final body = await _api.patch('/jobs/$id/status', data: {'status': status});
    return Job.fromJson(unwrapMap(body));
  }

  Future<Application> apply(String jobId, {String? message}) async {
    final body = await _api.post('/jobs/$jobId/apply', data: {if (message != null) 'message': message});
    return Application.fromJson(unwrapMap(body));
  }

  Future<List<Application>> jobApplications(String jobId) async {
    final body = await _api.get('/jobs/$jobId/applications');
    return unwrapList(body).whereType<Map>().map((e) => Application.fromJson(asMap(e))).toList();
  }

  Future<void> rate(String jobId, {required int rating, required String review, String? toUserId}) async {
    await _api.post('/jobs/$jobId/rate', data: {
      'rating': rating,
      'review': review,
      if (toUserId != null) 'toUserId': toUserId,
    });
  }

  Future<List<JobCategory>> categories() async {
    final body = await _api.get('/categories');
    return unwrapList(body).whereType<Map>().map((e) => JobCategory.fromJson(asMap(e))).toList();
  }
}
