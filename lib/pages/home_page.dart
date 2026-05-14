import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/transaksi.dart';
import '../models/user.dart';
import '../services/transaksi_service.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';
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

  final _formKey = GlobalKey<FormState>();
  final _judulController = TextEditingController();
  final _nominalController = TextEditingController();
  String _tipeTerpilih = 'Pemasukan';

  final fmt = NumberFormat.currency(
    locale: 'id',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  final _inputNominalFormat = NumberFormat('#,###', 'id');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _muatData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _judulController.dispose();
    _nominalController.dispose();
    super.dispose();
  }

  String get _userId => widget.userId;

  Future<void> _muatData() async {
    setState(() => _isLoading = true);
    try {
      final user = await UserService.getUserById(_userId);
      final data = await TransaksiService.getTransaksiByUser(_userId);
      setState(() {
        _currentUser = user;
        listTransaksi = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  double get totalSaldo {
    return listTransaksi.fold(
      0,
      (sum, t) => sum + (t.tipe == 'Pemasukan' ? t.nominal : -t.nominal),
    );
  }

  double get totalPemasukan => listTransaksi
      .where((t) => t.tipe == 'Pemasukan')
      .fold(0, (s, t) => s + t.nominal);

  double get totalPengeluaran => listTransaksi
      .where((t) => t.tipe == 'Pengeluaran')
      .fold(0, (s, t) => s + t.nominal);

  String getChartUrl() {
    final config =
        '{"type":"doughnut","data":{"labels":["Pemasukan","Pengeluaran"],"datasets":[{"data":[$totalPemasukan,$totalPengeluaran],"backgroundColor":["#00C896","#FF5C6A"],"borderWidth":0}]},"options":{"plugins":{"legend":{"display":false}},"cutout":"70%"}}';
    return 'https://quickchart.io/chart?c=${Uri.encodeComponent(config)}&backgroundColor=transparent&width=200&height=200';
  }

  // ✅ PERBAIKAN: warna benar (hitam di putih), data ringkas, ukuran lebih besar
  String getQrUrl(Transaksi t) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final data =
        'Nama: ${_currentUser?.nama ?? 'User'} | '
        'Judul: ${t.judul} | '
        'Nominal: ${fmt.format(t.nominal)} | '
        'Tipe: ${t.tipe} | '
        'Tanggal: ${dateFormat.format(t.tanggal)} | '
        'ID: ${t.id?.toHexString() ?? 'N/A'}';
    return 'https://api.qrserver.com/v1/create-qr-code/?size=300x300'
        '&data=${Uri.encodeComponent(data)}'
        '&bgcolor=ffffff'   // latar putih
        '&color=000000'     // modul hitam
        '&margin=10';       // margin agar mudah di-scan
  }

  String _formatNominalInput(String value) {
    final digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) return '';
    return _inputNominalFormat.format(int.parse(digitsOnly));
  }

  double _parseNominalInput(String value) {
    final digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) return 0;
    return double.parse(digitsOnly);
  }

  void _konfirmasiHapus(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Transaksi'),
        content: const Text(
          'Data ini akan dihapus permanen. Yakin ingin melanjutkan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.textSecondary,
            ),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              await TransaksiService.deleteTransaksi(id);
              await _muatData();
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
            child: const Text(
              'Hapus',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _editTransaksi(Transaksi transaksi) {
    final editJudulController = TextEditingController(text: transaksi.judul);
    final editNominalController = TextEditingController(
      text: _formatNominalInput(transaksi.nominal.toStringAsFixed(0)),
    );
    String editTipe = transaksi.tipe;
    final editFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Transaksi'),
        content: Form(
          key: editFormKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: editJudulController,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Judul Transaksi',
                  ),
                  validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: editNominalController,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(labelText: 'Nominal'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    _ThousandsSeparatorInputFormatter(),
                  ],
                  validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                StatefulBuilder(
                  builder: (ctx, setStateEdit) =>
                      DropdownButtonFormField<String>(
                        initialValue: editTipe,
                        dropdownColor: AppTheme.surfaceElevated,
                        style: const TextStyle(color: AppTheme.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Jenis Transaksi',
                        ),
                        items: ['Pemasukan', 'Pengeluaran']
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                        onChanged: (v) => setStateEdit(() => editTipe = v!),
                      ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.textSecondary,
            ),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              if (editFormKey.currentState!.validate()) {
                final res = await TransaksiService.updateTransaksi(
                  id: transaksi.id!.toHexString(),
                  tipe: editTipe,
                  nominal: _parseNominalInput(editNominalController.text),
                  judul: editJudulController.text,
                  kategori: transaksi.kategori,
                );
                if (res['success']) {
                  await _muatData();
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Transaksi berhasil diperbarui!'),
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.accent),
            child: const Text(
              'Simpan',
              style: TextStyle(fontWeight: FontWeight.w600),
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _currentUser != null
                  ? 'Halo, ${_currentUser!.nama.split(' ').first} 👋'
                  : 'Keuanganku',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppTheme.divider, width: 1),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.home_outlined, size: 20), text: 'Beranda'),
                Tab(
                  icon: Icon(Icons.add_circle_outline_rounded, size: 20),
                  text: 'Input',
                ),
                Tab(
                  icon: Icon(Icons.person_outline_rounded, size: 20),
                  text: 'Profil',
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBerandaTab(),
          _buildInputTab(),
          ProfilePage(userId: _userId),
        ],
      ),
    );
  }

  Widget _buildBerandaTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppTheme.accent,
          strokeWidth: 2.5,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _muatData,
      color: AppTheme.accent,
      backgroundColor: AppTheme.surfaceElevated,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
        children: [
          _buildSaldoCard(),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Pemasukan',
                  totalPemasukan,
                  AppTheme.accent,
                  Icons.arrow_downward_rounded,
                  const Color(0xFF0D2620),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Pengeluaran',
                  totalPengeluaran,
                  AppTheme.danger,
                  Icons.arrow_upward_rounded,
                  const Color(0xFF2D1218),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (listTransaksi.isNotEmpty) ...[
            _buildChartSection(),
            const SizedBox(height: 24),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Riwayat Transaksi',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${listTransaksi.length} transaksi',
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 14),
          listTransaksi.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: listTransaksi
                      .map((t) => _buildTransaksiCard(t))
                      .toList(),
                ),
        ],
      ),
    );
  }

  Widget _buildSaldoCard() {
    final isPositive = totalSaldo >= 0;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isPositive
              ? [const Color(0xFF0D2620), const Color(0xFF0A1E18)]
              : [const Color(0xFF2D1218), const Color(0xFF1E0B0F)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPositive
              ? AppTheme.accent.withOpacity(0.3)
              : AppTheme.danger.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: (isPositive ? AppTheme.accent : AppTheme.danger)
                      .withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isPositive ? '● Saldo Positif' : '● Saldo Negatif',
                  style: TextStyle(
                    color: isPositive ? AppTheme.accent : AppTheme.danger,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Total Saldo',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            fmt.format(totalSaldo),
            style: TextStyle(
              color: isPositive ? AppTheme.accent : AppTheme.danger,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String label,
    double amount,
    Color color,
    IconData icon,
    Color bg,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            fmt.format(amount),
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Komposisi Keuangan',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 110,
                height: 110,
                child: Image.network(getChartUrl(), fit: BoxFit.contain),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLegendItem('Pemasukan', AppTheme.accent),
                    const SizedBox(height: 12),
                    _buildLegendItem('Pengeluaran', AppTheme.danger),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildTransaksiCard(Transaksi t) {
    final isIn = t.tipe == 'Pemasukan';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: (isIn ? AppTheme.accent : AppTheme.danger).withOpacity(
                0.12,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isIn ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              color: isIn ? AppTheme.accent : AppTheme.danger,
              size: 18,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.judul,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      t.kategori,
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    const Text(
                      ' · ',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                    ),
                    Text(
                      DateFormat('dd MMM yyyy').format(t.tanggal),
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isIn ? '+' : '-'}${fmt.format(t.nominal)}',
                style: TextStyle(
                  color: isIn ? AppTheme.accent : AppTheme.danger,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ✅ PERBAIKAN: Dialog QR dengan latar putih dan ukuran lebih besar
                  _actionIcon(Icons.qr_code_rounded, AppTheme.textMuted, () {
                    showDialog(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        backgroundColor: AppTheme.surface,
                        title: const Text('QR Transaksi'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.all(12),
                              child: Image.network(
                                getQrUrl(t),
                                width: 250,
                                height: 250,
                                fit: BoxFit.contain,
                                loadingBuilder: (context, child, progress) {
                                  if (progress == null) return child;
                                  return const SizedBox(
                                    width: 250,
                                    height: 250,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: AppTheme.accent,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              t.judul,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              fmt.format(t.nominal),
                              style: TextStyle(
                                color: isIn ? AppTheme.accent : AppTheme.danger,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.textSecondary,
                            ),
                            child: const Text('Tutup'),
                          ),
                        ],
                      ),
                    );
                  }),
                  _actionIcon(
                    Icons.edit_outlined,
                    AppTheme.textMuted,
                    () => _editTransaksi(t),
                  ),
                  _actionIcon(
                    Icons.delete_outline_rounded,
                    AppTheme.danger.withOpacity(0.7),
                    () => _konfirmasiHapus(t.id!.toHexString()),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionIcon(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 50),
      alignment: Alignment.center,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              color: AppTheme.textMuted,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Belum Ada Transaksi',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tap tab Input untuk mulai mencatat',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildInputTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tambah Transaksi',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Catat pemasukan atau pengeluaran Anda.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 32),
          const Text(
            'JENIS TRANSAKSI',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTipeButton(
                  'Pemasukan',
                  Icons.arrow_downward_rounded,
                  AppTheme.accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTipeButton(
                  'Pengeluaran',
                  Icons.arrow_upward_rounded,
                  AppTheme.danger,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'JUDUL TRANSAKSI',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _judulController,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'Contoh: Gaji Bulan Ini',
                    prefixIcon: Icon(
                      Icons.title_rounded,
                      color: AppTheme.textMuted,
                      size: 20,
                    ),
                  ),
                  validator: (v) => v!.isEmpty ? 'Judul wajib diisi' : null,
                ),
                const SizedBox(height: 20),
                const Text(
                  'NOMINAL',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _nominalController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    _ThousandsSeparatorInputFormatter(),
                  ],
                  decoration: const InputDecoration(
                    hintText: '0',
                    prefixIcon: Icon(
                      Icons.payments_outlined,
                      color: AppTheme.textMuted,
                      size: 20,
                    ),
                    prefixText: 'Rp  ',
                    prefixStyle: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  validator: (v) => v!.isEmpty ? 'Nominal wajib diisi' : null,
                ),
                const SizedBox(height: 36),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        final res = await TransaksiService.tambahTransaksi(
                          userId: _userId,
                          tipe: _tipeTerpilih,
                          nominal: _parseNominalInput(_nominalController.text),
                          judul: _judulController.text,
                          kategori: 'Umum',
                        );
                        if (res['success']) {
                          _judulController.clear();
                          _nominalController.clear();
                          await _muatData();
                          _tabController.animateTo(0);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Transaksi berhasil disimpan! ✓'),
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _tipeTerpilih == 'Pemasukan'
                          ? AppTheme.accent
                          : AppTheme.danger,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _tipeTerpilih == 'Pemasukan'
                              ? Icons.arrow_downward_rounded
                              : Icons.arrow_upward_rounded,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        const Text('Simpan Transaksi'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipeButton(String tipe, IconData icon, Color color) {
    final isSelected = _tipeTerpilih == tipe;
    return GestureDetector(
      onTap: () => setState(() => _tipeTerpilih = tipe),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.15)
              : AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : AppTheme.cardBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? color : AppTheme.textMuted,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              tipe,
              style: TextStyle(
                color: isSelected ? color : AppTheme.textSecondary,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThousandsSeparatorInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat('#,###', 'id');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) {
      return const TextEditingValue(text: '');
    }

    final formatted = _formatter.format(int.parse(digitsOnly));
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}