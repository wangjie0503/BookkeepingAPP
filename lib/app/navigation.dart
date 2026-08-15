import 'package:flutter/material.dart';

import '../features/category_management/category_management_page.dart';
import '../features/expense_entry/expense_entry_page.dart';
import '../features/expense_list/expense_list_page.dart';
import '../features/overview/overview_page.dart';
import '../features/settings/settings_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const _items = <_NavigationItem>[
    _NavigationItem('记一笔', Icons.add_circle_outline),
    _NavigationItem('支出列表', Icons.format_list_bulleted),
    _NavigationItem('分类管理', Icons.grid_view_outlined),
    _NavigationItem('概述统计', Icons.pie_chart_outline),
  ];

  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 760;
    final page = switch (_index) {
      0 => const ExpenseEntryPage(),
      1 => const ExpenseListPage(),
      2 => const CategoryManagementPage(),
      _ => const OverviewPage(),
    };
    final content = Scaffold(
      appBar: AppBar(
        title: Text(
          wide ? _items[_index].label : '个人记账 · ${_items[_index].label}',
        ),
        actions: [
          IconButton(
            tooltip: '设置',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SettingsPage()),
            ),
          ),
        ],
      ),
      body: page,
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (index) => setState(() => _index = index),
              destinations: [
                for (final item in _items)
                  NavigationDestination(
                    icon: Icon(item.icon),
                    label: item.label,
                  ),
              ],
            ),
    );
    if (!wide) return content;
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _index,
            labelType: NavigationRailLabelType.all,
            onDestinationSelected: (index) => setState(() => _index = index),
            leading: const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Icon(Icons.account_balance_wallet_outlined),
            ),
            destinations: [
              for (final item in _items)
                NavigationRailDestination(
                  icon: Icon(item.icon),
                  label: Text(item.label),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: content),
        ],
      ),
    );
  }
}

class _NavigationItem {
  const _NavigationItem(this.label, this.icon);
  final String label;
  final IconData icon;
}
