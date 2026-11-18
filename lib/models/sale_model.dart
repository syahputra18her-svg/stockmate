
class SaleModel {
  final String id;
  final String productId;
  final String namaBarang;
  final int harga;
  final int jumlah;
  final int subtotal;
  final String tanggal;
  final int waktuMillis;
  final String kasirEmail;

  SaleModel({
    required this.id,
    required this.productId,
    required this.namaBarang,
    required this.harga,
    required this.jumlah,
    required this.subtotal,
    required this.tanggal,
    required this.waktuMillis,
    required this.kasirEmail,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'namaBarang': namaBarang,
      'harga': harga,
      'jumlah': jumlah,
      'subtotal': subtotal,
      'tanggal': tanggal,
      'waktuMillis': waktuMillis,
      'kasirEmail': kasirEmail,
    };
  }

  factory SaleModel.fromMap(
    String id,
    Map<dynamic, dynamic> map,
  ) {
    return SaleModel(
      id: id,
      productId: map['productId']?.toString() ?? '',
      namaBarang: map['namaBarang']?.toString() ?? '',
      harga: (map['harga'] as num?)?.toInt() ?? 0,
      jumlah: (map['jumlah'] as num?)?.toInt() ?? 0,
      subtotal: (map['subtotal'] as num?)?.toInt() ?? 0,
      tanggal: map['tanggal']?.toString() ?? '',
      waktuMillis: (map['waktuMillis'] as num?)?.toInt() ?? 0,
      kasirEmail: map['kasirEmail']?.toString() ?? '',
    );
  }
}
