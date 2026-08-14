import '../../data/repositories/period_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../models/budget_period.dart';

class PeriodService {
  PeriodService(
    this._periodRepository,
    this._settingsRepository, {
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final PeriodRepository _periodRepository;
  final SettingsRepository _settingsRepository;
  final DateTime Function() _clock;

  /// Returns the period containing [date], creating it when it is missing.
  ///
  /// A past expense is a valid backfill. A missing historical period snapshots
  /// the default budget that is configured on the day it is created.
  Future<BudgetPeriod> ensurePeriodFor(DateTime date) async {
    final now = _clock();
    if (date.isAfter(now)) {
      throw ArgumentError.value(date, 'date', '不能创建未来生活费周期');
    }
    final existing = await _periodRepository.findContaining(date);
    if (existing != null) return existing;
    final settings = await _settingsRepository.get();
    return _ensureCurrentPeriod(
      now,
      settings.defaultBudgetJiao,
      calculate(date, settings.fundingDay),
    );
  }

  Future<BudgetPeriod> ensureCurrentPeriod() async {
    final now = _clock();
    final existing = await _periodRepository.findContaining(now);
    if (existing != null) return existing;
    final settings = await _settingsRepository.get();
    return _ensureCurrentPeriod(
      now,
      settings.defaultBudgetJiao,
      calculate(now, settings.fundingDay),
    );
  }

  /// Reads any stored period without creating historical or future rows.
  Future<BudgetPeriod?> findExistingPeriodFor(DateTime date) =>
      _periodRepository.findContaining(date);

  Future<void> updateBudget(int periodId, int budgetJiao) {
    if (budgetJiao < 0) {
      throw ArgumentError.value(budgetJiao, 'budgetJiao', '预算不能小于 ¥0。');
    }
    return _periodRepository.updateBudget(periodId, budgetJiao, _clock());
  }

  Future<BudgetPeriod> _ensureCurrentPeriod(
    DateTime now,
    int defaultBudgetJiao,
    PeriodDefinition definition,
  ) => _periodRepository.createOrGet(
    labelYear: definition.labelYear,
    labelMonth: definition.labelMonth,
    startAt: definition.startAt,
    endAt: definition.endAt,
    budgetJiao: defaultBudgetJiao,
    now: now,
  );

  static PeriodDefinition calculate(DateTime date, int fundingDay) {
    if (fundingDay < 1 || fundingDay > 28) {
      throw ArgumentError.value(fundingDay, 'fundingDay', '发放日只能是 1-28 日');
    }
    final local = date.toLocal();
    final labelDate = local.day >= fundingDay
        ? DateTime(local.year, local.month)
        : DateTime(local.year, local.month - 1);
    final start = DateTime(labelDate.year, labelDate.month, fundingDay);
    final nextStart = DateTime(labelDate.year, labelDate.month + 1, fundingDay);
    return PeriodDefinition(
      labelYear: labelDate.year,
      labelMonth: labelDate.month,
      startAt: start,
      endAt: nextStart.subtract(const Duration(microseconds: 1)),
    );
  }
}

class PeriodDefinition {
  const PeriodDefinition({
    required this.labelYear,
    required this.labelMonth,
    required this.startAt,
    required this.endAt,
  });

  final int labelYear;
  final int labelMonth;
  final DateTime startAt;
  final DateTime endAt;
}
