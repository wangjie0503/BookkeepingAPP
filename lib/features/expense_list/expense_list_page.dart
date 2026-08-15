import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../domain/models/budget_period.dart';
import '../../domain/models/category.dart';
import '../../domain/models/expense_draft.dart';
import '../../domain/models/expense_list_item.dart';
import '../../domain/services/expense_service.dart';
import '../../shared/date_range.dart';
import '../../shared/money.dart';

class ExpenseListPage extends ConsumerStatefulWidget {
  const ExpenseListPage({super.key});

  @override
  ConsumerState<ExpenseListPage> createState() => _ExpenseListPageState();
}

class _ExpenseListPageState extends ConsumerState<ExpenseListPage> {
  int? _selectedPeriodId;
  DateRange? _customRange;
  bool _loadingCurrentPeriod = true;

  @override
  void initState() {
    super.initState();
    _ensureCurrentPeriod();
  }

  Future<void> _ensureCurrentPeriod() async {
    try {
      final period = await ref
          .read(periodServiceProvider)
          .ensureCurrentPeriod();
      if (mounted) setState(() => _selectedPeriodId = period.id);
    } finally {
      if (mounted) setState(() => _loadingCurrentPeriod = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final periods = ref.watch(periodsProvider);
    return periods.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('周期加载失败：$error')),
      data: (items) => _buildContent(items),
    );
  }

  Widget _buildContent(List<BudgetPeriod> periods) {
    if (_loadingCurrentPeriod) {
      return const Center(child: CircularProgressIndicator());
    }
    if (periods.isEmpty) {
      return const Center(child: Text('正在创建当前生活费周期…'));
    }
    final selected =
        periods.where((item) => item.id == _selectedPeriodId).firstOrNull ??
        periods.last;
    final range =
        _customRange ?? DateRange(start: selected.startAt, end: selected.endAt);
    final expenses = ref.watch(expensesInRangeProvider(range));
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('支出列表', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        ExpenseRangeSelector(
          periods: periods,
          selected: selected,
          customRange: _customRange,
          onPeriodChanged: (period) => setState(() {
            _selectedPeriodId = period.id;
            _customRange = null;
          }),
          onChooseRange: _chooseCustomRange,
          onReturnToPeriod: () => setState(() => _customRange = null),
          onEditBudget: () => _editPeriodBudget(selected),
        ),
        const SizedBox(height: 16),
        expenses.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Text('支出加载失败：$error'),
          data: _buildExpenseGroups,
        ),
      ],
    );
  }

  Widget _buildExpenseGroups(List<ExpenseListItem> expenses) {
    if (expenses.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text('这段时间还没有支出记录。')),
        ),
      );
    }
    final groups = <DateTime, List<ExpenseListItem>>{};
    for (final item in expenses) {
      final day = DateUtils.dateOnly(item.expense.spentAt);
      groups.putIfAbsent(day, () => []).add(item);
    }
    final days = groups.keys.toList()
      ..sort((left, right) => right.compareTo(left));
    return Column(
      children: [
        for (final day in days) ...[
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                DateFormat('yyyy年M月d日 EEEE', 'zh_CN').format(day),
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
          ),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                for (final item in groups[day]!)
                  ListTile(
                    title: Text(
                      '${item.primaryCategoryName} · ${item.secondaryCategoryName}',
                    ),
                    subtitle: Text(
                      DateFormat('HH:mm').format(item.expense.spentAt),
                    ),
                    trailing: Text(
                      Money.formatJiao(item.expense.amountJiao),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    onTap: () => _openEditor(item),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _chooseCustomRange() async {
    final now = DateUtils.dateOnly(DateTime.now());
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: now,
      initialDateRange: _customRange == null
          ? null
          : DateTimeRange(start: _customRange!.start, end: _customRange!.end),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _customRange = DateRange(
        start: DateUtils.dateOnly(picked.start),
        end: DateRange.endOfDay(picked.end),
      );
    });
  }

  Future<void> _editPeriodBudget(BudgetPeriod period) async {
    final controller = TextEditingController(
      text: Money.formatInputJiao(period.budgetJiao),
    );
    final value = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('修改本期预算'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: '预算（元）',
            prefixText: '¥ ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              Money.tryParseNonNegativeJiao(controller.text),
            ),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null) return;
    await ref.read(periodServiceProvider).updateBudget(period.id, value);
  }

  Future<void> _openEditor(ExpenseListItem item) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ExpenseEditorSheet(item: item),
    );
  }
}

class ExpenseRangeSelector extends StatelessWidget {
  const ExpenseRangeSelector({
    super.key,
    required this.periods,
    required this.selected,
    required this.customRange,
    required this.onPeriodChanged,
    required this.onChooseRange,
    required this.onReturnToPeriod,
    required this.onEditBudget,
  });

  final List<BudgetPeriod> periods;
  final BudgetPeriod selected;
  final DateRange? customRange;
  final ValueChanged<BudgetPeriod> onPeriodChanged;
  final VoidCallback onChooseRange;
  final VoidCallback onReturnToPeriod;
  final VoidCallback onEditBudget;

