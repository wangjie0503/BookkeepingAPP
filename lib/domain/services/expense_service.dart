import '../../data/repositories/category_repository.dart';
import '../../data/repositories/expense_repository.dart';
import '../models/expense_draft.dart';
import 'period_service.dart';

class ExpenseValidationException implements Exception {
  ExpenseValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ExpenseService {
  ExpenseService(
    this._expenseRepository,
    this._categoryRepository,
    this._periodService, {
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final ExpenseRepository _expenseRepository;
  final CategoryRepository _categoryRepository;
  final PeriodService _periodService;
  final DateTime Function() _clock;

  Future<int> create(ExpenseDraft draft) async {
    final now = _clock();
    await _validateDraft(draft, now);
    await _periodService.ensurePeriodFor(draft.spentAt);
    return _expenseRepository.create(
      amountJiao: draft.amountJiao,
      secondaryCategoryId: draft.secondaryCategoryId,
      spentAt: draft.spentAt,
      now: now,
    );
  }

  Future<void> update(int id, ExpenseDraft draft) async {
    final now = _clock();
    final existing = await _expenseRepository.findById(id);
    if (existing == null) {
      throw ExpenseValidationException('这笔支出已经不存在。');
    }
    await _validateDraft(
      draft,
      now,
      requireSelectableCategory:
          draft.secondaryCategoryId != existing.secondaryCategoryId,
    );
    await _periodService.ensurePeriodFor(draft.spentAt);
    await _expenseRepository.update(
      id: id,
      amountJiao: draft.amountJiao,
      secondaryCategoryId: draft.secondaryCategoryId,
      spentAt: draft.spentAt,
      now: now,
    );
  }

  Future<void> delete(int id) => _expenseRepository.delete(id);

  Future<void> _validateDraft(
    ExpenseDraft draft,
    DateTime now, {
    bool requireSelectableCategory = true,
  }) async {
    if (draft.amountJiao <= 0) {
      throw ExpenseValidationException('金额必须大于 ¥0。');
    }
    if (draft.spentAt.isAfter(now)) {
      throw ExpenseValidationException('消费时间不能晚于当前时间。');
    }
    if (!requireSelectableCategory) return;
    final secondary = await _categoryRepository.findById(
      draft.secondaryCategoryId,
    );
    if (secondary == null || secondary.isPrimary || !secondary.isActive) {
      throw ExpenseValidationException('请选择一个可用的二级支出分类。');
    }
    final primary = await _categoryRepository.findById(secondary.parentId!);
    if (primary == null || !primary.isPrimary || !primary.isActive) {
      throw ExpenseValidationException('该一级分类已停用，请重新选择。');
    }
  }
}
