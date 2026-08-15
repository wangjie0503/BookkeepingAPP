import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_bookkeeping/app/providers.dart';
import 'package:personal_bookkeeping/data/database/app_database.dart';
import 'package:personal_bookkeeping/data/repositories/category_repository.dart';
import 'package:personal_bookkeeping/domain/services/category_service.dart';
import 'package:personal_bookkeeping/features/category_management/category_management_page.dart';

void main() {
  testWidgets('renames a category without a widget disposal exception', (
    tester,
  ) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = CategoryRepository(database);
    final categories = await repository.getAll();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          categoryServiceProvider.overrideWithValue(
            CategoryService(repository),
          ),
          categoriesProvider.overrideWith((ref) => Stream.value(categories)),
        ],
        child: const MaterialApp(
          home: Scaffold(body: CategoryManagementPage()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.tap(find.byTooltip('分类操作').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('改名').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('category-name-input')),
      '测试餐饮',
    );
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
