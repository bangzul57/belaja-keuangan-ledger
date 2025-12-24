/// Konstanta string untuk aplikasi
/// Memudahkan lokalisasi di masa depan
class AppStrings {
  AppStrings._(); // Private constructor

  // ===== APP INFO =====
  static const String appName = 'Ledger Keuangan';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Aplikasi pencatatan keuangan dengan sistem double-entry ledger';

  // ===== COMMON =====
  static const String save = 'Simpan';
  static const String cancel = 'Batal';
  static const String delete = 'Hapus';
  static const String edit = 'Edit';
  static const String add = 'Tambah';
  static const String close = 'Tutup';
  static const String confirm = 'Konfirmasi';
  static const String yes = 'Ya';
  static const String no = 'Tidak';
  static const String ok = 'OK';
  static const String loading = 'Memuat...';
  static const String search = 'Cari...';
  static const String noData = 'Tidak ada data';
  static const String retry = 'Coba Lagi';
  static const String success = 'Berhasil';
  static const String failed = 'Gagal';

  // ===== NAVIGATION =====
  static const String dashboard = 'Dashboard';
  static const String digitalTransaction = 'Transaksi Digital';
  static const String retailTransaction = 'Transaksi Ritel';
  static const String receivable = 'Piutang';
  static const String transfer = 'Transfer';
  static const String prive = 'Prive';
  static const String ledger = 'Buku Besar';
  static const String settings = 'Pengaturan';
  static const String inventory = 'Inventaris';
  static const String reports = 'Laporan';

  // ===== ACCOUNTS =====
  static const String accounts = 'Akun';
  static const String addAccount = 'Tambah Akun';
  static const String editAccount = 'Edit Akun';
  static const String accountName = 'Nama Akun';
  static const String accountType = 'Tipe Akun';
  static const String accountBalance = 'Saldo';
  static const String initialBalance = 'Saldo Awal';
  static const String currentBalance = 'Saldo Saat Ini';
  
  static const String cashAccount = 'Kas';
  static const String digitalAccount = 'E-Wallet';
  static const String bankAccount = 'Bank';
  static const String receivableAccount = 'Piutang';

  // ===== TRANSACTIONS =====
  static const String transaction = 'Transaksi';
  static const String transactions = 'Transaksi';
  static const String addTransaction = 'Tambah Transaksi';
  static const String transactionDate = 'Tanggal Transaksi';
  static const String transactionType = 'Tipe Transaksi';
  static const String amount = 'Nominal';
  static const String description = 'Keterangan';
  static const String notes = 'Catatan';
  
  static const String income = 'Pemasukan';
  static const String expense = 'Pengeluaran';
  static const String buyBalance = 'Beli Saldo';
  static const String sellBalance = 'Jual Saldo';
  static const String topUp = 'Top Up';

  // ===== DIGITAL SPECIFIC =====
  static const String digitalSell = 'Pembeli Beli Saldo';
  static const String digitalBuy = 'Pembeli Jual Saldo';
  static const String adminFee = 'Biaya Admin';
  static const String adminCash = 'Admin Tunai';
  static const String deductBalance = 'Potong Saldo';
  static const String selectWallet = 'Pilih E-Wallet';
  static const String profit = 'Keuntungan';

  // ===== RETAIL SPECIFIC =====
  static const String item = 'Barang';
  static const String items = 'Barang';
  static const String stock = 'Stok';
  static const String buyPrice = 'Harga Beli';
  static const String sellPrice = 'Harga Jual';
  static const String quantity = 'Jumlah';
  static const String unit = 'Satuan';
  static const String lowStock = 'Stok Menipis';

  // ===== RECEIVABLE SPECIFIC =====
  static const String buyerName = 'Nama Pembeli';
  static const String dueDate = 'Jatuh Tempo';
  static const String remainingAmount = 'Sisa Hutang';
  static const String paidAmount = 'Sudah Dibayar';
  static const String receivePayment = 'Terima Pembayaran';
  static const String paymentHistory = 'Riwayat Pembayaran';
  static const String overdue = 'Jatuh Tempo Lewat';

