
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

import '../models/sale_model.dart';

class SaleService {
  final FirebaseDatabase _database = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://stockmate-1a9c5-default-rtdb.firebaseio.com',
  );

  final String storeId;

  SaleService({required this.storeId});

  DatabaseReference get _salesRef =>
      _database.ref('sales/$storeId');

  // Menyimpan transaksi sekaligus mengurangi stok barang.
  Future<void> saveSale(SaleModel sale) async {
    if (sale.jumlah <= 0) {
      throw Exception('Jumlah barang harus lebih dari 0.');
    }

    final saleRef = _salesRef.push();

    // Simpan transaksi terlebih dahulu.
    await saleRef.set(sale.toMap());

    // Referensi stok barang yang dijual.
    final stockRef = _database.ref(
      'products/$storeId/${sale.productId}/stok',
    );

    try {
      // Kurangi stok menggunakan transaction agar tidak
      // mengurangi stok yang sama secara bersamaan.
      final result = await stockRef.runTransaction(
        (Object? currentData) {
          if (currentData == null || currentData is! num) {
            return Transaction.abort();
          }

          final stokSekarang = currentData.toInt();

          if (stokSekarang < sale.jumlah) {
            return Transaction.abort();
          }

          final stokBaru = stokSekarang - sale.jumlah;

          return Transaction.success(stokBaru);
        },
        applyLocally: false,
      );

      if (!result.committed) {
        await saleRef.remove();
        throw Exception(
          'Transaksi dibatalkan. Stok barang tidak mencukupi.',
        );
      }
    } catch (e) {
      // Hapus catatan transaksi jika pengurangan stok gagal.
      await saleRef.remove();
      rethrow;
    }
  }

  // Mengambil riwayat penjualan.
  Stream<List<SaleModel>> getSales() {
    return _salesRef.onValue.map((event) {
      final data = event.snapshot.value;

      if (data == null) {
        return <SaleModel>[];
      }

      final Map<dynamic, dynamic> sales =
          data as Map<dynamic, dynamic>;

      final result = sales.entries.map((entry) {
        return SaleModel.fromMap(
          entry.key.toString(),
          entry.value as Map<dynamic, dynamic>,
        );
      }).toList();

      result.sort(
        (a, b) => b.waktuMillis.compareTo(a.waktuMillis),
      );

      return result;
    });
  }
}
