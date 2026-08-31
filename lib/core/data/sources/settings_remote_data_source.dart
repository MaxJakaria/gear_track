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
  }

  @override
  Future<void> saveCostCodeMapping(CostCodeMapping mapping) async {
    await firestore.collection(_settingsCollection).doc(_costCodeDoc).set({
      'mapping': mapping.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<ShopSettings> getShopSettings() async {
    final doc = await firestore
        .collection(_settingsCollection)
        .doc(_shopDoc)
        .get();

    if (!doc.exists || doc.data() == null) {
      return const ShopSettings();
    }

    final data = doc.data()!;
    return ShopSettings.fromMap(data);
  }

  @override
  Future<void> saveShopSettings(ShopSettings settings) async {
    await firestore.collection(_settingsCollection).doc(_shopDoc).set({
      ...settings.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
