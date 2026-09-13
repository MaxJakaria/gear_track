import 'package:equatable/equatable.dart';

/// Entity representing Shop/Business settings for receipts and invoices.
class ShopSettings extends Equatable {
  final String shopName;
  final String address;
  final String phone;
  final String email;

  const ShopSettings({
    this.shopName = '',
    this.address = '',
    this.phone = '',
    this.email = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'shopName': shopName,
      'address': address,
      'phone': phone,
      'email': email,
    };
  }

  factory ShopSettings.fromMap(Map<String, dynamic> map) {
    return ShopSettings(
      shopName: map['shopName'] as String? ?? '',
      address: map['address'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      email: map['email'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [shopName, address, phone, email];
}
