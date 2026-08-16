import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_bookkeeping/app/theme.dart';

void main() {
  testWidgets('uses the calm bookkeeping surface and teal accent tokens', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: const Scaffold(body: Card(child: SizedBox(height: 48))),
      ),
    );

    final theme = Theme.of(tester.element(find.byType(Card)));
    expect(theme.scaffoldBackgroundColor, AppPalette.canvas);
    expect(theme.colorScheme.primary, AppPalette.teal);
    expect(theme.cardTheme.color, AppPalette.surface);
    expect(theme.cardTheme.shape, isA<RoundedRectangleBorder>());
    expect(theme.navigationBarTheme.indicatorColor, AppPalette.mint);
  });
}
