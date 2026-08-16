import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/models/category.dart';
import '../../domain/services/category_service.dart';

class CategoryManagementPage extends ConsumerWidget {
  const CategoryManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    return categories.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('分类加载失败：$error')),
      data: (items) => _CategoryList(categories: items),
    );
  }
}

class _CategoryList extends ConsumerWidget {
  const _CategoryList({required this.categories});
  final List<Category> categories;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primaries = categories.where((item) => item.isPrimary).toList();
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 840),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            Text('分类管理', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .primaryContainer,
                      child: Icon(
                        Icons.account_tree_outlined,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '管理一级和二级分类。停用分类会保留历史账单，名称仍不可重复。',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (primaries.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('还没有分类，请先新增一级分类。'),
                ),
              ),
            for (final primary in primaries)
              _PrimaryCategoryCard(
                primary: primary,
                children: categories
                    .where((item) => item.parentId == primary.id)
                    .toList(),
                allCategories: categories,
              ),
            const SizedBox(height: 12),
            FilledButton.icon(
              key: const Key('add-primary-category'),
              onPressed: () => _addPrimary(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('新增一级分类'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryCategoryCard extends ConsumerWidget {
  const _PrimaryCategoryCard({
    required this.primary,
    required this.children,
    required this.allCategories,
  });

  final Category primary;
  final List<Category> children;
  final List<Category> allCategories;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    clipBehavior: Clip.antiAlias,
    child: ExpansionTile(
      initiallyExpanded: primary.isActive,
      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Icon(
          Icons.folder_outlined,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              primary.name,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          _StatusChip(isActive: primary.isActive),
        ],
      ),
      subtitle: Text('${children.length} 个二级分类'),
      trailing: _CategoryMenu(category: primary, allCategories: allCategories),
      children: [
        for (final child in children)
          ListTile(
            contentPadding: const EdgeInsets.only(left: 32, right: 8),
            leading: const Icon(
              Icons.subdirectory_arrow_right_outlined,
              size: 20,
            ),
            title: Text(child.name),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _StatusChip(isActive: child.isActive),
                _CategoryMenu(category: child, allCategories: allCategories),
              ],
            ),
          ),
        ListTile(
          enabled: primary.isActive,
          leading: const Icon(Icons.add),
          title: const Text('新增二级分类'),
          onTap: primary.isActive
              ? () => _addSecondary(context, ref, primary)
              : null,
        ),
      ],
    ),
  );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.isActive});
  final bool isActive;

  @override
  Widget build(BuildContext context) => Chip(
    visualDensity: VisualDensity.compact,
    backgroundColor: isActive
        ? Theme.of(context).colorScheme.primaryContainer
        : Theme.of(context).colorScheme.surfaceContainerHighest,
    side: BorderSide.none,
    label: Text(isActive ? '启用' : '已停用'),
  );
}

class _CategoryMenu extends ConsumerWidget {
  const _CategoryMenu({required this.category, required this.allCategories});
  final Category category;
  final List<Category> allCategories;

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) => PopupMenuButton<_MenuAction>(
    tooltip: '分类操作',
    onSelected: (action) => switch (action) {
      _MenuAction.rename => _rename(context, ref, category),
      _MenuAction.addChild => _addSecondary(context, ref, category),
      _MenuAction.move => _moveSecondary(context, ref, category, allCategories),
      _MenuAction.toggleActive => _toggleActive(context, ref, category),
    },
    itemBuilder: (context) => [
      const PopupMenuItem(value: _MenuAction.rename, child: Text('改名')),
      if (category.isPrimary && category.isActive)
        const PopupMenuItem(value: _MenuAction.addChild, child: Text('新增二级分类')),
      if (!category.isPrimary)
        const PopupMenuItem(value: _MenuAction.move, child: Text('移动到其他一级分类')),
      PopupMenuItem(
        value: _MenuAction.toggleActive,
        child: Text(category.isActive ? '停用' : '恢复'),
      ),
    ],
  );
}

enum _MenuAction { rename, addChild, move, toggleActive }

Future<void> _addPrimary(BuildContext context, WidgetRef ref) async {
  final name = await _askForName(context, title: '新增一级分类');
  if (name == null || !context.mounted) return;
  await _createWithRestoreOption(
    context,
    ref,
    () => ref.read(categoryServiceProvider).addPrimary(name),
  );
}

