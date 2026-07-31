class UserModel {
  final int id;
  final String name;
  final String email;
  final ProfileModel? profile;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.profile,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      profile: json['profile'] != null
          ? ProfileModel.fromJson(json['profile'])
          : null,
    );
  }
}

class ProfileModel {
  final String? phone;
  final String currency;
  final double? monthlyBudgetLimit;
  final String? avatar;

  ProfileModel({
    this.phone,
    this.currency = 'PEN',
    this.monthlyBudgetLimit,
    this.avatar,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      phone: json['phone'],
      currency: json['currency'] ?? 'PEN',
      monthlyBudgetLimit: (json['monthly_budget_limit'] as num?)?.toDouble(),
      avatar: json['avatar'],
    );
  }

  Map<String, dynamic> toJson() => {
    'phone': phone,
    'currency': currency,
    'monthly_budget_limit': monthlyBudgetLimit,
  };
}
