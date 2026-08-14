import 'expense.dart';

/// An expense together with its current category hierarchy for presentation.
///
/// Category labels are deliberately resolved when queried rather than copied
/// into [Expense], so renaming or moving a secondary category reclassifies
/// historical records consistently.
class ExpenseListItem {
  const ExpenseListItem({
    required this.expense,
    required this.primaryCategoryId,
    required this.primaryCategoryName,
    required this.secondaryCategoryName,
  });

  final Expense expense;
  final int primaryCategoryId;
  final String primaryCategoryName;
  final String secondaryCategoryName;
}
