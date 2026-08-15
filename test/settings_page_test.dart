import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_bookkeeping/app/providers.dart';
import 'package:personal_bookkeeping/data/database/app_database.dart';
import 'package:personal_bookkeeping/data/repositories/settings_repository.dart';
import 'package:personal_bookkeeping/domain/models/app_settings.dart';
import 'package:personal_bookkeeping/domain/services/settings_service.dart';
import 'package:personal_bookkeeping/features/settings/settings_page.dart';

void main() {
  testWidgets('returns to the previous page after saving the default budget', (
    tester,
  ) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final settingsService = SettingsService(SettingsRepository(database));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsServiceProvider.overrideWithValue(settingsService),
          settingsProvider.overrideWith(
            (ref) => Stream.value(
              const AppSettings(defaultBudgetJiao: 0, fundingDay: 25),
            ),
          ),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: FilledButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const SettingsPage()),
                ),
                child: const Text('打开设置'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('打开设置'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('default-budget-input')),
      '300',
    );
    await tester.tap(find.text('保存默认预算'));
    await tester.pumpAndSettle();

    expect(find.text('打开设置'), findsOneWidget);
    expect(find.byType(SettingsPage), findsNothing);
  });
}
