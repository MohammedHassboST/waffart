import '../../domain/entities/app_user.dart';

class AppUserModel extends AppUser {
  const AppUserModel({
    required super.id,
    required super.phone,
    required super.fullName,
    required super.role,
    super.businessName,
    super.address,
  });

  factory AppUserModel.fromJson(Map<String, dynamic> json) {
    return AppUserModel(
      id: json['id'] as String,
      phone: json['phone'] as String? ?? '',
      fullName: json['full_name'] as String? ?? 'مستخدم',
      role: json['role'] as String? ?? 'customer',
      businessName: json['business_name'] as String?,
      address: json['address'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'phone': phone,
    'full_name': fullName,
    'role': role,
    'business_name': businessName,
    'address': address,
  };
}