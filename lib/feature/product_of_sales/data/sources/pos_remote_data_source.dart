import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gear_track/feature/product_of_sales/data/models/sale_model.dart';

abstract class PosRemoteDataSource {
  Future<void> addSale(SaleModel saleModel);
  Future<List<SaleModel>> getSales();
}

class PosRemoteDataSourceImpl implements PosRemoteDataSource {
  final FirebaseFirestore firestore;

  PosRemoteDataSourceImpl({required this.firestore});

  @override
  Future<void> addSale(SaleModel saleModel) async {
    await firestore
        .collection('sales')
        .doc(saleModel.id)
        .set(saleModel.toMap());
  }

  @override
  Future<List<SaleModel>> getSales() async {
    final snapshot = await firestore.collection('sales').get();
    return snapshot.docs.map((doc) => SaleModel.fromFirestore(doc)).toList();
  }
}
