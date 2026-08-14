class Category {
  const Category({
    required this.id,
    required this.name,
    required this.parentId,
    required this.isActive,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String name;
  final int? parentId;
  final bool isActive;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isPrimary => parentId == null;
}
