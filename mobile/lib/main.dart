import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/constants/api_constants.dart';
import 'core/network/api_client.dart';
import 'core/storage/local_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = LocalStore();
  final saved = await store.getApiBase();
  final apiBase = ApiConstants.resolveBaseUrl(saved: saved);
  runApp(
    ProviderScope(
      overrides: [
        apiBaseProvider.overrideWith((ref) => apiBase),
      ],
      child: const Time2WorkApp(),
    ),
  );
}