Future<void> _addSecondary(
  BuildContext context,
  WidgetRef ref,
  Category primary,
) async {
  final name = await _askForName(context, title: '新增「${primary.name}」的二级分类');
  if (name == null || !context.mounted) return;
  await _createWithRestoreOption(
    context,
    ref,
    () => ref.read(categoryServiceProvider).addSecondary(primary.id, name),
  );
}

Future<void> _rename(
  BuildContext context,
  WidgetRef ref,
  Category category,
) async {
  final name = await _askForName(
    context,
    title: '修改分类名称',
    initialValue: category.name,
  );
  if (name == null || !context.mounted) return;
  try {
    await ref.read(categoryServiceProvider).rename(category.id, name);
  } on CategoryNameConflict catch (error) {
    if (!context.mounted) return;
    _showMessage(context, '「${error.existing.name}」已存在，请使用其他名称。');
  } on CategoryValidationException catch (error) {
    if (!context.mounted) return;
    _showMessage(context, error.message);
  }
}

Future<void> _toggleActive(
  BuildContext context,
  WidgetRef ref,
  Category category,
) async {
  await ref
      .read(categoryServiceProvider)
      .setActive(category.id, !category.isActive);
  if (context.mounted) {
    _showMessage(
      context,
      category.isActive ? '已停用「${category.name}」' : '已恢复「${category.name}」',
    );
  }
}

Future<void> _moveSecondary(
  BuildContext context,
  WidgetRef ref,
  Category secondary,
  List<Category> categories,
) async {
  final choices = categories
      .where(
        (item) =>
            item.isPrimary && item.isActive && item.id != secondary.parentId,
      )
      .toList();
  if (choices.isEmpty) {
    _showMessage(context, '没有其他启用中的一级分类可移动。');
    return;
  }
  final parentId = await showDialog<int>(
    context: context,
    builder: (dialogContext) => SimpleDialog(
      title: Text('移动「${secondary.name}」'),
      children: [
        for (final primary in choices)
          SimpleDialogOption(
            onPressed: () => Navigator.pop(dialogContext, primary.id),
            child: Text(primary.name),
          ),
      ],
    ),
  );
  if (parentId == null || !context.mounted) return;
  try {
    await ref
        .read(categoryServiceProvider)
        .moveSecondary(secondary.id, parentId);
  } on CategoryValidationException catch (error) {
    if (context.mounted) _showMessage(context, error.message);
  }
}

Future<void> _createWithRestoreOption(
  BuildContext context,
  WidgetRef ref,
  Future<Category> Function() create,
) async {
  try {
    await create();
  } on CategoryNameConflict catch (error) {
    if (!context.mounted) return;
    if (error.existing.isActive) {
      _showMessage(context, '「${error.existing.name}」已存在。');
      return;
    }
    final restore = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('发现已停用分类'),
        content: Text('「${error.existing.name}」已停用。是否恢复原分类？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('恢复'),
          ),
        ],
      ),
    );
    if (restore == true) {
      await ref
          .read(categoryServiceProvider)
          .setActive(error.existing.id, true);
    }
  } on CategoryValidationException catch (error) {
    if (!context.mounted) return;
    _showMessage(context, error.message);
  }
}

Future<String?> _askForName(
  BuildContext context, {
  required String title,
  String initialValue = '',
}) => showDialog<String>(
  context: context,
  builder: (_) => _CategoryNameDialog(title: title, initialValue: initialValue),
);

class _CategoryNameDialog extends StatefulWidget {
  const _CategoryNameDialog({required this.title, required this.initialValue});

  final String title;
  final String initialValue;

  @override
  State<_CategoryNameDialog> createState() => _CategoryNameDialogState();
}

class _CategoryNameDialogState extends State<_CategoryNameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: TextField(
      key: const Key('category-name-input'),
      controller: _controller,
      autofocus: true,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => Navigator.pop(context, _controller.text),
      decoration: const InputDecoration(labelText: '分类名称'),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('取消'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, _controller.text),
        child: const Text('保存'),
      ),
    ],
  );
}

void _showMessage(BuildContext context, String message) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
