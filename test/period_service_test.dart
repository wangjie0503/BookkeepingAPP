import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_bookkeeping/data/database/app_database.dart';
import 'package:personal_bookkeeping/data/repositories/period_repository.dart';
import 'package:personal_bookkeeping/data/repositories/settings_repository.dart';
import 'package:personal_bookkeeping/domain/services/period_service.dart';
import 'package:personal_bookkeeping/domain/services/settings_service.dart';

void main() {
  group('PeriodService.calculate', () {
    test('uses an inclusive 25th-to-24th life-expense period', () {
      final onStart = PeriodService.calculate(DateTime(2026, 8, 25, 0, 0), 25);
      final beforeNext = PeriodService.calculate(
        DateTime(2026, 9, 24, 23, 59),
        25,
      );
      final nextStart = PeriodService.calculate(DateTime(2026, 9, 25), 25);

      expect(onStart.labelYear, 2026);
      expect(onStart.labelMonth, 8);
      expect(onStart.startAt, DateTime(2026, 8, 25));
      expect(onStart.endAt, DateTime(2026, 9, 24, 23, 59, 59, 999, 999));
      expect(beforeNext.labelMonth, 8);
      expect(nextStart.labelMonth, 9);
    });

    test('rejects an unsupported funding day', () {
      expect(
        () => PeriodService.calculate(DateTime(2026, 8, 25), 29),
        throwsArgumentError,
      );
    });
  });

  group('PeriodService persistence', () {
    late AppDatabase database;
    late PeriodRepository periods;
    late SettingsRepository settings;
    final augustNow = DateTime(2026, 8, 26, 12);

    setUp(() {
      database = AppDatabase.forTesting(NativeDatabase.memory());
      periods = PeriodRepository(database);
      settings = SettingsRepository(database);
    });

    tearDown(() => database.close());

    PeriodService serviceAt(DateTime now) =>
        PeriodService(periods, settings, clock: () => now);

    test(
      'only creates the current period once, even for concurrent requests',
      () async {
        await settings.updateDefaultBudget(1234);
        final service = serviceAt(augustNow);

        final created = await Future.wait(
          List.generate(8, (_) => service.ensureCurrentPeriod()),
        );

        expect(created.map((period) => period.id).toSet(), hasLength(1));
        expect((await periods.getAll()), hasLength(1));
        expect(created.first.budgetJiao, 1234);
      },
    );

    test(
      'does not insert historical periods and rejects future creation',
      () async {
        final service = serviceAt(DateTime(2026, 9, 26, 12));
        final historicalDate = DateTime(2026, 8, 26);

        expect(await service.findExistingPeriodFor(historicalDate), isNull);
        await expectLater(
          service.ensurePeriodFor(historicalDate),
          throwsStateError,
        );
        await expectLater(
          service.ensurePeriodFor(DateTime(2026, 10, 1)),
          throwsArgumentError,
        );
        expect(await periods.getAll(), isEmpty);
      },
    );

    test(
      'period budget snapshots are independent from later default changes',
      () async {
        await settings.updateDefaultBudget(1000);
        final august = await serviceAt(augustNow).ensureCurrentPeriod();

        await settings.updateDefaultBudget(2000);
        final september = await serviceAt(DateTime(2026, 9, 26, 12))
            .ensureCurrentPeriod();

        expect(august.budgetJiao, 1000);
        expect(september.budgetJiao, 2000);
        expect((await periods.findByLabel(2026, 8))!.budgetJiao, 1000);
      },
    );

    test('funding day accepts 1-28 and locks after a period exists', () async {
      final settingsService = SettingsService(settings);
      await settingsService.updateFundingDay(1);
      await settingsService.updateFundingDay(28);
      await expectLater(
        settingsService.updateFundingDay(0),
        throwsArgumentError,
      );
      await expectLater(
        settingsService.updateFundingDay(29),
        throwsArgumentError,
      );

      await serviceAt(augustNow).ensureCurrentPeriod();
      await expectLater(settingsService.updateFundingDay(25), throwsStateError);
    });
  });
}
