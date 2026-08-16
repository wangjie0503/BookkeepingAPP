import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../domain/models/category.dart';
import '../../domain/models/expense_draft.dart';
import '../../domain/services/expense_service.dart';
import '../../shared/money.dart';

class ExpenseEntryPage extends ConsumerStatefulWidget {
  const ExpenseEntryPage({super.key});

  @override
  ConsumerState<ExpenseEntryPage> createState() => _ExpenseEntryPageState();
}

class _ExpenseEntryPageState extends ConsumerState<ExpenseEntryPage> {
  final _amountController = TextEditingController();
  int? _primaryId;
  int? _secondaryId;
  DateTime _spentAt = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);
    return categories.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('分类加载失败：$error')),
      data: (all) {
        final primaryCategories = all
            .where((category) => category.isPrimary && category.isActive)
            .toList();
        _ensureSelectedCategories(all, primaryCategories);
        final selectedPrimary =
            _primaryId ??
            (primaryCategories.isEmpty ? null : primaryCategories.first.id);
        final secondaries = all
            .where(
              (category) =>
                  !category.isPrimary &&
                  category.isActive &&
                  category.parentId == selectedPrimary,
            )
            .toList();
        final selectedSecondary =
            _secondaryId ?? (secondaries.isEmpty ? null : secondaries.first.id);
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              children: [
                Text('记一笔', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(
                  '快速记录这一笔日常支出',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      key: const Key('expense_amount_field'),
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                      decoration: const InputDecoration(
                        labelText: '金额（元）',
                        prefixText: '¥ ',
                        hintText: '例如 18.5',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text('一级支出', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (primaryCategories.isEmpty)
                  const Text('请先到分类管理中添加并启用一级分类。')
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final category in primaryCategories)
                        ChoiceChip(
                          label: Text(category.name),
                          selected: selectedPrimary == category.id,
                          onSelected: (_) => setState(() {
                            _primaryId = category.id;
                            _secondaryId = null;
                          }),
                        ),
                    ],
                  ),
                const SizedBox(height: 20),
                Text('二级支出', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (selectedPrimary == null)
                  const Text('请先选择一级分类。')
                else if (secondaries.isEmpty)
                  const Text('该一级分类下没有可用的二级分类。')
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final category in secondaries)
                        ChoiceChip(
                          label: Text(category.name),
                          selected: selectedSecondary == category.id,
                          onSelected: (_) =>
                              setState(() => _secondaryId = category.id),
                        ),
                    ],
                  ),
                const SizedBox(height: 20),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.schedule_outlined),
                    title: const Text('消费时间'),
                    subtitle: Text(
                      DateFormat('yyyy年M月d日 HH:mm').format(_spentAt),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _pickSpentAt,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  key: const Key('save_expense_button'),
                  onPressed: _saving ? null : () => _save(selectedSecondary),
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: const Text('保存支出'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _ensureSelectedCategories(
    List<Category> all,
    List<Category> primaryCategories,
  ) {
    final currentPrimary = primaryCategories.where(
      (item) => item.id == _primaryId,
    );
    final validPrimary = currentPrimary.isNotEmpty
        ? currentPrimary.first
        : (primaryCategories.isEmpty ? null : primaryCategories.first);
    final validSecondaries = all
        .where(
          (item) =>
              !item.isPrimary &&
              item.isActive &&
              item.parentId == validPrimary?.id,
        )
        .toList();
    final secondaryStillValid = validSecondaries.any(
      (item) => item.id == _secondaryId,
    );
    if (_primaryId != validPrimary?.id || !secondaryStillValid) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _primaryId = validPrimary?.id;
          _secondaryId = secondaryStillValid
              ? _secondaryId
              : (validSecondaries.isEmpty ? null : validSecondaries.first.id);
        });
      });
    }
  }

  Future<void> _pickSpentAt() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _spentAt.isAfter(now) ? now : _spentAt,
      firstDate: DateTime(2000),
      lastDate: DateUtils.dateOnly(now),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_spentAt),
    );
    if (time == null || !mounted) return;
    final value = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    if (value.isAfter(DateTime.now())) {
      _showMessage('消费时间不能晚于当前时间。');
      return;
    }
    setState(() => _spentAt = value);
  }

  Future<void> _save(int? secondaryId) async {
    if (secondaryId == null) {
      _showMessage('请选择一个可用的二级支出分类。');
      return;
    }
    final amount = Money.tryParseJiao(_amountController.text);
    if (amount == null) {
      _showMessage('请输入大于 ¥0 且最多一位小数的金额。');
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(expenseServiceProvider)
          .create(
            ExpenseDraft(
              amountJiao: amount,
              secondaryCategoryId: secondaryId,
              spentAt: _spentAt,
            ),
          );
      _amountController.clear();
      if (mounted) _showMessage('已保存。');
    } on ExpenseValidationException catch (error) {
      if (mounted) _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showMessage(String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
}
