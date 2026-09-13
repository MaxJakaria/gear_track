import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gear_track/core/entities/cost_code_mapping.dart';
import 'package:gear_track/core/entities/shop_settings.dart';

abstract class SettingsRemoteDataSource {
  Future<CostCodeMapping> getCostCodeMapping();
  Future<void> saveCostCodeMapping(CostCodeMapping mapping);

  Future<ShopSettings> getShopSettings();
  Future<void> saveShopSettings(ShopSettings settings);
}

class SettingsRemoteDataSourceImpl implements SettingsRemoteDataSource {
  final FirebaseFirestore firestore;

  SettingsRemoteDataSourceImpl({required this.firestore});

  static const String _settingsCollection = 'app_settings';
  static const String _costCodeDoc = 'cost_code_mapping';
  static const String _shopDoc = 'shop_settings';

  @override
  Future<CostCodeMapping> getCostCodeMapping() async {
    try {
      final doc = await firestore
          .collection(_settingsCollection)
          .doc(_costCodeDoc)
          .get();

      if (!doc.exists || doc.data() == null) {
        return CostCodeMapping.defaultMapping();
      }

      final data = doc.data()!;
      final mappingData = data['mapping'] as Map<String, dynamic>?;
      if (mappingData == null || mappingData.isEmpty) {
        return CostCodeMapping.defaultMapping();
      }

      return CostCodeMapping.fromMap(mappingData);
    } catch (_) {
      return CostCodeMapping.defaultMapping();
    }
  }

  @override
  Future<void> saveCostCodeMapping(CostCodeMapping mapping) async {
    // Overwrite document completely so deleted keys/symbols are removed from Firestore
    await firestore.collection(_settingsCollection).doc(_costCodeDoc).set({
      'mapping': mapping.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<ShopSettings> getShopSettings() async {
    try {
      final doc = await firestore
          .collection(_settingsCollection)
          .doc(_shopDoc)
          .get();

      if (!doc.exists || doc.data() == null) {
        return const ShopSettings();
      }

      final data = doc.data()!;
      return ShopSettings.fromMap(data);
    } catch (_) {
      return const ShopSettings();
    }
  }

  @override
  Future<void> saveShopSettings(ShopSettings settings) async {
    // Overwrite document completely so updated fields are cleanly saved
    await firestore.collection(_settingsCollection).doc(_shopDoc).set({
      'shopName': settings.shopName.trim(),
      'address': settings.address.trim(),
      'phone': settings.phone.trim(),
      'email': settings.email.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
