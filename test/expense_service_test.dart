import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_bookkeeping/data/database/app_database.dart';
import 'package:personal_bookkeeping/data/repositories/category_repository.dart';
import 'package:personal_bookkeeping/data/repositories/expense_repository.dart';
import 'package:personal_bookkeeping/data/repositories/period_repository.dart';
import 'package:personal_bookkeeping/data/repositories/settings_repository.dart';
import 'package:personal_bookkeeping/domain/models/expense_draft.dart';
import 'package:personal_bookkeeping/domain/services/category_service.dart';
import 'package:personal_bookkeeping/domain/services/expense_service.dart';
import 'package:personal_bookkeeping/domain/services/period_service.dart';
import 'package:personal_bookkeeping/shared/date_range.dart';

void main() {
  test('DateRange has value equality for provider cache keys', () {
    expect(
      DateRange(start: DateTime(2026, 8, 1), end: DateTime(2026, 8, 2)),
      DateRange(start: DateTime(2026, 8, 1), end: DateTime(2026, 8, 2)),
    );
  });

  group('ExpenseService', () {
    late AppDatabase database;
    late CategoryRepository categories;
    late ExpenseRepository expenses;
    late PeriodRepository periods;
    late SettingsRepository settings;
    late ExpenseService service;
    final now = DateTime(2026, 8, 26, 12);

    setUp(() {
      database = AppDatabase.forTesting(NativeDatabase.memory());
      categories = CategoryRepository(database);
      expenses = ExpenseRepository(database);
      periods = PeriodRepository(database);
      settings = SettingsRepository(database);
      service = ExpenseService(
        expenses,
        categories,
        PeriodService(periods, settings, clock: () => now),
        clock: () => now,
      );
    });

    tearDown(() => database.close());

    Future<int> createAt(DateTime spentAt, {int amountJiao = 185}) async {
      final secondary = (await categories.getAll()).firstWhere(
        (category) => !category.isPrimary,
      );
      return service.create(
        ExpenseDraft(
          amountJiao: amountJiao,
          secondaryCategoryId: secondary.id,
          spentAt: spentAt,
        ),
      );
    }

    test('rejects non-positive amounts and future spending times', () async {
      final secondary = (await categories.getAll()).firstWhere(
        (category) => !category.isPrimary,
      );
      await expectLater(
        service.create(
          ExpenseDraft(
            amountJiao: 0,
            secondaryCategoryId: secondary.id,
            spentAt: now,
          ),
        ),
        throwsA(isA<ExpenseValidationException>()),
      );
      await expectLater(
        service.create(
          ExpenseDraft(
            amountJiao: 10,
            secondaryCategoryId: secondary.id,
            spentAt: now.add(const Duration(minutes: 1)),
          ),
        ),
        throwsA(isA<ExpenseValidationException>()),
      );
    });

    test(
      'queries an inclusive range in descending spending-time order',
      () async {
        await createAt(DateTime(2026, 8, 24, 9), amountJiao: 10);
        await createAt(DateTime(2026, 8, 25, 18), amountJiao: 20);
        await createAt(DateTime(2026, 8, 25, 8), amountJiao: 30);
        await createAt(DateTime(2026, 8, 26, 1), amountJiao: 40);

        final result = await expenses
            .watchInRange(
              DateRange(
                start: DateTime(2026, 8, 25),
                end: DateTime(2026, 8, 25, 23, 59, 59, 999, 999),
              ),
            )
            .first;

        expect(result.map((item) => item.expense.amountJiao), [20, 30]);
      },
    );

    test(
      'backfilling an expense creates its missing historical budget snapshot',
      () async {
        await settings.updateDefaultBudget(6543);
        await createAt(DateTime(2026, 7, 10, 9));

        final period = await periods.findContaining(DateTime(2026, 7, 10, 9));
        expect(period, isNotNull);
        expect(period!.budgetJiao, 6543);
      },
    );

    test(
      'updates, physically deletes, and resolves the current primary parent',
      () async {
        final id = await createAt(DateTime(2026, 8, 25, 8));
        final all = await categories.getAll();
        final originalSecondary = all.firstWhere(
          (category) => !category.isPrimary,
        );
        final newPrimary = all.firstWhere(
          (category) =>
              category.isPrimary && category.id != originalSecondary.parentId,
        );
        await CategoryService(
          categories,
          clock: () => now,
        ).moveSecondary(originalSecondary.id, newPrimary.id);
        await service.update(
          id,
          ExpenseDraft(
            amountJiao: 999,
            secondaryCategoryId: originalSecondary.id,
            spentAt: DateTime(2026, 8, 25, 10),
          ),
        );

        final displayed = await expenses
            .watchInRange(
              DateRange(
                start: DateTime(2026, 8, 25),
                end: DateTime(2026, 8, 25, 23, 59, 59, 999, 999),
              ),
            )
            .first;
        expect(displayed, hasLength(1));
        expect(displayed.single.expense.amountJiao, 999);
        expect(displayed.single.primaryCategoryId, newPrimary.id);

        await service.delete(id);
        expect(await expenses.findById(id), isNull);
      },
    );

    test(
      'editing into a missing historical period creates a stable snapshot',
      () async {
        await settings.updateDefaultBudget(1000);
        final id = await createAt(DateTime(2026, 8, 25, 9));
        await settings.updateDefaultBudget(4321);
        final secondary = (await categories.getAll()).firstWhere(
          (category) => !category.isPrimary,
        );

        await service.update(
          id,
          ExpenseDraft(
            amountJiao: 185,
            secondaryCategoryId: secondary.id,
            spentAt: DateTime(2026, 7, 10, 9),
          ),
        );

        final historical = await periods.findContaining(DateTime(2026, 7, 10));
        expect(historical, isNotNull);
        expect(historical!.labelYear, 2026);
        expect(historical.labelMonth, 6);
        expect(historical.startAt, DateTime(2026, 6, 25));
        expect(historical.endAt, DateTime(2026, 7, 24, 23, 59, 59));
        expect(historical.budgetJiao, 4321);

        await settings.updateDefaultBudget(9999);
        expect(
          (await periods.findContaining(DateTime(2026, 7, 10)))!.budgetJiao,
          4321,
        );
      },
    );

    test(
      'keeps an inactive original category when only amount or time changes',
      () async {
        final id = await createAt(DateTime(2026, 8, 25, 8));
        final secondary = (await categories.getAll()).firstWhere(
          (category) => !category.isPrimary,
        );
        final parent = (await categories.getAll()).firstWhere(
          (category) => category.id == secondary.parentId,
        );
        final categoryService = CategoryService(categories, clock: () => now);
        await categoryService.setActive(secondary.id, false);
        await categoryService.setActive(parent.id, false);

        await service.update(
          id,
          ExpenseDraft(
            amountJiao: 300,
            secondaryCategoryId: secondary.id,
            spentAt: DateTime(2026, 8, 25, 10),
          ),
        );

        expect((await expenses.findById(id))!.amountJiao, 300);
      },
    );

    test(
      'rejects a stopped replacement category but accepts an available one',
      () async {
        final id = await createAt(DateTime(2026, 8, 25, 8));
        final all = await categories.getAll();
        final original = all.firstWhere((category) => !category.isPrimary);
        final inactiveTarget = all.firstWhere(
          (category) => !category.isPrimary && category.id != original.id,
        );
        final availableTarget = all.firstWhere(
          (category) =>
              !category.isPrimary &&
              category.id != original.id &&
              category.id != inactiveTarget.id,
        );
        await CategoryService(
          categories,
          clock: () => now,
        ).setActive(inactiveTarget.id, false);

        await expectLater(
          service.update(
            id,
            ExpenseDraft(
              amountJiao: 200,
              secondaryCategoryId: inactiveTarget.id,
              spentAt: DateTime(2026, 8, 25, 9),
            ),
          ),
          throwsA(isA<ExpenseValidationException>()),
        );
        await service.update(
          id,
          ExpenseDraft(
            amountJiao: 200,
            secondaryCategoryId: availableTarget.id,
            spentAt: DateTime(2026, 8, 25, 9),
          ),
        );
        expect(
          (await expenses.findById(id))!.secondaryCategoryId,
          availableTarget.id,
        );
      },
    );
  });
}
