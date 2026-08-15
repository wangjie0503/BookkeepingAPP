import 'dart:async';
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_bookkeeping/data/database/app_database.dart';
import 'package:personal_bookkeeping/data/repositories/category_repository.dart';
import 'package:personal_bookkeeping/data/repositories/expense_repository.dart';
import 'package:personal_bookkeeping/domain/models/expense.dart';
import 'package:personal_bookkeeping/domain/models/expense_list_item.dart';
import 'package:personal_bookkeeping/domain/services/category_service.dart';
import 'package:personal_bookkeeping/domain/services/csv_export_service.dart';
import 'package:personal_bookkeeping/domain/services/statistics_service.dart';
import 'package:personal_bookkeeping/shared/date_range.dart';

void main() {
  ExpenseListItem item(
    int id,
    int amount,
    DateTime at,
    int primary,
    String p,
    int secondary,
    String s,
  ) => ExpenseListItem(
    expense: Expense(
      id: id,
      amountJiao: amount,
      secondaryCategoryId: secondary,
      spentAt: at,
      createdAt: at,
      updatedAt: at,
    ),
    primaryCategoryId: primary,
    primaryCategoryName: p,
    secondaryCategoryName: s,
  );
  final range = DateRange(
    start: DateTime(2026, 8, 25),
    end: DateTime(2026, 8, 26, 23, 59, 59),
  );
  final items = [
    item(1, 100, DateTime(2026, 8, 25, 9), 1, '餐饮', 11, '早餐'),
    item(2, 85, DateTime(2026, 8, 25, 18), 1, '餐饮', 12, '晚餐'),
    item(3, 200, DateTime(2026, 8, 26, 10), 2, '交通', 21, '地铁'),
  ];
  test('aggregates current category hierarchy, daily totals and budget', () {
    final snapshot = StatisticsService.calculate(range, items, budgetJiao: 500);
    expect(snapshot.totalJiao, 385);
    expect(snapshot.remainingJiao, 115);
    expect(snapshot.primaryTotals.first.name, '交通');
    expect(
      snapshot.primaryTotals
          .singleWhere((p) => p.name == '餐饮')
          .secondaryTotals
          .map((s) => s.amountJiao),
      [100, 85],
    );
    expect(snapshot.dailyTotals.map((d) => d.amountJiao), [185, 200]);
  });

  test('treats a zero period budget as not configured', () {
    final snapshot = StatisticsService.calculate(range, items, budgetJiao: 0);
    expect(snapshot.hasBudget, isFalse);
    expect(snapshot.remainingJiao, isNull);
    expect(snapshot.usageRate, isNull);
  });

  test(
    'includes an expense in the final microsecond of a closed date range',
    () async {
      final inclusiveRange = DateRange(
        start: DateTime(2026, 8, 26),
        end: DateRange.endOfDay(DateTime(2026, 8, 26)),
      );
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      final categories = CategoryRepository(database);
      final expenses = ExpenseRepository(database);
      final secondary = (await categories.getAll()).firstWhere(
        (category) => !category.isPrimary,
      );
      final end = DateRange.endOfDay(DateTime(2026, 8, 26));
      await expenses.create(
        amountJiao: 99,
        secondaryCategoryId: secondary.id,
        spentAt: end,
        now: end,
      );
      final result = await expenses.getInRange(inclusiveRange);
      expect(inclusiveRange.contains(end), isTrue);
      expect(result.single.expense.amountJiao, 99);
    },
  );

  test(
    'watch refreshes after expense and current category hierarchy changes',
    () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      final categories = CategoryRepository(database);
      final expenses = ExpenseRepository(database);
      final service = StatisticsService(expenses);
      final all = await categories.getAll();
      final secondary = all.firstWhere((category) => !category.isPrimary);
      final originalParent = all.firstWhere(
        (category) => category.id == secondary.parentId,
      );
      final newParent = all.firstWhere(
        (category) => category.isPrimary && category.id != originalParent.id,
      );
      final watcher = StreamIterator(
        service.watchForRange(
          DateRange(
            start: DateTime(2026, 8, 1),
            end: DateRange.endOfDay(DateTime(2026, 8, 31)),
          ),
        ),
      );
      addTearDown(watcher.cancel);

      expect(await watcher.moveNext(), isTrue);
      expect(watcher.current.totalJiao, 0);

      final at = DateTime(2026, 8, 20, 10);
      await expenses.create(
        amountJiao: 123,
        secondaryCategoryId: secondary.id,
        spentAt: at,
        now: at,
      );
      expect(await watcher.moveNext(), isTrue);
      expect(watcher.current.totalJiao, 123);

      final categoryService = CategoryService(
        categories,
        clock: () => DateTime(2026, 8, 20, 11),
      );
      await categoryService.rename(originalParent.id, '统计改名分类');
      expect(await watcher.moveNext(), isTrue);
      expect(watcher.current.primaryTotals.single.name, '统计改名分类');

      await categoryService.moveSecondary(secondary.id, newParent.id);
      expect(await watcher.moveNext(), isTrue);
      expect(watcher.current.primaryTotals.single.categoryId, newParent.id);
    },
  );

  test('CSV is UTF-8 BOM with current hierarchy and time descending', () {
    final bytes = CsvExportService.encode([items[2], items[0]]);
    final text = utf8.decode(bytes);
    expect(bytes.take(3), [0xef, 0xbb, 0xbf]);
    expect(text, contains('消费时间,一级分类,二级分类,金额（元）'));
    expect(text, contains('交通,地铁,20'));
  });
}
