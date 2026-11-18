
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

import '../models/product_model.dart';
import '../services/product_service.dart';

const Color historyNavy = Color(0xFF173B67);

class StockInHistoryPage extends StatelessWidget {
  final String storeId;

  const StockInHistoryPage({
    super.key,
    required this.storeId,
  });

  DatabaseReference get stockInRef {
    final database = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL:
          'https://stockmate-1a9c5-default-rtdb.firebaseio.com',
    );

    return database.ref('stockIn/$storeId');
  }

  String formatDate(dynamic value) {
    if (value == null) return 'Tanggal tidak tersedia';

    final milliseconds = int.tryParse(value.toString());

    if (milliseconds == null) {
      return 'Tanggal tidak tersedia';
    }

    final date = DateTime.fromMillisecondsSinceEpoch(
      milliseconds,
    );

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day/$month/$year • $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final productService = ProductService(storeId: storeId);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Riwayat Barang Masuk',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: historyNavy,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<ProductModel>>(
        stream: productService.getProducts(),
        builder: (context, productSnapshot) {
          if (productSnapshot.hasError) {
            return const Center(
              child: Text('Gagal memuat data barang.'),
            );
          }

          if (!productSnapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final products = productSnapshot.data!;

          final productNames = {
            for (final product in products)
              product.id: product.nama,
          };

          return StreamBuilder<DatabaseEvent>(
            stream: stockInRef.onValue,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(
                  child: Text('Gagal memuat riwayat barang masuk.'),
                );
              }

              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final data = snapshot.data!.snapshot.value;

              if (data == null) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 65,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Belum ada riwayat barang masuk.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              final records =
                  (data as Map<dynamic, dynamic>).entries.toList();

              records.sort((a, b) {
                final timeA = int.tryParse(
                      (a.value['waktuMillis'] ??
                              a.value['tanggal'] ??
                              0)
                          .toString(),
                    ) ??
                    0;

                final timeB = int.tryParse(
                      (b.value['waktuMillis'] ??
                              b.value['tanggal'] ??
                              0)
                          .toString(),
                    ) ??
                    0;

                return timeB.compareTo(timeA);
              });

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: records.length,
                itemBuilder: (context, index) {
                  final record = Map<dynamic, dynamic>.from(
                    records[index].value as Map,
                  );

                  final productId =
                      (record['productId'] ?? '').toString();

                  final productName =
                      productNames[productId] ?? 'Barang tidak ditemukan';

                  final quantity =
                      (record['jumlah'] as num?)?.toInt() ?? 0;

                  final note =
                      (record['keterangan'] ?? '').toString();

                  final dateValue =
                      record['waktuMillis'] ?? record['tanggal'];

                  return Card(
                    color: Colors.white,
                    elevation: 1,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(11),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius:
                                      BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.add_box_rounded,
                                  color: Colors.green,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 13),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      productName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      formatDate(dateValue),
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '+$quantity',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          if (note.isNotEmpty) ...[
                            const Divider(height: 25),
                            const Text(
                              'Keterangan:',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              note,
                              style: const TextStyle(
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
