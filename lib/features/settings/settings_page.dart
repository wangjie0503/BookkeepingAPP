import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../shared/money.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _budgetController = TextEditingController();
  bool _initialized = false;
  bool _saving = false;
  bool? _canChangeFundingDay;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() async {
      final allowed = await ref
          .read(settingsServiceProvider)
          .canChangeFundingDay();
      if (mounted) setState(() => _canChangeFundingDay = allowed);
    });
  }

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: settings.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('设置加载失败：$error')),
        data: (value) {
          if (!_initialized) {
            _budgetController.text = _toInput(value.defaultBudgetJiao);
            _initialized = true;
          }
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text('默认月预算', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  TextField(
                    key: const Key('default-budget-input'),
                    controller: _budgetController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: '金额（元）',
                      prefixText: '¥ ',
                      helperText: '新创建的生活费周期会复制当前默认预算。',
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _saving ? null : _saveBudget,
                    child: const Text('保存默认预算'),
                  ),
                  const Divider(height: 48),
                  Text('生活费发放日', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    _canChangeFundingDay == true
                        ? '初始空数据阶段可修改；首次创建周期或支出后将锁定。'
                        : '已有周期或支出，发放日已锁定为每月 ${value.fundingDay} 日。',
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: value.fundingDay,
                    decoration: const InputDecoration(labelText: '每月发放日'),
                    items: [
                      for (var day = 1; day <= 28; day++)
                        DropdownMenuItem(value: day, child: Text('每月 $day 日')),
                    ],
                    onChanged: _canChangeFundingDay == true
                        ? (day) {
                            if (day != null) _saveFundingDay(day);
                          }
                        : null,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _saveBudget() async {
    try {
      final amount = Money.parseNonNegativeJiao(_budgetController.text);
      setState(() => _saving = true);
      await ref.read(settingsServiceProvider).updateDefaultBudget(amount);
      if (mounted) Navigator.of(context).pop();
    } on FormatException catch (error) {
      _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveFundingDay(int day) async {
    try {
      await ref.read(settingsServiceProvider).updateFundingDay(day);
      if (mounted) _showMessage('发放日已更新');
    } on StateError catch (error) {
      if (mounted) {
        setState(() => _canChangeFundingDay = false);
        _showMessage(error.message);
      }
    }
  }

  String _toInput(int amountJiao) {
    final yuan = amountJiao ~/ 10;
    final decimal = amountJiao % 10;
    return '$yuan${decimal == 0 ? '' : '.$decimal'}';
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
