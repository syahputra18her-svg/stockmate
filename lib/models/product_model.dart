
class ProductModel {
  final String id;
  final String nama;
  final String kategori;
  final int harga;
  final int stok;
  final String satuan;
  final int stokMinimum;

  ProductModel({
    required this.id,
    required this.nama,
    required this.kategori,
    required this.harga,
    required this.stok,
    required this.satuan,
    required this.stokMinimum,
  });

  // Mengubah data barang menjadi format Map untuk Firebase.
  Map<String, dynamic> toMap() {
    return {
      'nama': nama,
      'kategori': kategori,
      'harga': harga,
      'stok': stok,
      'satuan': satuan,
      'stokMinimum': stokMinimum,
    };
  }

  // Mengambil data dari Firebase dan mengubahnya menjadi ProductModel.
  factory ProductModel.fromMap(
    String id,
    Map<dynamic, dynamic> map,
  ) {
    return ProductModel(
      id: id,
      nama: map['nama']?.toString() ?? '',
      kategori: map['kategori']?.toString() ?? '',
      harga: (map['harga'] as num?)?.toInt() ?? 0,
      stok: (map['stok'] as num?)?.toInt() ?? 0,
      satuan: map['satuan']?.toString() ?? '',
      stokMinimum: (map['stokMinimum'] as num?)?.toInt() ?? 0,
    );
  }
}
