import '../../shared/date_range.dart';

class CategoryTotal {
  const CategoryTotal({
    required this.categoryId,
    required this.name,
    required this.amountJiao,
  });

  final int categoryId;
  final String name;
  final int amountJiao;
}

class PrimaryCategoryTotal extends CategoryTotal {
  const PrimaryCategoryTotal({
    required super.categoryId,
    required super.name,
    required super.amountJiao,
    required this.secondaryTotals,
  });

  final List<CategoryTotal> secondaryTotals;
}

class DailyTotal {
  const DailyTotal({required this.day, required this.amountJiao});

  final DateTime day;
  final int amountJiao;
}

class StatisticsSnapshot {
  const StatisticsSnapshot({
    required this.range,
    required this.totalJiao,
    required this.primaryTotals,
    required this.dailyTotals,
    this.budgetJiao,
  });

  final DateRange range;
  final int totalJiao;
  final int? budgetJiao;
  final List<PrimaryCategoryTotal> primaryTotals;
  final List<DailyTotal> dailyTotals;

  /// A zero snapshot is the initial "not configured" budget, not a usable cap.
  bool get hasBudget => budgetJiao != null && budgetJiao! > 0;
  int? get remainingJiao => hasBudget ? budgetJiao! - totalJiao : null;
  int? get overspentJiao =>
      hasBudget && remainingJiao! < 0 ? -remainingJiao! : null;
  double? get usageRate => hasBudget ? totalJiao / budgetJiao! : null;
}
