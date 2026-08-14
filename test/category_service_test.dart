import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_bookkeeping/data/database/app_database.dart';
import 'package:personal_bookkeeping/data/repositories/category_repository.dart';
import 'package:personal_bookkeeping/data/repositories/settings_repository.dart';
import 'package:personal_bookkeeping/domain/services/category_service.dart';
import 'package:personal_bookkeeping/domain/services/settings_service.dart';

void main() {
  setUpAll(() {
    // This file intentionally opens the same file-backed database sequentially
    // to verify persistence. There is no shared QueryExecutor in that test.
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  late AppDatabase database;
  late CategoryService service;
  final fixedNow = DateTime(2026, 8, 14, 12);

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    service = CategoryService(
      CategoryRepository(database),
      clock: () => fixedNow,
    );
  });

  tearDown(() => database.close());

  test('seeds the documented default categories', () async {
    final categories = await CategoryRepository(database).getAll();
    expect(
      categories.where((item) => item.isPrimary).map((item) => item.name),
      ['餐饮', '交通', '生活', '学习', '娱乐', '数码', '其他支出'],
    );
    expect(categories.where((item) => !item.isPrimary), hasLength(23));
  });

  test(
    'trims and enforces names globally across both category levels',
    () async {
      final repository = CategoryRepository(database);
      final transport = (await repository.getAll()).singleWhere(
        (item) => item.name == '交通',
      );
      await service.addPrimary('  自定义  ');

      await expectLater(
        service.addPrimary('自定义'),
        throwsA(isA<CategoryNameConflict>()),
      );
      await expectLater(
        service.addSecondary(transport.id, ' 餐饮 '),
        throwsA(isA<CategoryNameConflict>()),
      );
    },
  );

  test(
    'an inactive name conflict identifies the original category for restore',
    () async {
      final custom = await service.addPrimary('自定义');
      await service.setActive(custom.id, false);

      try {
        await service.addPrimary(' 自定义 ');
        fail('Expected CategoryNameConflict');
      } on CategoryNameConflict catch (conflict) {
        expect(conflict.existing.id, custom.id);
        expect(conflict.existing.isActive, isFalse);
      }
      await service.setActive(custom.id, true);
      expect(
        (await CategoryRepository(database).findById(custom.id))!.isActive,
        isTrue,
      );
    },
  );

  test(
    'deactivating a primary does not change children but hides selection',
    () async {
      final repository = CategoryRepository(database);
      final food = (await repository.getAll()).singleWhere(
        (item) => item.name == '餐饮',
      );
      final breakfast = (await repository.getAll()).singleWhere(
        (item) => item.name == '早餐',
      );
      await service.setActive(food.id, false);

      expect((await repository.findById(breakfast.id))!.isActive, isTrue);
      expect(
        await service.watchSelectableSecondaryCategories(food.id).first,
        isEmpty,
      );

      await service.setActive(food.id, true);
      expect(
        await service.watchSelectableSecondaryCategories(food.id).first,
        isNotEmpty,
      );
    },
  );

  test('moving a secondary changes its current primary parent', () async {
    final repository = CategoryRepository(database);
    final breakfast = (await repository.getAll()).singleWhere(
      (item) => item.name == '早餐',
    );
    final transport = (await repository.getAll()).singleWhere(
      (item) => item.name == '交通',
    );

    await service.moveSecondary(breakfast.id, transport.id);
    expect((await repository.findById(breakfast.id))!.parentId, transport.id);
  });

  test('new categories append fixed sort order within their parent', () async {
    final repository = CategoryRepository(database);
    final primaryOne = await service.addPrimary('自定义一');
    final primaryTwo = await service.addPrimary('自定义二');
    expect(primaryTwo.sortOrder, primaryOne.sortOrder + 1);

    final food = (await repository.getAll()).singleWhere(
      (item) => item.name == '餐饮',
    );
    final secondaryOne = await service.addSecondary(food.id, '夜宵');
    final secondaryTwo = await service.addSecondary(food.id, '外卖');
    expect(secondaryTwo.sortOrder, secondaryOne.sortOrder + 1);
  });

  test('funding day locks after an expense exists', () async {
    final repository = CategoryRepository(database);
    final breakfast = (await repository.getAll()).singleWhere(
      (item) => item.name == '早餐',
    );
    await database
        .into(database.expenses)
        .insert(
          ExpensesCompanion.insert(
            amountJiao: 10,
            secondaryCategoryId: breakfast.id,
            spentAt: fixedNow,
            createdAt: fixedNow,
            updatedAt: fixedNow,
          ),
        );

    await expectLater(
      SettingsService(SettingsRepository(database)).updateFundingDay(24),
      throwsStateError,
    );
  });

  test(
    'file-backed SQLite preserves seed, category, and settings after reopen',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'personal_bookkeeping_test_',
      );
      final databaseFile = File(
        '${directory.path}${Platform.pathSeparator}bookkeeping.sqlite',
      );
      try {
        final first = AppDatabase.forTesting(NativeDatabase(databaseFile));
        final firstRepository = CategoryRepository(first);
        expect(
          (await firstRepository.getAll()).where((item) => item.isPrimary),
          hasLength(7),
        );
        await CategoryService(firstRepository).addPrimary('持久化分类');
        await SettingsService(SettingsRepository(first))
            .updateDefaultBudget(8888);
        await first.close();

        final reopened = AppDatabase.forTesting(NativeDatabase(databaseFile));
        final reopenedCategories = await CategoryRepository(reopened).getAll();
        expect(reopenedCategories.any((item) => item.name == '持久化分类'), isTrue);
        expect(
          (await SettingsRepository(reopened).get()).defaultBudgetJiao,
          8888,
        );
        await reopened.close();
      } finally {
        await directory.delete(recursive: true);
      }
    },
  );
}
