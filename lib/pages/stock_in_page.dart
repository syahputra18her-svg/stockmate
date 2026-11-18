
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

import '../models/product_model.dart';
import '../services/product_service.dart';

const navy = Color(0xFF173B67);

class StockInPage extends StatefulWidget {
  final String storeId;

  const StockInPage({
    super.key,
    required this.storeId,
  });

  @override
  State<StockInPage> createState() => _StockInPageState();
}

class _StockInPageState extends State<StockInPage> {
  final jumlahController = TextEditingController();
  final keteranganController = TextEditingController();

  String? selectedProductId;
  bool isLoading = false;

  late final ProductService productService;
  late final DatabaseReference rootRef;

  @override
  void initState() {
    super.initState();

    productService = ProductService(storeId: widget.storeId);

    rootRef = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL:
          'https://stockmate-1a9c5-default-rtdb.firebaseio.com',
    ).ref();
  }

  @override
  void dispose() {
    jumlahController.dispose();
    keteranganController.dispose();
    super.dispose();
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> simpanBarangMasuk(
    List<ProductModel> products,
  ) async {
    if (selectedProductId == null) {
      showMessage('Silakan pilih barang terlebih dahulu.');
      return;
    }

    final jumlah = int.tryParse(jumlahController.text.trim());

    if (jumlah == null || jumlah <= 0) {
      showMessage('Jumlah barang harus lebih dari 0.');
      return;
    }

    final productExists = products.any(
      (product) => product.id == selectedProductId,
    );

    if (!productExists) {
      showMessage('Barang tidak ditemukan. Muat ulang halaman.');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final recordRef =
          rootRef.child('stockIn/${widget.storeId}').push();

      final recordId = recordRef.key!;

      final now = DateTime.now();

      // Satu update untuk menambah stok dan menyimpan riwayat.
      // Jika salah satu operasi gagal, keduanya tidak diterapkan.
      await rootRef.update({
        'products/${widget.storeId}/$selectedProductId/stok':
            ServerValue.increment(jumlah),

        'stockIn/${widget.storeId}/$recordId': {
          'productId': selectedProductId,
          'jumlah': jumlah,
          'keterangan': keteranganController.text.trim(),
          'tanggal': now.toIso8601String(),
          'waktuMillis': ServerValue.timestamp,
        },
      });

      if (!mounted) return;

      jumlahController.clear();
      keteranganController.clear();

      setState(() {
        selectedProductId = null;
      });

      showMessage('Barang masuk berhasil disimpan.');
    } catch (e) {
      if (mounted) {
        showMessage('Gagal menyimpan barang masuk: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Barang Masuk'),
        backgroundColor: navy,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<ProductModel>>(
        stream: productService.getProducts(),
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
              child: Text(
                'Belum ada barang. Tambahkan barang terlebih dahulu.',
                textAlign: TextAlign.center,
              ),
            );
          }

          final selectedExists = products.any(
            (product) => product.id == selectedProductId,
          );

          if (!selectedExists) {
            selectedProductId = null;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 650),
                child: Card(
                  color: Colors.white,
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(
                          Icons.add_box_rounded,
                          color: navy,
                          size: 55,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Catat Barang Masuk',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: navy,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Pilih barang dan masukkan jumlah stok yang diterima.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 25),

                        const Text(
                          'Pilih Barang',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),

                        DropdownButtonFormField<String>(
                          initialValue: selectedProductId,
                          isExpanded: true,
                          decoration: InputDecoration(
                            prefixIcon:
                                const Icon(Icons.inventory_2_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          hint: const Text('Pilih barang'),
                          items: products.map((product) {
                            return DropdownMenuItem<String>(
                              value: product.id,
                              child: Text(
                                '${product.nama} (Stok: ${product.stok})',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: isLoading
                              ? null
                              : (value) {
                                  setState(() {
                                    selectedProductId = value;
                                  });
                                },
                        ),

                        const SizedBox(height: 20),
                        const Text(
                          'Jumlah Barang Masuk',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),

                        TextField(
                          controller: jumlahController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'Contoh: 20',
                            prefixIcon:
                                const Icon(Icons.numbers_rounded),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),
                        const Text(
                          'Keterangan (Opsional)',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),

                        TextField(
                          controller: keteranganController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText:
                                'Contoh: Pembelian dari supplier',
                            prefixIcon:
                                const Icon(Icons.notes_rounded),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),

                        const SizedBox(height: 25),

                        SizedBox(
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: isLoading
                                ? null
                                : () => simpanBarangMasuk(products),
                            icon: isLoading
                                ? const SizedBox(
                                    width: 19,
                                    height: 19,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.save_rounded),
                            label: Text(
                              isLoading
                                  ? 'Menyimpan...'
                                  : 'SIMPAN BARANG MASUK',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: navy,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}