import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:time2work/app.dart';
import 'package:time2work/core/constants/app_strings.dart';

void main() {
  testWidgets('app boots to splash branding', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: Time2WorkApp()));
    expect(find.text(AppStrings.appName), findsWidgets);
    expect(find.text(AppStrings.tagline), findsWidgets);
  });
}
