import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaksi.dart';
import '../models/user.dart';
import '../services/transaksi_service.dart';
import '../services/user_service.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  final String userId;

  const HomePage({super.key, required this.userId});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Transaksi> listTransaksi = [];
  bool _isLoading = true;
  User? _currentUser;

  // Form Controllers
  final _formKey = GlobalKey<FormState>();
  final _judulController = TextEditingController();
  final _nominalController = TextEditingController();
  String _tipeTerpilih = "Pemasukan";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _muatData();
  }

  String get _userId => widget.userId;

  // Fungsi untuk mengambil data dari database
  Future<void> _muatData() async {
    setState(() => _isLoading = true);
    try {
      print("🔍 Sedang mengambil data untuk User ID: $_userId");
      final user = await UserService.getUserById(_userId);
      final data = await TransaksiService.getTransaksiByUser(_userId);

      setState(() {
        _currentUser = user;
        listTransaksi = data;
        _isLoading = false;
      });
      print("✅ Berhasil memuat ${listTransaksi.length} transaksi.");
    } catch (e) {
      print("❌ Error saat muat data: $e");
      setState(() => _isLoading = false);
    }
  }

  double get totalSaldo {
    double total = 0;
    for (var t in listTransaksi) {
      total += (t.tipe == "Pemasukan") ? t.nominal : -t.nominal;
    }
    return total;
  }

  // QuickChart API
  String getChartUrl() {
    double pemasukan = 0;
    double pengeluaran = 0;
    for (var t in listTransaksi) {
      if (t.tipe == "Pemasukan")
        pemasukan += t.nominal;
      else
        pengeluaran += t.nominal;
    }
    final config =
        '{"type":"pie","data":{"labels":["Masuk","Keluar"],"datasets":[{"data":[$pemasukan,$pengeluaran],"backgroundColor":["#4CAF50","#F44336"]}]}}';
    return "https://quickchart.io/chart?c=${Uri.encodeComponent(config)}";
  }

  // QR Code API dengan data lengkap
  String getQrUrl(Transaksi t) {
    final fmt = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    String data =
        """TRANSAKSI KEUANGAN
---
Nama: ${_currentUser?.nama ?? 'User'}
Judul: ${t.judul}
Nominal: ${fmt.format(t.nominal)}
Tipe: ${t.tipe}
Kategori: ${t.kategori}
Tanggal: ${dateFormat.format(t.tanggal)}
ID: ${t.id?.toHexString() ?? 'N/A'}""";

    return "https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=${Uri.encodeComponent(data)}";
  }

  void _konfirmasiHapus(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus Transaksi"),
        content: const Text("Yakin ingin menghapus data ini?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () async {
              await TransaksiService.deleteTransaksi(id);
              await _muatData(); // Refresh data
              Navigator.pop(ctx);
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _editTransaksi(Transaksi transaksi) {
    final editJudulController = TextEditingController(text: transaksi.judul);
    final editNominalController = TextEditingController(
      text: transaksi.nominal.toString(),
    );
    String editTipeTerpilih = transaksi.tipe;
    final editFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Edit Transaksi"),
        content: Form(
          key: editFormKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: editJudulController,
                  decoration: const InputDecoration(
                    labelText: "Judul Transaksi",
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v!.isEmpty ? "Isi judul" : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: editNominalController,
                  decoration: const InputDecoration(
                    labelText: "Nominal",
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) => v!.isEmpty ? "Isi nominal" : null,
                ),
                const SizedBox(height: 12),
                StatefulBuilder(
                  builder: (ctx, setStateEdit) =>
                      DropdownButtonFormField<String>(
                        value: editTipeTerpilih,
                        decoration: const InputDecoration(
                          labelText: "Jenis Transaksi",
                          border: OutlineInputBorder(),
                        ),
                        items: ["Pemasukan", "Pengeluaran"]
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setStateEdit(() => editTipeTerpilih = v!),
                      ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () async {
              if (editFormKey.currentState!.validate()) {
                final res = await TransaksiService.updateTransaksi(
                  id: transaksi.id!.toHexString(),
                  tipe: editTipeTerpilih,
                  nominal: double.parse(editNominalController.text),
                  judul: editJudulController.text,
                  kategori: transaksi.kategori,
                );

                if (res['success']) {
                  await _muatData();
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Transaksi berhasil diperbarui!"),
                    ),
                  );
                }
              }
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("Pencatatan Keuangan"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Beranda"),
            Tab(text: "Input"),
            Tab(text: "Profil"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // --- TAB BERANDA ---
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _muatData,
                  child: Column(
                    children: [
                      if (listTransaksi.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: SizedBox(
                            height: 150,
                            child: Image.network(getChartUrl()),
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.all(15),
                        width: double.infinity,
                        color: totalSaldo < 0
                            ? Colors.redAccent
                            : Colors.blueAccent,
                        child: Center(
                          child: Text(
                            "Total Saldo: ${fmt.format(totalSaldo)}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: listTransaksi.isEmpty
                            ? const Center(
                                child: Text("Belum ada riwayat transaksi."),
                              )
                            : ListView.builder(
                                itemCount: listTransaksi.length,
                                itemBuilder: (ctx, i) {
                                  final t = listTransaksi[i];
                                  return ListTile(
                                    leading: Icon(
                                      t.tipe == "Pemasukan"
                                          ? Icons.add_circle
                                          : Icons.remove_circle,
                                      color: t.tipe == "Pemasukan"
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                    title: Text(t.judul),
                                    subtitle: Text(
                                      DateFormat(
                                        'dd/MM/yyyy',
                                      ).format(t.tanggal),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(fmt.format(t.nominal)),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.qr_code,
                                            size: 20,
                                          ),
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (_) => AlertDialog(
                                                content: Image.network(
                                                  getQrUrl(t),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit,
                                            color: Colors.blue,
                                          ),
                                          onPressed: () => _editTransaksi(t),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: Colors.red,
                                          ),
                                          onPressed: () => _konfirmasiHapus(
                                            t.id!.toHexString(),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),

          // --- TAB INPUT ---
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _judulController,
                    decoration: const InputDecoration(
                      labelText: "Judul Transaksi",
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v!.isEmpty ? "Isi judul" : null,
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _nominalController,
                    decoration: const InputDecoration(
                      labelText: "Nominal",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? "Isi nominal" : null,
                  ),
                  const SizedBox(height: 15),
                  // Dropdown Tipe Transaksi
                  DropdownButtonFormField<String>(
                    value: _tipeTerpilih,
                    decoration: const InputDecoration(
                      labelText: "Jenis Transaksi",
                      border: OutlineInputBorder(),
                    ),
                    items: ["Pemasukan", "Pengeluaran"]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setState(() => _tipeTerpilih = v!),
                  ),
                  const SizedBox(height: 25),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          final res = await TransaksiService.tambahTransaksi(
                            userId: _userId,
                            tipe: _tipeTerpilih,
                            nominal: double.parse(_nominalController.text),
                            judul: _judulController.text,
                            kategori: "Umum",
                          );

                          if (res['success']) {
                            _judulController.clear();
                            _nominalController.clear();
                            await _muatData(); // Update riwayat
                            _tabController.animateTo(
                              0,
                            ); // Pindah ke tab beranda
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Data berhasil disimpan!"),
                              ),
                            );
                          }
                        }
                      },
                      child: const Text("Simpan Transaksi"),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- TAB PROFILE ---
          ProfilePage(userId: _userId),
        ],
      ),
    );
  }
}
