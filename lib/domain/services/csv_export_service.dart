import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/repositories/expense_repository.dart';
import '../models/expense_list_item.dart';
import '../../shared/date_range.dart';
import '../../shared/money.dart';

class CsvExportService {
  CsvExportService(this._expenses);
  final ExpenseRepository _expenses;

  Future<CsvExportResult> export(DateRange range) async {
    final items = await _expenses.getInRange(range);
    final bytes = encode(items);
    final filename =
        '个人记账_${_datePart(range.start)}_${_datePart(range.end)}.csv';
    if (Platform.isWindows) {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}${Platform.pathSeparator}$filename');
      await file.writeAsBytes(bytes, flush: true);
      return CsvExportResult.saved(file.path);
    }
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}${Platform.pathSeparator}$filename');
    await file.writeAsBytes(bytes, flush: true);
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: '个人记账 CSV 导出'),
    );
    return CsvExportResult.shared();
  }

  static List<int> encode(List<ExpenseListItem> items) {
    final rows = <List<String>>[
      ['消费时间', '一级分类', '二级分类', '金额（元）'],
      for (final item in items)
        [
          item.expense.spentAt.toLocal().toString().substring(0, 19),
          item.primaryCategoryName,
          item.secondaryCategoryName,
          Money.formatInputJiao(item.expense.amountJiao),
        ],
    ];
    return utf8.encode('\uFEFF${const CsvEncoder().convert(rows)}');
  }

  static String _datePart(DateTime value) =>
      '${value.year}${value.month.toString().padLeft(2, '0')}${value.day.toString().padLeft(2, '0')}';
}

class CsvExportResult {
  const CsvExportResult._(this.path, this.shared);
  factory CsvExportResult.saved(String path) => CsvExportResult._(path, false);
  factory CsvExportResult.shared() => const CsvExportResult._(null, true);
  final String? path;
  final bool shared;
}
