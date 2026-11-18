
import 'package:flutter/material.dart';

import '../models/product_model.dart';
import '../services/product_service.dart';

class ProductPage extends StatefulWidget {
  final String storeId;

  const ProductPage({
    super.key,
    required this.storeId,
  });

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  late ProductService productService;

  static const Color navy = Color(0xFF173B67);
  static const Color background = Color(0xFFF3F6FB);

  @override
  void initState() {
    super.initState();
    productService = ProductService(storeId: widget.storeId);
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Form tambah dan edit barang.
  void showProductForm({ProductModel? product}) {
    final isEdit = product != null;

    final namaController =
        TextEditingController(text: product?.nama ?? '');
    final kategoriController =
        TextEditingController(text: product?.kategori ?? '');
    final hargaController =
        TextEditingController(text: product?.harga.toString() ?? '');
    final stokController =
        TextEditingController(text: product?.stok.toString() ?? '');
    final satuanController =
        TextEditingController(text: product?.satuan ?? '');
    final minimumController =
        TextEditingController(
          text: product?.stokMinimum.toString() ?? '5',
        );

    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                isEdit ? 'Edit Barang' : 'Tambah Barang',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SizedBox(
                width: 450,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        buildTextField(
                          controller: namaController,
                          label: 'Nama Barang',
                        ),
                        buildTextField(
                          controller: kategoriController,
                          label: 'Kategori',
                        ),
                        buildTextField(
                          controller: hargaController,
                          label: 'Harga',
                          number: true,
                        ),
                        buildTextField(
                          controller: stokController,
                          label: 'Jumlah Stok',
                          number: true,
                        ),
                        buildTextField(
                          controller: satuanController,
                          label: 'Satuan (kg, pcs, liter, dll.)',
                        ),
                        buildTextField(
                          controller: minimumController,
                          label: 'Stok Minimum',
                          number: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: navy,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) {
                            return;
                          }

                          setDialogState(() {
                            isSaving = true;
                          });

                          final newProduct = ProductModel(
                            id: product?.id ?? '',
                            nama: namaController.text.trim(),
                            kategori: kategoriController.text.trim(),
                            harga: int.parse(hargaController.text),
                            stok: int.parse(stokController.text),
                            satuan: satuanController.text.trim(),
                            stokMinimum:
                                int.parse(minimumController.text),
                          );

                          try {
                            if (isEdit) {
                              await productService.updateProduct(
                                newProduct,
                              );
                            } else {
                              await productService.addProduct(
                                newProduct,
                              );
                            }

                            if (!dialogContext.mounted) return;

                            Navigator.pop(dialogContext);

                            showMessage(
                              isEdit
                                  ? 'Data barang berhasil diperbarui'
                                  : 'Barang berhasil ditambahkan',
                            );
                          } catch (e) {
                            setDialogState(() {
                              isSaving = false;
                            });

                            showMessage('Gagal menyimpan barang: $e');
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(isEdit ? 'Simpan Perubahan' : 'Simpan'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      namaController.dispose();
      kategoriController.dispose();
      hargaController.dispose();
      stokController.dispose();
      satuanController.dispose();
      minimumController.dispose();
    });
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String label,
    bool number = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: number
            ? TextInputType.number
            : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return '$label wajib diisi';
          }

          if (number) {
            final parsed = int.tryParse(value.trim());

            if (parsed == null || parsed < 0) {
              return 'Masukkan angka bulat minimal 0';
            }
          }

          return null;
        },
      ),
    );
  }

  // Konfirmasi sebelum menghapus barang.
  Future<void> confirmDelete(ProductModel product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus Barang'),
          content: Text(
            'Apakah kamu yakin ingin menghapus ${product.nama}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await productService.deleteProduct(product.id);
      if (!mounted) return;
      showMessage('Barang berhasil dihapus');
    } catch (e) {
      if (!mounted) return;
      showMessage('Gagal menghapus barang: $e');
    }
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

  Widget buildProductCard(ProductModel product) {
    final lowStock = product.stok <= product.stokMinimum;

    return Card(
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
                Expanded(
                  child: Text(
                    product.nama,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      showProductForm(product: product);
                    } else if (value == 'delete') {
                      confirmDelete(product);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit'),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('Hapus'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              product.kategori,
              style: const TextStyle(color: Colors.grey),
            ),
            const Divider(height: 24),
            Wrap(
              spacing: 24,
              runSpacing: 12,
              children: [
                Text('Harga: ${formatRupiah(product.harga)}'),
                Text('Stok: ${product.stok} ${product.satuan}'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  lowStock ? Icons.warning_amber : Icons.check_circle,
                  size: 18,
                  color: lowStock ? Colors.red : Colors.green,
                ),
                const SizedBox(width: 6),
                Text(
                  lowStock ? 'Stok Menipis' : 'Stok Aman',
                  style: TextStyle(
                    color: lowStock ? Colors.red : Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  'Minimum: ${product.stokMinimum}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        title: const Text(
          'Data Barang',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        onPressed: () => showProductForm(),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Barang'),
      ),
      body: StreamBuilder<List<ProductModel>>(
        stream: productService.getProducts(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Gagal mengambil data barang:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final products = snapshot.data ?? [];

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Daftar Barang',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: navy,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Total ${products.length} barang terdaftar',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: products.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 65,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Belum ada data barang',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Tekan Tambah Barang untuk memulai.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: products.length,
                          itemBuilder: (context, index) {
                            return buildProductCard(products[index]);
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
