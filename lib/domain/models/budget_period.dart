import '../../shared/date_range.dart';

class BudgetPeriod {
  const BudgetPeriod({
    required this.id,
    required this.labelYear,
    required this.labelMonth,
    required this.startAt,
    required this.endAt,
    required this.budgetJiao,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int labelYear;
  final int labelMonth;
  final DateTime startAt;
  final DateTime endAt;
  final int budgetJiao;
  final DateTime createdAt;
  final DateTime updatedAt;

  DateRange get range => DateRange(start: startAt, end: endAt);
  String get label => '$labelYear 年 $labelMonth 月';
}
