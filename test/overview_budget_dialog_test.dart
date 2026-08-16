import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_bookkeeping/app/providers.dart';
import 'package:personal_bookkeeping/app/theme.dart';
import 'package:personal_bookkeeping/data/database/app_database.dart';
import 'package:personal_bookkeeping/data/repositories/period_repository.dart';
import 'package:personal_bookkeeping/data/repositories/settings_repository.dart';
import 'package:personal_bookkeeping/domain/models/statistics_snapshot.dart';
import 'package:personal_bookkeeping/domain/services/period_service.dart';
import 'package:personal_bookkeeping/features/overview/overview_page.dart';

void main() {
  testWidgets(
    'saves the current-period budget without a dialog lifecycle error',
    (tester) async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      final periods = PeriodRepository(database);
      final now = DateTime(2026, 8, 26, 12);
      final periodService = PeriodService(
        periods,
        SettingsRepository(database),
        clock: () => now,
      );
      final period = await periodService.ensureCurrentPeriod();
      final snapshot = StatisticsSnapshot(
        range: period.range,
        totalJiao: 0,
        budgetJiao: 0,
        primaryTotals: const [],
        dailyTotals: const [],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            periodServiceProvider.overrideWithValue(periodService),
            periodsProvider.overrideWith((ref) => Stream.value([period])),
            statisticsProvider.overrideWith(
              (ref, request) => Stream.value(snapshot),
            ),
          ],
          child: MaterialApp(
            theme: buildAppTheme(),
            home: const Scaffold(body: OverviewPage()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('设置本期预算'));
      await tester.pump();
      await tester.enterText(find.byType(TextField), '125');
      await tester.tap(find.text('保存'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(tester.takeException(), isNull);
      expect(
        (await periods.findByLabel(
          period.labelYear,
          period.labelMonth,
        ))!.budgetJiao,
        1250,
      );
    },
  );
}
