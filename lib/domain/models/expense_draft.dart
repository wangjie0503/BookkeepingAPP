/// The editable fields of an expense.
///
/// A primary category is intentionally absent: it is always derived from the
/// secondary category's current parent.
class ExpenseDraft {
  const ExpenseDraft({
    required this.amountJiao,
    required this.secondaryCategoryId,
    required this.spentAt,
  });

  final int amountJiao;
  final int secondaryCategoryId;
  final DateTime spentAt;
}