  @override
  Widget build(BuildContext context) {
    final rangeText = customRange == null
        ? '${DateFormat('M月d日').format(selected.startAt)} – ${DateFormat('M月d日').format(selected.endAt)}'
        : '${DateFormat('yyyy/M/d').format(customRange!.start)} – ${DateFormat('yyyy/M/d').format(customRange!.end)}';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (customRange == null)
              DropdownButtonFormField<int>(
                key: ValueKey(selected.id),
                initialValue: selected.id,
                decoration: const InputDecoration(
                  labelText: '生活费周期',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final period in periods)
                    DropdownMenuItem(
                      value: period.id,
                      child: Text('${period.labelYear}年${period.labelMonth}期'),
                    ),
                ],
                onChanged: (id) {
                  final selectedPeriod = periods.firstWhere(
                    (item) => item.id == id,
                  );
                  onPeriodChanged(selectedPeriod);
                },
              )
            else
              Text('自定义日期范围', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(rangeText),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: onChooseRange,
                  icon: const Icon(Icons.date_range_outlined),
                  label: const Text('自定义范围'),
                ),
                if (customRange != null)
                  OutlinedButton.icon(
                    key: const Key('return_to_period_button'),
                    onPressed: onReturnToPeriod,
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: const Text('返回周期选择'),
                  ),
                if (customRange == null)
                  OutlinedButton.icon(
                    onPressed: onEditBudget,
                    icon: const Icon(Icons.edit_outlined),
                    label: Text(
                      '本期预算 ${Money.formatJiao(selected.budgetJiao)}',
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpenseEditorSheet extends ConsumerStatefulWidget {
  const _ExpenseEditorSheet({required this.item});

  final ExpenseListItem item;

  @override
  ConsumerState<_ExpenseEditorSheet> createState() =>
      _ExpenseEditorSheetState();
}

class _ExpenseEditorSheetState extends ConsumerState<_ExpenseEditorSheet> {
  late final TextEditingController _amountController;
  late int _secondaryId;
  late DateTime _spentAt;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: Money.formatInputJiao(widget.item.expense.amountJiao),
    );
    _secondaryId = widget.item.expense.secondaryCategoryId;
    _spentAt = widget.item.expense.spentAt;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: categories.when(
          loading: () => const SizedBox(
            height: 160,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => SizedBox(
            height: 160,
            child: Center(child: Text('分类加载失败：$error')),
          ),
          data: (all) => _form(all),
        ),
      ),
    );
  }

  Widget _form(List<Category> all) {
    final currentSecondary = all
        .where((item) => item.id == _secondaryId)
        .firstOrNull;
    final activePrimaryIds = all
        .where((item) => item.isPrimary && item.isActive)
        .map((item) => item.id)
        .toSet();
    final selectable = all
        .where(
          (item) =>
              !item.isPrimary &&
              item.isActive &&
              activePrimaryIds.contains(item.parentId),
        )
        .toList();
    final isRetainedUnavailable =
        currentSecondary != null &&
        !selectable.any((item) => item.id == currentSecondary.id);
    final options = <Category>[
      if (isRetainedUnavailable) currentSecondary,
      ...selectable,
    ];
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('编辑支出', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: '金额（元）',
              prefixText: '¥ ',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            key: ValueKey(_secondaryId),
            initialValue: currentSecondary == null ? null : _secondaryId,
            decoration: const InputDecoration(
              labelText: '二级支出分类',
              border: OutlineInputBorder(),
            ),
            items: [
              for (final secondary in options)
                DropdownMenuItem(
                  value: secondary.id,
                  child: Text(
                    '${_categoryPath(all, secondary)}${isRetainedUnavailable && secondary.id == _secondaryId ? '（已停用，保留原分类）' : ''}',
                  ),
                ),
            ],
            onChanged: options.isEmpty
                ? null
                : (value) => setState(() => _secondaryId = value!),
          ),
          if (isRetainedUnavailable) ...[
            const SizedBox(height: 8),
            Text(
              '当前分类已停用；可保留它修改金额或时间，若更换分类只能选择可用分类。',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.schedule_outlined),
            title: const Text('消费时间'),
            subtitle: Text(DateFormat('yyyy年M月d日 HH:mm').format(_spentAt)),
            trailing: const Icon(Icons.edit_calendar_outlined),
            onTap: _pickSpentAt,
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _saving || currentSecondary == null
                ? null
                : () => _save(),
            child: Text(_saving ? '保存中…' : '保存修改'),
          ),
          const SizedBox(height: 4),
          TextButton.icon(
            key: const Key('delete_expense_button'),
            onPressed: _saving ? null : _delete,
            icon: const Icon(Icons.delete_outline),
            label: const Text('删除这笔支出'),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }

  String _categoryPath(List<Category> all, Category secondary) {
    final primary = all
        .where((item) => item.id == secondary.parentId)
        .firstOrNull;
    return primary == null
        ? secondary.name
        : '${primary.name} · ${secondary.name}';
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

  Future<void> _save() async {
    final amount = Money.tryParseJiao(_amountController.text);
    if (amount == null) {
      _showMessage('请输入大于 ¥0 且最多一位小数的金额。');
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(expenseServiceProvider)
          .update(
            widget.item.expense.id,
            ExpenseDraft(
              amountJiao: amount,
              secondaryCategoryId: _secondaryId,
              spentAt: _spentAt,
            ),
          );
      if (mounted) Navigator.pop(context);
    } on ExpenseValidationException catch (error) {
      if (mounted) _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    if (!await confirmExpenseDeletion(context) || !mounted) return;
    await ref.read(expenseServiceProvider).delete(widget.item.expense.id);
    if (mounted) Navigator.pop(context);
  }

  void _showMessage(String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
}

Future<bool> confirmExpenseDeletion(BuildContext context) async {
  final first = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('删除这笔支出？'),
      content: const Text('删除后无法恢复。'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('继续'),
        ),
      ],
    ),
  );
  if (first != true || !context.mounted) return false;
  final second = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('请再次确认删除'),
      content: const Text('这将永久删除该支出记录。'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          child: const Text('永久删除'),
        ),
      ],
    ),
  );
  return second == true;
}

extension _IterableLookup<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
