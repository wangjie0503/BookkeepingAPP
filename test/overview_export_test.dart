import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_bookkeeping/domain/services/csv_export_service.dart';
import 'package:personal_bookkeeping/features/overview/overview_page.dart';

void main() {
  testWidgets('shows a clear snackbar when CSV export fails', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () => showCsvExportFeedback(
                context,
                () => Future<CsvExportResult>.error(StateError('write failed')),
              ),
              child: const Text('导出'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('导出'));
    await tester.pump();

    expect(find.text('CSV 导出失败，请检查文件权限或系统分享服务后重试。'), findsOneWidget);
  });
}
