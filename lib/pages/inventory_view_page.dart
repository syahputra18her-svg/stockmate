import 'package:flutter/material.dart';

import '../models/product_model.dart';
import '../services/product_service.dart';

const navy = Color(0xFF173B67);

class InventoryViewPage extends StatelessWidget {
  final String storeId;

  const InventoryViewPage({
    super.key,
    required this.storeId,
  });

  @override
  Widget build(BuildContext context) {
    final service = ProductService(storeId: storeId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Barang'),
        backgroundColor: navy,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<ProductModel>>(
        stream: service.getProducts(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Gagal memuat data barang.'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final products = snapshot.data!;

          if (products.isEmpty) {
            return const Center(
              child: Text('Belum ada data barang.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];

              final isLowStock =
                  product.stok <= product.stokMinimum;

              return Card(
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.nama,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text('Kategori: ${product.kategori}'),
                      Text(
                        'Harga: Rp${product.harga}',
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Text(
                            'Stok: ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${product.stok} ${product.satuan}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isLowStock
                                  ? Colors.red
                                  : Colors.green,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: isLowStock
                                  ? Colors.red.shade50
                                  : Colors.green.shade50,
                              borderRadius:
                                  BorderRadius.circular(20),
                            ),
                            child: Text(
                              isLowStock
                                  ? 'Stok Menipis'
                                  : 'Stok Aman',
                              style: TextStyle(
                                color: isLowStock
                                    ? Colors.red
                                    : Colors.green,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}