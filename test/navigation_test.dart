import 'package:flutter_test/flutter_test.dart';
import 'package:personal_bookkeeping/app/app.dart';
import 'package:personal_bookkeeping/app/providers.dart';
import 'package:personal_bookkeeping/domain/models/category.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('shows the four core navigation entries on a desktop width', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          categoriesProvider.overrideWith(
            (ref) => Stream.value(const <Category>[]),
          ),
        ],
        child: const PersonalBookkeepingApp(),
      ),
    );

    expect(find.text('记一笔'), findsWidgets);
    expect(find.text('支出列表'), findsWidgets);
    expect(find.text('分类管理'), findsWidgets);
    expect(find.text('概述统计'), findsWidgets);
    expect(find.byTooltip('设置'), findsOneWidget);
  });
}
