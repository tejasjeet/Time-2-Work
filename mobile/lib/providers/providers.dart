import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/location/location_service.dart';
import '../core/network/api_client.dart';
import '../models/application.dart';
import '../models/category.dart';
import '../models/chat.dart';
import '../models/earnings.dart';
import '../models/job.dart';
import '../models/notification_item.dart';
import '../models/phase2.dart';
import '../models/profile.dart';
import '../models/user.dart';
import '../repositories/applications_repository.dart';
import '../repositories/auth_repository.dart';
import '../repositories/chat_repository.dart';
import '../repositories/jobs_repository.dart';
import '../repositories/misc_repository.dart';
import '../repositories/places_repository.dart';
import '../repositories/upload_repository.dart';
import '../repositories/user_repository.dart';
import 'auth_provider.dart';

export 'auth_provider.dart';
export 'theme_provider.dart';

final compareWorkersProvider = StateProvider<List<String>>((ref) => ['w1', 'w2', 'w3']);

final locationServiceProvider = Provider<LocationService>((ref) => LocationService());

final authRepositoryProvider = Provider((ref) => AuthRepository(ref.watch(apiClientProvider)));
final userRepositoryProvider = Provider((ref) => UserRepository(ref.watch(apiClientProvider)));
final jobsRepositoryProvider = Provider((ref) => JobsRepository(ref.watch(apiClientProvider)));
final applicationsRepositoryProvider = Provider((ref) => ApplicationsRepository(ref.watch(apiClientProvider)));
final chatRepositoryProvider = Provider((ref) => ChatRepository(ref.watch(apiClientProvider)));
final paymentsRepositoryProvider = Provider((ref) => PaymentsRepository(ref.watch(apiClientProvider)));
final earningsRepositoryProvider = Provider((ref) => EarningsRepository(ref.watch(apiClientProvider)));
final notificationsRepositoryProvider = Provider((ref) => NotificationsRepository(ref.watch(apiClientProvider)));
final searchRepositoryProvider = Provider((ref) => SearchRepository(ref.watch(apiClientProvider)));
final placesRepositoryProvider = Provider((ref) => PlacesRepository(ref.watch(apiClientProvider)));
final uploadRepositoryProvider = Provider((ref) => UploadRepository(ref.watch(apiClientProvider)));
final phase2RepositoryProvider = Provider((ref) => Phase2Repository(ref.watch(apiClientProvider)));

final radiusKmProvider = StateProvider<int>((ref) => 10);

final jobFiltersProvider = StateProvider<JobFilters>((ref) => const JobFilters());

final categoriesProvider = FutureProvider<List<JobCategory>>((ref) async {
  return ref.watch(jobsRepositoryProvider).categories();
});

final nearbyJobsProvider = FutureProvider<List<Job>>((ref) async {
  final auth = ref.watch(authProvider);
  final user = auth.user;
  final filters = ref.watch(jobFiltersProvider);
  final lat = user?.lat ?? 25.5941;
  final lng = user?.lng ?? 85.1376;
  return ref.watch(jobsRepositoryProvider).list(lat: lat, lng: lng, filters: filters);
});

final myJobsProvider = FutureProvider<List<Job>>((ref) async {
  ref.watch(authProvider);
  return ref.watch(jobsRepositoryProvider).mine();
});

final jobDetailProvider = FutureProvider.family<Job, String>((ref, id) {
  return ref.watch(jobsRepositoryProvider).getById(id);
});

final myApplicationsProvider = FutureProvider<List<Application>>((ref) async {
  ref.watch(authProvider);
  return ref.watch(applicationsRepositoryProvider).mine();
});

final jobApplicationsProvider = FutureProvider.family<List<Application>, String>((ref, jobId) {
  return ref.watch(jobsRepositoryProvider).jobApplications(jobId);
});

final chatsProvider = FutureProvider<List<ChatThread>>((ref) async {
  ref.watch(authProvider);
  return ref.watch(chatRepositoryProvider).list();
});

final chatMessagesProvider = FutureProvider.family<List<ChatMessage>, String>((ref, chatId) {
  return ref.watch(chatRepositoryProvider).messages(chatId);
});

final notificationsProvider = FutureProvider<List<NotificationItem>>((ref) async {
  ref.watch(authProvider);
  return ref.watch(notificationsRepositoryProvider).list();
});

final earningsProvider = FutureProvider<EarningsSummary>((ref) async {
  ref.watch(authProvider);
  return ref.watch(earningsRepositoryProvider).summary();
});

final transactionsProvider = FutureProvider<List<Txn>>((ref) async {
  ref.watch(authProvider);
  return ref.watch(earningsRepositoryProvider).transactions();
});

final workerProfileProvider = FutureProvider<WorkerProfile>((ref) async {
  ref.watch(authProvider);
  return ref.watch(userRepositoryProvider).getWorkerProfile();
});

final businessProfileProvider = FutureProvider<BusinessProfile>((ref) async {
  ref.watch(authProvider);
  return ref.watch(userRepositoryProvider).getBusinessProfile();
});

final publicProfileProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, userId) {
  return ref.watch(userRepositoryProvider).getPublicProfile(userId);
});

final userReviewsProvider = FutureProvider.family((ref, String userId) {
  return ref.watch(userRepositoryProvider).reviews(userId);
});

final servicesProvider = FutureProvider<List<ServiceItem>>((ref) {
  return ref.watch(phase2RepositoryProvider).services();
});

final marketplaceProvider = FutureProvider<List<MarketplaceItem>>((ref) {
  return ref.watch(phase2RepositoryProvider).marketplace();
});

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider<SearchResults>((ref) async {
  final q = ref.watch(searchQueryProvider).trim();
  if (q.isEmpty) return const SearchResults();
  return ref.watch(searchRepositoryProvider).search(q);
});

User? currentUser(WidgetRef ref) => ref.watch(authProvider).user;
