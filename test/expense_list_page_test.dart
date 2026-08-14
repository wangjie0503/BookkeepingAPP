import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_bookkeeping/domain/models/budget_period.dart';
import 'package:personal_bookkeeping/features/expense_list/expense_list_page.dart';
import 'package:personal_bookkeeping/shared/date_range.dart';

void main() {
  final period = BudgetPeriod(
    id: 1,
    labelYear: 2026,
    labelMonth: 8,
    startAt: DateTime(2026, 8, 25),
    endAt: DateTime(2026, 9, 24, 23, 59, 59, 999, 999),
    budgetJiao: 1000,
    createdAt: DateTime(2026, 8, 25),
    updatedAt: DateTime(2026, 8, 25),
  );

  testWidgets('returns from custom range to the persisted period selector', (
    tester,
  ) async {
    var custom = true;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: ExpenseRangeSelector(
              periods: [period],
              selected: period,
              customRange: custom
                  ? DateRange(
                      start: DateTime(2026, 8, 1),
                      end: DateTime(2026, 8, 2, 23, 59, 59, 999, 999),
                    )
                  : null,
              onPeriodChanged: (_) {},
              onChooseRange: () {},
              onReturnToPeriod: () => setState(() => custom = false),
              onEditBudget: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('return_to_period_button')), findsOneWidget);
    await tester.tap(find.byKey(const Key('return_to_period_button')));
    await tester.pump();

    expect(find.text('生活费周期'), findsOneWidget);
  });

  testWidgets('requires both deletion confirmations before returning true', (
    tester,
  ) async {
    bool? confirmed;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () async {
                confirmed = await confirmExpenseDeletion(context);
              },
              child: const Text('删除'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('删除'));
    await tester.pump();
    expect(find.text('删除这笔支出？'), findsOneWidget);

    await tester.tap(find.text('继续'));
    await tester.pump();
    expect(find.text('请再次确认删除'), findsOneWidget);
    expect(confirmed, isNull);

    await tester.tap(find.text('永久删除'));
    await tester.pump(const Duration(milliseconds: 250));
    expect(confirmed, isTrue);
  });
}
