import 'package:flutter_test/flutter_test.dart';
import 'package:personal_bookkeeping/app/app.dart';

void main() {
  testWidgets('shows the four core navigation entries on a desktop width', (
    tester,
  ) async {
    await tester.pumpWidget(const PersonalBookkeepingApp());

    expect(find.text('记一笔'), findsWidgets);
    expect(find.text('支出列表'), findsWidgets);
    expect(find.text('分类管理'), findsWidgets);
    expect(find.text('概述统计'), findsWidgets);
    expect(find.byTooltip('设置'), findsOneWidget);
  });
}
