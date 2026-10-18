import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:scandesk/core/l10n/generated/app_localizations.dart';
import 'package:scandesk/features/auth/presentation/pages/splash_page.dart';

void main() {
  testWidgets('Splash page shows the app name', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SplashPage(),
      ),
    );
    await tester.pump();

    expect(find.text('ScanDesk'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
