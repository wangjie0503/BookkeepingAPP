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

  /// Compatibility entry point: only the current period may be created.
  /// Missing historical periods must remain missing so they cannot accidentally
  /// receive today's default-budget snapshot.
  Future<BudgetPeriod> ensurePeriodFor(DateTime date) async {
    final now = _clock();
    if (date.isAfter(now)) {
      throw ArgumentError.value(date, 'date', '不能创建未来生活费周期');
    }
    final settings = await _settingsRepository.get();
    final requested = calculate(date, settings.fundingDay);
    final current = calculate(now, settings.fundingDay);
    if (requested.labelYear != current.labelYear ||
        requested.labelMonth != current.labelMonth) {
      throw StateError('历史周期只能读取，不能补建');
    }
    return _ensureCurrentPeriod(now, settings.defaultBudgetJiao, current);
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
