import 'package:flutter/material.dart';

/// Konstanta warna untuk aplikasi
/// Menggunakan sistem warna yang konsisten dengan Material Design 3
class AppColors {
  AppColors._(); // Private constructor untuk mencegah instansiasi

  // ===== PRIMARY COLORS =====
  static const Color primary = Color(0xFF1E88E5);
  static const Color primaryLight = Color(0xFF64B5F6);
  static const Color primaryDark = Color(0xFF1565C0);
  static const Color onPrimary = Colors.white;

  // ===== SECONDARY COLORS =====
  static const Color secondary = Color(0xFF26A69A);
  static const Color secondaryLight = Color(0xFF80CBC4);
  static const Color secondaryDark = Color(0xFF00897B);
  static const Color onSecondary = Colors.white;

  // ===== SEMANTIC COLORS =====
  static const Color success = Color(0xFF4CAF50);
  static const Color successLight = Color(0xFFC8E6C9);
  static const Color onSuccess = Colors.white;

  static const Color warning = Color(0xFFFFA726);
  static const Color warningLight = Color(0xFFFFE0B2);
  static const Color onWarning = Colors.black87;

  static const Color error = Color(0xFFE53935);
  static const Color errorLight = Color(0xFFFFCDD2);
  static const Color onError = Colors.white;

  static const Color info = Color(0xFF29B6F6);
  static const Color infoLight = Color(0xFFB3E5FC);
  static const Color onInfo = Colors.white;

  // ===== NEUTRAL COLORS =====
  static const Color background = Color(0xFFFAFAFA);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surface = Colors.white;
  static const Color surfaceDark = Color(0xFF1E1E1E);

  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);
  static const Color textDisabled = Color(0xFF9E9E9E);

  static const Color divider = Color(0xFFE0E0E0);
  static const Color dividerDark = Color(0xFF424242);

  // ===== TRANSACTION COLORS =====
  static const Color income = Color(0xFF4CAF50); // Hijau untuk pemasukan
  static const Color expense = Color(0xFFE53935); // Merah untuk pengeluaran
  static const Color transfer = Color(0xFF1E88E5); // Biru untuk transfer
  static const Color receivable = Color(0xFFFFA726); // Orange untuk piutang

  // ===== ACCOUNT TYPE COLORS =====
  static const Color cashAccount = Color(0xFF66BB6A);
  static const Color digitalAccount = Color(0xFF42A5F5);
  static const Color bankAccount = Color(0xFF7E57C2);
  static const Color receivableAccount = Color(0xFFFFCA28);

  // ===== CHART COLORS =====
  static const List<Color> chartColors = [
    Color(0xFF1E88E5),
    Color(0xFF26A69A),
    Color(0xFFFFA726),
    Color(0xFFEF5350),
    Color(0xFF7E57C2),
    Color(0xFF66BB6A),
    Color(0xFFEC407A),
    Color(0xFF5C6BC0),
  ];

  // ===== GRADIENT =====
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [success, Color(0xFF388E3C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ===== HELPER METHODS =====
  
  /// Mendapatkan warna berdasarkan tipe akun
  static Color getAccountTypeColor(String accountType) {
    switch (accountType.toLowerCase()) {
      case 'cash':
      case 'kas':
        return cashAccount;
      case 'digital':
      case 'e-wallet':
        return digitalAccount;
      case 'bank':
        return bankAccount;
      case 'receivable':
      case 'piutang':
        return receivableAccount;
      default:
        return primary;
    }
  }

  /// Mendapatkan warna berdasarkan tipe transaksi
  static Color getTransactionTypeColor(String transactionType) {
    switch (transactionType.toLowerCase()) {
      case 'income':
      case 'pemasukan':
        return income;
      case 'expense':
      case 'pengeluaran':
        return expense;
      case 'transfer':
        return transfer;
      case 'receivable':
      case 'piutang':
        return receivable;
      default:
        return textSecondary;
    }
  }
}
