import 'package:equatable/equatable.dart';

/// Entity representing Shop/Business settings for receipts and invoices.
class ShopSettings extends Equatable {
  final String shopName;
  final String address;
  final String phone;

  const ShopSettings({
    this.shopName = 'GearTrack POS',
    this.address = '',
    this.phone = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'shopName': shopName,
      'address': address,
      'phone': phone,
    };
  }

  factory ShopSettings.fromMap(Map<String, dynamic> map) {
    return ShopSettings(
      shopName: map['shopName'] as String? ?? 'GearTrack POS',
      address: map['address'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [shopName, address, phone];
}
