import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/applications/applications_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/otp_screen.dart';
import '../../features/chat/chat_list_screen.dart';
import '../../features/chat/chat_screen.dart';
import '../../features/earnings/earnings_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/jobs/job_details_screen.dart';
import '../../features/jobs/jobs_feed_screen.dart';
import '../../features/location/change_location_screen.dart';
import '../../features/location/location_permission_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/phase2/bazar_screen.dart';
import '../../features/phase2/map_screen.dart';
import '../../features/phase2/services_screen.dart';
import '../../features/post/checkout_screen.dart';
import '../../features/post/job_preview_screen.dart';
import '../../features/post/post_job_screen.dart';
import '../../features/profile_setup/profile_setup_screen.dart';
import '../../features/profiles/edit_profile_screen.dart';
import '../../features/profiles/public_profile_screen.dart';
import '../../features/profiles/role_profile_screen.dart';
import '../../features/ratings/rate_job_screen.dart';
import '../../features/role_select/role_select_screen.dart';
import '../../features/saved/saved_screen.dart';
import '../../features/search/search_results_screen.dart';
import '../../features/search/search_screen.dart';
import '../../features/workers/compare_workers_screen.dart';
import '../../features/workers/worker_profile_screen.dart';
import '../../features/settings/help_screen.dart';
import '../../features/settings/report_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/settings/sos_screen.dart';
import '../../features/shell/main_shell.dart';
import '../../features/splash/splash_screen.dart';
import '../../providers/auth_provider.dart';

final _rootKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen<AuthState>(authProvider, (_, __) => refresh.value++);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final loc = state.matchedLocation;
      final gate = auth.gate;

      if (gate == AuthGate.unknown) {
        return loc == '/splash' ? null : '/splash';
      }

      const public = {'/splash', '/onboarding', '/login', '/otp'};
      switch (gate) {
        case AuthGate.needsOnboarding:
          return loc == '/onboarding' ? null : '/onboarding';
        case AuthGate.unauthenticated:
          return public.contains(loc) && loc != '/splash' ? null : '/login';
        case AuthGate.needsProfile:
          return loc == '/profile-setup' ? null : '/profile-setup';
        case AuthGate.needsRole:
          return loc == '/role-select' ? null : '/role-select';
        case AuthGate.needsLocation:
          return loc == '/location' ? null : '/location';
        case AuthGate.ready:
          if (public.contains(loc) ||
              loc == '/profile-setup' ||
              loc == '/role-select' ||
              loc == '/location' ||
              loc == '/splash') {
            return '/home';
          }
          return null;
        case AuthGate.unknown:
          return '/splash';
      }
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/otp', builder: (_, __) => const OtpScreen()),
      GoRoute(path: '/profile-setup', builder: (_, __) => const ProfileSetupScreen()),
      GoRoute(path: '/role-select', builder: (_, __) => const RoleSelectScreen()),
      GoRoute(path: '/location', builder: (_, __) => const LocationPermissionScreen()),
      GoRoute(path: '/change-location', builder: (_, __) => const ChangeLocationScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/home', builder: (_, __) => const HomeScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/jobs', builder: (_, __) => const JobsFeedScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/post', builder: (_, __) => const PostJobScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/chat', builder: (_, __) => const ChatListScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/profile', builder: (_, __) => const RoleProfileScreen())]),
        ],
      ),
      GoRoute(path: '/profile/edit', builder: (_, __) => const EditProfileScreen()),
      GoRoute(path: '/jobs/:id', builder: (_, s) => JobDetailsScreen(jobId: s.pathParameters['id']!)),
      GoRoute(path: '/post/preview', builder: (_, __) => const JobPreviewScreen()),
      GoRoute(path: '/post/checkout', builder: (_, s) => CheckoutScreen(jobId: s.uri.queryParameters['jobId'] ?? '')),
      GoRoute(path: '/applications', builder: (_, __) => const ApplicationsScreen()),
      GoRoute(
        path: '/applications/job/:jobId',
        builder: (_, s) => ApplicationsScreen(jobId: s.pathParameters['jobId']),
      ),
      GoRoute(path: '/chats/:id', builder: (_, s) => ChatScreen(chatId: s.pathParameters['id']!)),
      GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),
      GoRoute(path: '/earnings', builder: (_, __) => const EarningsScreen()),
      GoRoute(
        path: '/rate/:jobId',
        builder: (_, s) => RateJobScreen(
          jobId: s.pathParameters['jobId']!,
          toUserId: s.uri.queryParameters['toUserId'],
        ),
      ),
      GoRoute(path: '/search', builder: (_, __) => const SearchScreen()),
      GoRoute(path: '/saved', builder: (_, __) => const SavedScreen()),
      GoRoute(
        path: '/search-results',
        builder: (_, s) => SearchResultsScreen(query: s.uri.queryParameters['q'] ?? 'Electrician'),
      ),
      GoRoute(path: '/compare', builder: (_, __) => const CompareWorkersScreen()),
      GoRoute(path: '/workers/:id', builder: (_, s) => WorkerProfileScreen(workerId: s.pathParameters['id']!)),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      GoRoute(path: '/help', builder: (_, __) => const HelpScreen()),
      GoRoute(path: '/report/:userId', builder: (_, s) => ReportScreen(userId: s.pathParameters['userId']!)),
      GoRoute(path: '/sos', builder: (_, __) => const SosScreen()),
      GoRoute(path: '/services', builder: (_, __) => const ServicesScreen()),
      GoRoute(path: '/bazar', builder: (_, __) => const BazarScreen()),
      GoRoute(path: '/map', builder: (_, __) => const MapScreen()),
      GoRoute(path: '/users/:id', builder: (_, s) => PublicProfileScreen(userId: s.pathParameters['id']!)),
    ],
  );
});
