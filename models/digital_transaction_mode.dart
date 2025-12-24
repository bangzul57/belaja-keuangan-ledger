/// Enum untuk mode transaksi digital
/// Menentukan bagaimana biaya admin ditangani
enum DigitalTransactionMode {
  /// Pembeli beli saldo: Admin ditambahkan ke harga
  /// Contoh: Saldo 50.000 + Admin 2.500 = Pembeli bayar 52.500
  buyBalance('buy_balance', 'Pembeli Beli Saldo'),

  /// Pembeli jual saldo dengan potongan: Admin dipotong dari nominal
  /// Contoh: Saldo 100.000 - Admin 3.000 = Pembeli terima 97.000
  sellBalanceDeduct('sell_balance_deduct', 'Jual Saldo (Potong Saldo)'),

  /// Pembeli jual saldo dengan admin tunai: Pembeli bayar admin terpisah
  /// Contoh: Saldo 100.000, Pembeli bayar admin tunai 3.000
  sellBalanceCash('sell_balance_cash', 'Jual Saldo (Admin Tunai)'),

  /// Top up saldo e-wallet/bank dari kas
  topUp('top_up', 'Top Up Saldo'),

  /// Transfer antar akun (dengan potensi biaya admin)
  transfer('transfer', 'Transfer'),

  /// Pembayaran menggunakan e-wallet/m-banking
  payment('payment', 'Pembayaran');

  final String value;
  final String label;

  const DigitalTransactionMode(this.value, this.label);

  /// Convert dari string value
  static DigitalTransactionMode fromValue(String value) {
    return DigitalTransactionMode.values.firstWhere(
      (e) => e.value == value,
      orElse: () => DigitalTransactionMode.buyBalance,
    );
  }

  /// Cek apakah mode ini adalah penjualan saldo (owner menerima saldo)
  bool get isSellMode {
    return this == DigitalTransactionMode.sellBalanceDeduct ||
        this == DigitalTransactionMode.sellBalanceCash;
  }

  /// Cek apakah mode ini adalah pembelian saldo (owner mengeluarkan saldo)
  bool get isBuyMode {
    return this == DigitalTransactionMode.buyBalance;
  }

  /// Cek apakah mode ini memerlukan akun kas
  bool get requiresCashAccount {
    return this == DigitalTransactionMode.buyBalance ||
        this == DigitalTransactionMode.sellBalanceDeduct ||
        this == DigitalTransactionMode.sellBalanceCash;
  }

  /// Cek apakah admin dibayar tunai terpisah
  bool get hasSeprateAdminPayment {
    return this == DigitalTransactionMode.sellBalanceCash;
  }

  /// Mendapatkan deskripsi detail mode
  String get description {
    switch (this) {
      case DigitalTransactionMode.buyBalance:
        return 'Pembeli membeli saldo dari owner. '
            'Owner mengeluarkan saldo digital dan menerima uang tunai + admin.';
      case DigitalTransactionMode.sellBalanceDeduct:
        return 'Pembeli menjual saldo ke owner dengan potongan admin. '
            'Owner menerima saldo digital dan membayar tunai dikurangi admin.';
      case DigitalTransactionMode.sellBalanceCash:
        return 'Pembeli menjual saldo ke owner. '
            'Admin dibayar tunai terpisah oleh pembeli.';
      case DigitalTransactionMode.topUp:
        return 'Owner mengisi saldo digital dari kas. '
            'Mungkin ada biaya admin dari provider.';
      case DigitalTransactionMode.transfer:
        return 'Transfer saldo antar akun. '
            'Bisa dikenakan biaya admin transfer.';
      case DigitalTransactionMode.payment:
        return 'Pembayaran menggunakan e-wallet atau m-banking.';
    }
  }

  /// Mendapatkan icon untuk mode ini
  String get iconName {
    switch (this) {
      case DigitalTransactionMode.buyBalance:
        return 'shopping_cart';
      case DigitalTransactionMode.sellBalanceDeduct:
      case DigitalTransactionMode.sellBalanceCash:
        return 'sell';
      case DigitalTransactionMode.topUp:
        return 'add_card';
      case DigitalTransactionMode.transfer:
        return 'swap_horiz';
      case DigitalTransactionMode.payment:
        return 'payment';
    }
  }
}

/// Extension untuk kemudahan penggunaan
extension DigitalTransactionModeList on List<DigitalTransactionMode> {
  /// Filter mode yang tersedia untuk transaksi dengan pembeli
  List<DigitalTransactionMode> get buyerModes {
    return where((mode) =>
        mode == DigitalTransactionMode.buyBalance ||
        mode == DigitalTransactionMode.sellBalanceDeduct ||
        mode == DigitalTransactionMode.sellBalanceCash).toList();
  }

  /// Filter mode yang tersedia untuk transaksi internal
  List<DigitalTransactionMode> get internalModes {
    return where((mode) =>
        mode == DigitalTransactionMode.topUp ||
        mode == DigitalTransactionMode.transfer).toList();
  }
}
