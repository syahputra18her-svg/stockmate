
import 'package:flutter/material.dart';

import '../models/product_model.dart';
import '../models/sale_model.dart';
import '../services/product_service.dart';
import '../services/sale_service.dart';

const navy = Color(0xFF173B67);

class SalesPage extends StatefulWidget {
  final String storeId;
  final String email;

  const SalesPage({
    super.key,
    required this.storeId,
    required this.email,
  });

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  final formKey = GlobalKey<FormState>();
  final quantityController = TextEditingController();

  late final ProductService productService;
  late final SaleService saleService;

  String? selectedProductId;
  int quantity = 1;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();

    productService = ProductService(storeId: widget.storeId);
    saleService = SaleService(storeId: widget.storeId);

    quantityController.text = '1';
  }

  @override
  void dispose() {
    quantityController.dispose();
    super.dispose();
  }

  String formatRupiah(int value) {
    final text = value.toString();
    final result = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      result.write(text[i]);

      final remaining = text.length - i - 1;

      if (remaining > 0 && remaining % 3 == 0) {
        result.write('.');
      }
    }

    return 'Rp${result.toString()}';
  }

  void showMessage(String message, {bool error = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> saveTransaction(ProductModel product) async {
    if (isSaving) return;

    if (!formKey.currentState!.validate()) return;

    final jumlah = int.tryParse(quantityController.text.trim());

    if (jumlah == null || jumlah <= 0) {
      showMessage('Jumlah barang tidak valid.', error: true);
      return;
    }

    if (jumlah > product.stok) {
      showMessage(
        'Stok tidak mencukupi. Stok tersedia: ${product.stok}.',
        error: true,
      );
      return;
    }

    final now = DateTime.now();

    final tanggal =
        '${now.day.toString().padLeft(2, '0')}/'
        '${now.month.toString().padLeft(2, '0')}/'
        '${now.year}';

    final sale = SaleModel(
      id: '',
      productId: product.id,
      namaBarang: product.nama,
      harga: product.harga,
      jumlah: jumlah,
      subtotal: product.harga * jumlah,
      tanggal: tanggal,
      waktuMillis: now.millisecondsSinceEpoch,
      kasirEmail: widget.email,
    );

    setState(() {
      isSaving = true;
    });

    try {
      await saleService.saveSale(sale);

      if (!mounted) return;

      quantityController.text = '1';

      showMessage(
        'Transaksi berhasil disimpan. Stok barang telah diperbarui.',
      );
    } catch (e) {
      showMessage(
        'Transaksi gagal: ${e.toString().replaceFirst('Exception: ', '')}',
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  Widget buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: navy,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Penjualan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
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

          final availableProducts = products
              .where((product) => product.stok > 0)
              .toList();

          ProductModel? selectedProduct;

          for (final product in products) {
            if (product.id == selectedProductId) {
              selectedProduct = product;
              break;
            }
          }

          final jumlah =
              int.tryParse(quantityController.text.trim()) ?? 0;

          final total = selectedProduct == null
              ? 0
              : selectedProduct.harga * jumlah;

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 650),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Buat Transaksi Baru',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: navy,
                      ),
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'Pilih barang dan masukkan jumlah pembelian.',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 22),

                    Card(
                      color: Colors.white,
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Form(
                          key: formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Pilih Barang',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 10),

                              if (availableProducts.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  child: Text(
                                    'Belum ada barang dengan stok tersedia.',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                )
                              else
                                DropdownButtonFormField<String>(
                                  initialValue:
                                      availableProducts.any(
                                    (p) => p.id == selectedProductId,
                                  )
                                          ? selectedProductId
                                          : null,
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    hintText: 'Pilih barang',
                                    prefixIcon: const Icon(
                                      Icons.inventory_2_outlined,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(12),
                                    ),
                                  ),
                                  items: availableProducts.map((product) {
                                    return DropdownMenuItem<String>(
                                      value: product.id,
                                      child: Text(
                                        '${product.nama} (Stok: ${product.stok})',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: isSaving
                                      ? null
                                      : (value) {
                                          setState(() {
                                            selectedProductId = value;
                                          });
                                        },
                                  validator: (value) {
                                    if (value == null) {
                                      return 'Silakan pilih barang.';
                                    }
                                    return null;
                                  },
                                ),

                              const SizedBox(height: 20),

                              if (selectedProduct != null) ...[
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(15),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3F6FB),
                                    borderRadius:
                                        BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    children: [
                                      buildInfoRow(
                                        'Nama Barang',
                                        selectedProduct.nama,
                                      ),
                                      buildInfoRow(
                                        'Kategori',
                                        selectedProduct.kategori,
                                      ),
                                      buildInfoRow(
                                        'Harga Satuan',
                                        formatRupiah(
                                          selectedProduct.harga,
                                        ),
                                      ),
                                      buildInfoRow(
                                        'Stok Tersedia',
                                        '${selectedProduct.stok} ${selectedProduct.satuan}',
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],

                              const Text(
                                'Jumlah Pembelian',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 10),

                              TextFormField(
                                controller: quantityController,
                                keyboardType: TextInputType.number,
                                enabled: !isSaving,
                                decoration: InputDecoration(
                                  hintText: 'Masukkan jumlah barang',
                                  prefixIcon: const Icon(
                                    Icons.shopping_cart_outlined,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(12),
                                  ),
                                ),
                                onChanged: (value) {
                                  setState(() {});
                                },
                                validator: (value) {
                                  final number =
                                      int.tryParse(value?.trim() ?? '');

                                  if (number == null || number <= 0) {
                                    return 'Masukkan jumlah lebih dari 0.';
                                  }

                                  if (selectedProduct != null &&
                                      number > selectedProduct.stok) {
                                    return 'Jumlah melebihi stok tersedia.';
                                  }

                                  return null;
                                },
                              ),

                              const SizedBox(height: 22),

                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEAF0F8),
                                  borderRadius:
                                      BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Total Pembayaran',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      formatRupiah(total),
                                      style: const TextStyle(
                                        fontSize: 27,
                                        fontWeight: FontWeight.bold,
                                        color: navy,
                                      ),
                                    ),
                                    if (selectedProduct != null)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(top: 6),
                                        child: Text(
                                          '${formatRupiah(selectedProduct.harga)} × $jumlah barang',
                                          style: const TextStyle(
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 22),

                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton.icon(
                                  onPressed: selectedProduct == null ||
                                          isSaving ||
                                          availableProducts.isEmpty
                                      ? null
                                      : () => saveTransaction(
                                            selectedProduct!,
                                          ),
                                  icon: isSaving
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child:
                                              CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.save_rounded,
                                        ),
                                  label: Text(
                                    isSaving
                                        ? 'Menyimpan Transaksi...'
                                        : 'Simpan Transaksi',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: navy,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Stok barang akan berkurang otomatis setelah transaksi berhasil disimpan.',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
