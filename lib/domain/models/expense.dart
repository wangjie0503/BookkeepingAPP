class Expense {
  const Expense({
    required this.id,
    required this.amountJiao,
    required this.secondaryCategoryId,
    required this.spentAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int amountJiao;
  final int secondaryCategoryId;
  final DateTime spentAt;
  final DateTime createdAt;
  final DateTime updatedAt;
}
