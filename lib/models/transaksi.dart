class Transaksi {
  int? id;
  String judul;
  double nominal;
  String tanggal;
  String tipe; // "Pemasukan" atau "Pengeluaran"

  Transaksi({
    this.id,
    required this.judul,
    required this.nominal,
    required this.tanggal,
    required this.tipe,
  });

  // Untuk konversi dari Map (SQLite/API) ke Object
  factory Transaksi.fromMap(Map<String, dynamic> map) {
    return Transaksi(
      id: map['id'],
      judul: map['judul'],
      nominal: map['nominal'],
      tanggal: map['tanggal'],
      tipe: map['tipe'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'judul': judul,
      'nominal': nominal,
      'tanggal': tanggal,
      'tipe': tipe,
    };
  }
}