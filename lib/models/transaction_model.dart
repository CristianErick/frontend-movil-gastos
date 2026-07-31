double _parseAmount(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

class TransactionModel {
  final int id;
  final int categoryId;
  final double amount;
  final String description;
  final DateTime date;
  final String type;
  final String? referenceImage;
  final CategoryModel? category;

  TransactionModel({
    required this.id,
    required this.categoryId,
    required this.amount,
    required this.description,
    required this.date,
    required this.type,
    this.referenceImage,
    this.category,
  });

  static double _parseAmount(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'],
      categoryId: json['category_id'],
      amount: _parseAmount(json['amount']),
      description: json['description'],
      date: DateTime.parse(json['date']),
      type: json['type'],
      referenceImage: json['reference_image'],
      category: json['category'] != null
          ? CategoryModel.fromJson(json['category'])
          : null,
    );
  }
}

class CategoryModel {
  final int id;
  final String name;
  final String type;
  final String? icon;
  final String? color;

  CategoryModel({
    required this.id,
    required this.name,
    required this.type,
    this.icon,
    this.color,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      icon: json['icon'],
      color: json['color'],
    );
  }
}

class SavingsGoalModel {
  final int id;
  final String title;
  final double targetAmount;
  final double currentAmount;
  final DateTime deadline;

  SavingsGoalModel({
    required this.id,
    required this.title,
    required this.targetAmount,
    required this.currentAmount,
    required this.deadline,
  });

  factory SavingsGoalModel.fromJson(Map<String, dynamic> json) {
    return SavingsGoalModel(
      id: json['id'],
      title: json['title'],
      targetAmount: _parseAmount(json['target_amount']),
      currentAmount: _parseAmount(json['current_amount']),
      deadline: DateTime.parse(json['deadline']),
    );
  }

  double get progress => targetAmount > 0 ? currentAmount / targetAmount : 0;
}
