import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../domain/models/budget_period.dart';
import '../../domain/models/statistics_snapshot.dart';
import '../../domain/services/csv_export_service.dart';
import '../../shared/date_range.dart';
import '../../shared/money.dart';
import '../settings/settings_page.dart';

class OverviewPage extends ConsumerStatefulWidget {
  const OverviewPage({super.key});
  @override
  ConsumerState<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends ConsumerState<OverviewPage> {
  int? _periodId;
  DateRange? _customRange;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrent();
  }

  Future<void> _loadCurrent() async {
    final period = await ref.read(periodServiceProvider).ensureCurrentPeriod();
    if (mounted) {
      setState(() {
        _periodId = period.id;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final periods = ref.watch(periodsProvider);
    return periods.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('周期加载失败：$e')),
      data: _build,
    );
  }

  Widget _build(List<BudgetPeriod> periods) {
    if (_loading || periods.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    final period =
        periods.where((p) => p.id == _periodId).firstOrNull ?? periods.last;
    final range =
        _customRange ?? DateRange(start: period.startAt, end: period.endAt);
    final stats = ref.watch(
      statisticsProvider(
        StatisticsRequest(
          range,
          budgetJiao: _customRange == null ? period.budgetJiao : null,
        ),
      ),
    );
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1080),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            Text('概述统计', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              '看看这一期生活费主要花到了哪里',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            _Selector(
              periods: periods,
              period: period,
              custom: _customRange,
              onPeriod: (p) => setState(() {
                _periodId = p.id;
                _customRange = null;
              }),
              onCustom: _chooseRange,
              onReturn: () => setState(() => _customRange = null),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _export(range),
              icon: const Icon(Icons.file_download_outlined),
              label: const Text('导出 CSV'),
            ),
            const SizedBox(height: 12),
            stats.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('统计加载失败：$e'),
              data: (snapshot) => _content(
                snapshot,
                period,
                isCustomRange: _customRange != null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(
    StatisticsSnapshot s,
    BudgetPeriod period, {
    required bool isCustomRange,
  }) {
    if (!isCustomRange && !s.hasBudget && s.totalJiao == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _noBudgetCard(period),
          const SizedBox(height: 12),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(28),
              child: Center(child: Text('该范围暂时无支出记录，先去记一笔吧。')),
            ),
          ),
        ],
      );
    }
    if (s.totalJiao == 0) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Center(child: Text('该范围暂无支出记录，先去记一笔吧。')),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= 760;
        final cards = s.hasBudget
            ? _budgetCards(s)
            : !isCustomRange
            ? [_noBudgetCard(period)]
            : [
                Card(
                  child: ListTile(
                    title: const Text('总支出'),
                    trailing: Text(Money.formatJiao(s.totalJiao)),
                  ),
                ),
              ];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (wide)
              Row(
                children: [
                  for (final card in cards)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: card,
                      ),
                    ),
                ],
              )
            else
              ...cards,
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('分类去向', style: Theme.of(context).textTheme.titleLarge),
                    SizedBox(
                      height: 230,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 3,
                          centerSpaceRadius: 36,
                          sections: [
                            for (
                              var index = 0;
                              index < s.primaryTotals.length;
                              index++
                            )
                              PieChartSectionData(
                                color:
                                    AppPalette.chartColors[index %
                                        AppPalette.chartColors.length],
                                value: s.primaryTotals[index].amountJiao
                                    .toDouble(),
                                title:
                                    '${s.primaryTotals[index].name}\n${Money.formatJiao(s.primaryTotals[index].amountJiao)}',
                                titleStyle: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                                radius: 76,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            for (final p in s.primaryTotals)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ExpansionTile(
                  title: Text(
                    p.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  trailing: Text(
                    Money.formatJiao(p.amountJiao),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  children: [
                    for (final secondary in p.secondaryTotals)
                      ListTile(
                        title: Text(secondary.name),
                        trailing: Text(Money.formatJiao(secondary.amountJiao)),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('每日趋势', style: Theme.of(context).textTheme.titleLarge),
                    SizedBox(
                      height: 220,
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(
                            show: true,
                            getDrawingHorizontalLine: (_) => const FlLine(
                              color: AppPalette.line,
                              strokeWidth: 1,
                            ),
                            drawVerticalLine: false,
                          ),
                          titlesData: const FlTitlesData(show: false),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              isCurved: true,
                              color: AppPalette.teal,
                              barWidth: 3,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                color: AppPalette.mint,
                              ),
                              spots: [
                                for (var i = 0; i < s.dailyTotals.length; i++)
                                  FlSpot(
                                    i.toDouble(),
                                    s.dailyTotals[i].amountJiao.toDouble(),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _budgetCards(StatisticsSnapshot s) => [
    Card(
      child: ListTile(
        title: const Text('本期预算'),
        trailing: Text(Money.formatJiao(s.budgetJiao!)),
      ),
    ),
    Card(
      child: ListTile(
        title: const Text('已消费'),
        trailing: Text(Money.formatJiao(s.totalJiao)),
      ),
    ),
    Card(
      child: ListTile(
        title: Text(s.overspentJiao == null ? '剩余 / 使用率' : '已超支'),
        trailing: Text(
          s.overspentJiao == null
              ? '${Money.formatJiao(s.remainingJiao!)} · ${((s.usageRate ?? 0) * 100).toStringAsFixed(0)}%'
              : Money.formatJiao(s.overspentJiao!),
        ),
      ),
    ),
  ];

  Widget _noBudgetCard(BudgetPeriod period) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('本期尚未设置预算', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          const Text('设置本期预算后，可查看剩余金额、超支和使用率。'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(
                onPressed: () => _setPeriodBudget(period),
                child: const Text('设置本期预算'),
              ),
              OutlinedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const SettingsPage()),
                ),
                child: const Text('设置默认预算'),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Future<void> _setPeriodBudget(BudgetPeriod period) async {
    final input = await showDialog<String>(
      context: context,
      builder: (_) => const _PeriodBudgetDialog(),
    );
    if (input == null || !mounted) return;
    try {
      final budget = Money.parseNonNegativeJiao(input);
      await ref.read(periodServiceProvider).updateBudget(period.id, budget);
    } on FormatException {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('请输入最多一位小数的有效金额。')));
      }
    }
  }

  Future<void> _chooseRange() async {
    final now = DateUtils.dateOnly(DateTime.now());
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: now,
    );
    if (picked != null && mounted) {
      setState(
        () => _customRange = DateRange(
          start: DateUtils.dateOnly(picked.start),
          end: DateRange.endOfDay(picked.end),
        ),
      );
    }
  }

  Future<void> _export(DateRange range) async {
    await showCsvExportFeedback(
      context,
      () => ref.read(csvExportServiceProvider).export(range),
    );
  }
}

class _PeriodBudgetDialog extends StatefulWidget {
  const _PeriodBudgetDialog();

  @override
  State<_PeriodBudgetDialog> createState() => _PeriodBudgetDialogState();
}

class _PeriodBudgetDialogState extends State<_PeriodBudgetDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('设置本期预算'),
    content: TextField(
      controller: _controller,
      autofocus: true,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: const InputDecoration(labelText: '金额（元）'),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('取消'),
      ),
      FilledButton(
        onPressed: () => Navigator.of(context).pop(_controller.text),
        child: const Text('保存'),
      ),
    ],
  );
}

Future<void> showCsvExportFeedback(
  BuildContext context,
  Future<CsvExportResult> Function() export,
) async {
  try {
    final result = await export();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.shared ? '已打开系统分享。' : '已保存至 ${result.path}'),
      ),
    );
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('CSV 导出失败，请检查文件权限或系统分享服务后重试。')),
    );
  }
}

