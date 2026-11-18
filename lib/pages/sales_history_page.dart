
import 'package:flutter/material.dart';

import '../models/sale_model.dart';
import '../services/sale_service.dart';

class SalesHistoryPage extends StatefulWidget {
  final String storeId;

  const SalesHistoryPage({
    super.key,
    required this.storeId,
  });

  @override
  State<SalesHistoryPage> createState() =>
      _SalesHistoryPageState();
}

class _SalesHistoryPageState extends State<SalesHistoryPage> {
  late final SaleService saleService;

  @override
  void initState() {
    super.initState();

    saleService = SaleService(
      storeId: widget.storeId,
    );
  }

  String formatRupiah(int angka) {
    final value = angka.toString();
    final buffer = StringBuffer();
    int count = 0;

    for (int i = value.length - 1; i >= 0; i--) {
      buffer.write(value[i]);
      count++;

      if (count == 3 && i != 0) {
        buffer.write('.');
        count = 0;
      }
    }

    return 'Rp ${buffer.toString().split('').reversed.join()}';
  }

  String formatTanggal(int waktuMillis, String tanggal) {
    if (waktuMillis <= 0) {
      return tanggal.isEmpty ? '-' : tanggal;
    }

    final date = DateTime.fromMillisecondsSinceEpoch(
      waktuMillis,
    );

    final hari = date.day.toString().padLeft(2, '0');
    final bulan = date.month.toString().padLeft(2, '0');
    final tahun = date.year;

    final jam = date.hour.toString().padLeft(2, '0');
    final menit = date.minute.toString().padLeft(2, '0');

    return '$hari/$bulan/$tahun • $jam:$menit';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Riwayat Penjualan',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF172B4D),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Daftar transaksi penjualan barang',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),

              Expanded(
                child: StreamBuilder<List<SaleModel>>(
                  stream: saleService.getSales(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text(
                          'Gagal mengambil data riwayat penjualan.',
                        ),
                      );
                    }

                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    final sales = snapshot.data ?? [];

                    if (sales.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 65,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Belum ada transaksi penjualan',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'Transaksi yang dilakukan kasir akan muncul di sini.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final totalTransaksi = sales.length;

                    final totalPendapatan = sales.fold<int>(
                      0,
                      (total, sale) => total + sale.subtotal,
                    );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _summaryCard(
                                'Total Transaksi',
                                totalTransaksi.toString(),
                                Icons.receipt_long,
                                Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _summaryCard(
                                'Total Penjualan',
                                formatRupiah(totalPendapatan),
                                Icons.payments_outlined,
                                Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        const Text(
                          'Daftar Transaksi',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF172B4D),
                          ),
                        ),
                        const SizedBox(height: 10),

                        Expanded(
                          child: ListView.builder(
                            itemCount: sales.length,
                            itemBuilder: (context, index) {
                              final sale = sales[index];

                              return Card(
                                margin: const EdgeInsets.only(
                                  bottom: 12,
                                ),
                                elevation: 1,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(15),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.shopping_bag_outlined,
                                            color: Color(0xFF172B4D),
                                            size: 22,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              sale.namaBarang,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight:
                                                    FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            formatRupiah(
                                              sale.subtotal,
                                            ),
                                            style: const TextStyle(
                                              color: Colors.green,
                                              fontWeight:
                                                  FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 22),

                                      _detailRow(
                                        'Harga satuan',
                                        formatRupiah(sale.harga),
                                      ),
                                      const SizedBox(height: 7),

                                      _detailRow(
                                        'Jumlah terjual',
                                        '${sale.jumlah} barang',
                                      ),
                                      const SizedBox(height: 7),

                                      _detailRow(
                                        'Kasir',
                                        sale.kasirEmail,
                                      ),
                                      const SizedBox(height: 7),

                                      _detailRow(
                                        'Tanggal',
                                        formatTanggal(
                                          sale.waktuMillis,
                                          sale.tanggal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 25),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF172B4D),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 115,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ),
        const Text(': '),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
