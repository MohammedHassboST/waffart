class AppUser {
  final String id;
  final String phone;
  final String fullName;
  final String role; // customer, vendor, admin
  final String? businessName;
  final String? address;

  const AppUser({
    required this.id,
    required this.phone,
    required this.fullName,
    required this.role,
    this.businessName,
    this.address,
  });

  bool get isVendor => role == 'vendor';
  bool get isAdmin => role == 'admin';
  bool get isCustomer => role == 'customer';
}