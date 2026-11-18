
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

import '../models/product_model.dart';

class ProductService {
  // Alamat Firebase Realtime Database StockMate.
  final FirebaseDatabase _database = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://stockmate-1a9c5-default-rtdb.firebaseio.com',
  );

  final String storeId;

  ProductService({required this.storeId});

  // Mengambil alamat data barang berdasarkan toko.
  DatabaseReference get _productsRef =>
      _database.ref('products/$storeId');

  // 1. Menampilkan data barang secara real-time.
  Stream<List<ProductModel>> getProducts() {
    return _productsRef.onValue.map((event) {
      final data = event.snapshot.value;

      if (data == null) {
        return <ProductModel>[];
      }

      final Map<dynamic, dynamic> products =
          data as Map<dynamic, dynamic>;

      return products.entries.map((entry) {
        return ProductModel.fromMap(
          entry.key.toString(),
          entry.value as Map<dynamic, dynamic>,
        );
      }).toList();
    });
  }

  // 2. Menambahkan barang baru.
  Future<void> addProduct(ProductModel product) async {
    final newProductRef = _productsRef.push();

    await newProductRef.set(product.toMap());
  }

  // 3. Mengedit data barang.
  Future<void> updateProduct(ProductModel product) async {
    await _productsRef.child(product.id).update(
      product.toMap(),
    );
  }

  // 4. Menghapus barang.
  Future<void> deleteProduct(String productId) async {
    await _productsRef.child(productId).remove();
  }
}
