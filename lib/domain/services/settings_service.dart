import '../../data/repositories/settings_repository.dart';
import '../models/app_settings.dart';

class SettingsService {
  SettingsService(this._repository);

  final SettingsRepository _repository;

  Stream<AppSettings> watch() => _repository.watch();

  Future<void> updateDefaultBudget(int amountJiao) async {
    if (amountJiao < 0) {
      throw ArgumentError.value(amountJiao, 'amountJiao', '预算不能为负数');
    }
    await _repository.updateDefaultBudget(amountJiao);
  }

  Future<bool> canChangeFundingDay() => _repository.canChangeFundingDay();

  Future<void> updateFundingDay(int fundingDay) async {
    if (fundingDay < 1 || fundingDay > 28) {
      throw ArgumentError.value(fundingDay, 'fundingDay', '发放日只能是 1-28 日');
    }
    if (!await _repository.canChangeFundingDay()) {
      throw StateError('已有周期或支出，不能再修改发放日');
    }
    await _repository.updateFundingDay(fundingDay);
  }
}
