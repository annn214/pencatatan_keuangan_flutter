import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import 'package:uas_pencatatan_keuangan/models/transaksi.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Transaksi> listTransaksi = []; // Data dummy pengganti ViewModel

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  double get totalSaldo {
    double total = 0;
    for (var t in listTransaksi) {
      total += (t.tipe == "Pemasukan") ? t.nominal : -t.nominal;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: Text("Pencatatan Keuangan"),
        bottom: TabBar(
          controller: _tabController,
          tabs: [Tab(text: "Beranda"), Tab(text: "Input")],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB BERANDA
          Column(
            children: [
              Container(
                padding: EdgeInsets.all(20),
                color: totalSaldo < 0 ? Colors.red : Colors.blue,
                child: Center(
                  child: Text(
                    "Total Saldo: ${currencyFormat.format(totalSaldo)}",
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: listTransaksi.length,
                  itemBuilder: (context, index) {
                    final item = listTransaksi[index];
                    return ListTile(
                      leading: Icon(item.tipe == "Pemasukan" ? Icons.add_circle : Icons.remove_circle, 
                                   color: item.tipe == "Pemasukan" ? Colors.green : Colors.red),
                      title: Text(item.judul),
                      subtitle: Text(item.tanggal),
                      trailing: Text(currencyFormat.format(item.nominal)),
                    );
                  },
                ),
              ),
            ],
          ),
          // TAB INPUT
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("Halaman Input (Gunakan Form Field di sini)"),
          ),
        ],
      ),
    );
  }
}