class _Selector extends StatelessWidget {
  const _Selector({
    required this.periods,
    required this.period,
    required this.custom,
    required this.onPeriod,
    required this.onCustom,
    required this.onReturn,
  });
  final List<BudgetPeriod> periods;
  final BudgetPeriod period;
  final DateRange? custom;
  final ValueChanged<BudgetPeriod> onPeriod;
  final VoidCallback onCustom, onReturn;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (custom == null)
            DropdownButtonFormField<int>(
              key: ValueKey(period.id),
              initialValue: period.id,
              decoration: const InputDecoration(
                labelText: '生活费周期',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final p in periods)
                  DropdownMenuItem(
                    value: p.id,
                    child: Text('${p.labelYear}年${p.labelMonth}期'),
                  ),
              ],
              onChanged: (id) =>
                  onPeriod(periods.firstWhere((p) => p.id == id)),
            )
          else
            Text(
              '自定义范围 ${DateFormat('yyyy/M/d').format(custom!.start)} – ${DateFormat('yyyy/M/d').format(custom!.end)}',
            ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: onCustom,
                icon: const Icon(Icons.date_range_outlined),
                label: const Text('自定义范围'),
              ),
              if (custom != null)
                OutlinedButton.icon(
                  onPressed: onReturn,
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: const Text('返回周期选择'),
                ),
            ],
          ),
        ],
      ),
    ),
  );
}

extension _Lookup<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