  // ===== TRANSFER =====
  static const String fromAccount = 'Dari Akun';
  static const String toAccount = 'Ke Akun';
  static const String transferAmount = 'Nominal Transfer';
  static const String transferFee = 'Biaya Transfer';

  // ===== PRIVE =====
  static const String priveDescription = 'Penarikan untuk keperluan pribadi owner';
  static const String priveAmount = 'Nominal Penarikan';

  // ===== LEDGER =====
  static const String journalEntry = 'Jurnal';
  static const String debit = 'Debit';
  static const String credit = 'Kredit';
  static const String balanceBefore = 'Saldo Sebelum';
  static const String balanceAfter = 'Saldo Sesudah';

  // ===== SETTINGS =====
  static const String darkMode = 'Mode Gelap';
  static const String digitalMode = 'Mode Digital';
  static const String retailMode = 'Mode Ritel';
  static const String hybridMode = 'Mode Hybrid';
  static const String backup = 'Backup Data';
  static const String restore = 'Restore Data';
  static const String exportData = 'Ekspor Data';
  static const String importData = 'Impor Data';
  static const String defaultAdminFee = 'Biaya Admin Default';
  static const String defaultAdminPercentage = 'Persentase Admin Default';

  // ===== VALIDATION MESSAGES =====
  static const String fieldRequired = 'Field ini wajib diisi';
  static const String invalidAmount = 'Nominal tidak valid';
  static const String amountMustBePositive = 'Nominal harus lebih dari 0';
  static const String insufficientBalance = 'Saldo tidak mencukupi';
  static const String insufficientStock = 'Stok tidak mencukupi';
  static const String selectAccount = 'Pilih akun terlebih dahulu';
  static const String selectItem = 'Pilih barang terlebih dahulu';
  static const String sameAccountError = 'Akun asal dan tujuan tidak boleh sama';

  // ===== SUCCESS MESSAGES =====
  static const String transactionSaved = 'Transaksi berhasil disimpan';
  static const String accountSaved = 'Akun berhasil disimpan';
  static const String itemSaved = 'Barang berhasil disimpan';
  static const String dataSaved = 'Data berhasil disimpan';
  static const String dataDeleted = 'Data berhasil dihapus';
  static const String backupSuccess = 'Backup berhasil';
  static const String restoreSuccess = 'Restore berhasil';

  // ===== ERROR MESSAGES =====
  static const String errorOccurred = 'Terjadi kesalahan';
  static const String errorSaving = 'Gagal menyimpan data';
  static const String errorLoading = 'Gagal memuat data';
  static const String errorDeleting = 'Gagal menghapus data';
  static const String errorNetwork = 'Kesalahan jaringan';

  // ===== CONFIRM DIALOGS =====
  static const String confirmDelete = 'Yakin ingin menghapus?';
  static const String confirmDeleteDescription = 'Data yang dihapus tidak dapat dikembalikan.';
  static const String confirmCancel = 'Yakin ingin membatalkan?';
  static const String confirmCancelDescription = 'Perubahan yang belum disimpan akan hilang.';
  static const String confirmTransaction = 'Konfirmasi Transaksi';

  // ===== QUICK CALC =====
  static const String quickCalc = 'Hitung Kembalian';
  static const String moneyReceived = 'Uang Diterima';
  static const String change = 'Kembalian';
  static const String enableQuickCalc = 'Aktifkan Hitung Kembalian';

  // ===== EMPTY STATES =====
  static const String noTransactions = 'Belum ada transaksi';
  static const String noAccounts = 'Belum ada akun';
  static const String noItems = 'Belum ada barang';
  static const String noReceivables = 'Tidak ada piutang';
  static const String startAddingData = 'Mulai tambahkan data';

  // ===== DATE FORMATS =====
  static const String today = 'Hari Ini';
  static const String yesterday = 'Kemarin';
  static const String thisWeek = 'Minggu Ini';
  static const String thisMonth = 'Bulan Ini';
  static const String allTime = 'Semua Waktu';
}
