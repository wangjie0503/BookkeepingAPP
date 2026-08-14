import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

@DataClassName('CategoryRow')
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
  IntColumn get parentId => integer().nullable().references(
    Categories,
    #id,
    onDelete: KeyAction.restrict,
  )();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  IntColumn get sortOrder => integer()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

@DataClassName('ExpenseRow')
class Expenses extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get amountJiao => integer()();
  IntColumn get secondaryCategoryId =>
      integer().references(Categories, #id, onDelete: KeyAction.restrict)();
  DateTimeColumn get spentAt => dateTime()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  List<String> get customConstraints => const ['CHECK(amount_jiao > 0)'];
}

@DataClassName('BudgetPeriodRow')
class BudgetPeriods extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get labelYear => integer()();
  IntColumn get labelMonth => integer()();
  DateTimeColumn get startAt => dateTime()();
  DateTimeColumn get endAt => dateTime()();
  IntColumn get budgetJiao => integer()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  List<String> get customConstraints => const [
    'UNIQUE(label_year, label_month)',
    'CHECK(start_at < end_at)',
    'CHECK(budget_jiao >= 0)',
  ];
}

@DataClassName('AppSettingsRow')
class AppSettingsTable extends Table {
  IntColumn get id => integer()();
  IntColumn get defaultBudgetJiao => integer()();
  IntColumn get fundingDay => integer()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => const [
    'CHECK(default_budget_jiao >= 0)',
    'CHECK(funding_day BETWEEN 1 AND 28)',
  ];
}

@DriftDatabase(tables: [Categories, Expenses, BudgetPeriods, AppSettingsTable])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_expenses_spent_at ON expenses(spent_at)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_expenses_secondary_category '
        'ON expenses(secondary_category_id)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_categories_parent ON categories(parent_id)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_budget_periods_range '
        'ON budget_periods(start_at, end_at)',
      );
      await _seedDefaults();
    },
    onUpgrade: (migrator, from, to) async {
      // Future schema versions must append non-destructive migrations here.
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  Future<void> _seedDefaults() async {
    final now = DateTime.now();
    await transaction(() async {
      await into(appSettingsTable).insert(
        AppSettingsTableCompanion.insert(
          id: const Value(1),
          defaultBudgetJiao: 0,
          fundingDay: 25,
        ),
      );

      const defaults = <String, List<String>>{
        '餐饮': ['早餐', '午餐', '晚餐', '饮品', '水果', '零食'],
        '交通': ['公交', '地铁', '打车', '骑行'],
        '生活': ['日用品', '洗护', '衣物', '医疗'],
        '学习': ['书籍', '学习用品', '软件服务'],
        '娱乐': ['游戏', '影音', '聚会'],
        '数码': ['数码产品', '配件'],
        '其他支出': ['杂项'],
      };
      var primaryOrder = 0;
      for (final entry in defaults.entries) {
        final parentId = await into(categories).insert(
          CategoriesCompanion.insert(
            name: entry.key,
            sortOrder: primaryOrder++,
            createdAt: now,
            updatedAt: now,
          ),
        );
        for (var index = 0; index < entry.value.length; index++) {
          await into(categories).insert(
            CategoriesCompanion.insert(
              name: entry.value[index],
              parentId: Value(parentId),
              sortOrder: index,
              createdAt: now,
              updatedAt: now,
            ),
          );
        }
      }
    });
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationSupportDirectory();
    return NativeDatabase.createInBackground(
      File(
        '${directory.path}${Platform.pathSeparator}personal_bookkeeping.sqlite',
      ),
    );
  });
}
