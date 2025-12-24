import 'package:intl/intl.dart';

/// Utility class untuk formatting data
class Formatters {
  Formatters._();

  // ===== CURRENCY FORMATTERS =====

  static final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static final _currencyFormatWithDecimal = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 2,
  );

  static final _numberFormat = NumberFormat.decimalPattern('id_ID');

  /// Format angka ke format mata uang Indonesia
  /// Contoh: 50000 -> "Rp 50.000"
  static String formatCurrency(num? value) {
    if (value == null) return 'Rp 0';
    return _currencyFormat.format(value);
  }

  /// Format mata uang dengan desimal
  /// Contoh: 50000.50 -> "Rp 50.000,50"
  static String formatCurrencyWithDecimal(num? value) {
    if (value == null) return 'Rp 0,00';
    return _currencyFormatWithDecimal.format(value);
  }

  /// Format angka tanpa simbol mata uang
  /// Contoh: 50000 -> "50.000"
  static String formatNumber(num? value) {
    if (value == null) return '0';
    return _numberFormat.format(value);
  }

  /// Format angka dengan tanda positif/negatif
  /// Contoh: 50000 -> "+Rp 50.000", -50000 -> "-Rp 50.000"
  static String formatCurrencyWithSign(num? value) {
    if (value == null) return 'Rp 0';
    final formatted = _currencyFormat.format(value.abs());
    if (value > 0) return '+$formatted';
    if (value < 0) return '-$formatted';
    return formatted;
  }

  /// Format angka compact (untuk angka besar)
  /// Contoh: 1500000 -> "1,5 Jt"
  static String formatCompact(num? value) {
    if (value == null) return '0';
    if (value.abs() >= 1000000000) {
      return '${(value / 1000000000).toStringAsFixed(1)} M';
    } else if (value.abs() >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)} Jt';
    } else if (value.abs() >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)} Rb';
    }
    return value.toString();
  }

  /// Parse string currency ke double
  /// Contoh: "Rp 50.000" -> 50000.0
  static double parseCurrency(String? value) {
    if (value == null || value.isEmpty) return 0;
    // Remove currency symbol and formatting
    final cleaned = value
        .replaceAll('Rp', '')
        .replaceAll('.', '')
        .replaceAll(',', '.')
        .replaceAll(' ', '')
        .trim();
    return double.tryParse(cleaned) ?? 0;
  }

  // ===== DATE FORMATTERS =====

  static final _dateFormat = DateFormat('dd/MM/yyyy');
  static final _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');
  static final _timeFormat = DateFormat('HH:mm');
  static final _monthYearFormat = DateFormat('MMMM yyyy', 'id_ID');
  static final _dayMonthFormat = DateFormat('dd MMM', 'id_ID');
  static final _fullDateFormat = DateFormat('EEEE, dd MMMM yyyy', 'id_ID');
  static final _isoFormat = DateFormat('yyyy-MM-dd');

  /// Format DateTime ke string tanggal
  /// Contoh: DateTime -> "25/12/2024"
  static String formatDate(DateTime? date) {
    if (date == null) return '-';
    return _dateFormat.format(date);
  }

  /// Format DateTime ke string tanggal dan waktu
  /// Contoh: DateTime -> "25/12/2024 14:30"
  static String formatDateTime(DateTime? date) {
    if (date == null) return '-';
    return _dateTimeFormat.format(date);
  }

  /// Format DateTime ke string waktu saja
  /// Contoh: DateTime -> "14:30"
  static String formatTime(DateTime? date) {
    if (date == null) return '-';
    return _timeFormat.format(date);
  }

  /// Format DateTime ke string bulan dan tahun
  /// Contoh: DateTime -> "Desember 2024"
  static String formatMonthYear(DateTime? date) {
    if (date == null) return '-';
    return _monthYearFormat.format(date);
  }

  /// Format DateTime ke string tanggal lengkap
  /// Contoh: DateTime -> "Rabu, 25 Desember 2024"
  static String formatFullDate(DateTime? date) {
    if (date == null) return '-';
    return _fullDateFormat.format(date);
  }

  /// Format DateTime ke string pendek
  /// Contoh: DateTime -> "25 Des"
  static String formatShortDate(DateTime? date) {
    if (date == null) return '-';
    return _dayMonthFormat.format(date);
  }

  /// Format DateTime ke ISO string untuk database
  static String formatIso(DateTime? date) {
    if (date == null) return '';
    return date.toIso8601String();
  }

  /// Parse string ke DateTime
  static DateTime? parseDate(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      // Try ISO format first
      return DateTime.tryParse(value) ?? _dateFormat.parse(value);
    } catch (_) {
      return null;
    }
  }

  /// Format tanggal relatif (Hari ini, Kemarin, dll)
  static String formatRelativeDate(DateTime? date) {
    if (date == null) return '-';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    final difference = today.difference(dateOnly).inDays;

    if (difference == 0) {
      return 'Hari ini';
    } else if (difference == 1) {
      return 'Kemarin';
    } else if (difference == -1) {
      return 'Besok';
    } else if (difference > 0 && difference <= 7) {
      return '$difference hari lalu';
    } else if (difference < 0 && difference >= -7) {
      return '${-difference} hari lagi';
    } else {
      return formatDate(date);
    }
  }

  /// Format durasi jatuh tempo piutang
  static String formatDueDuration(DateTime? dueDate) {
    if (dueDate == null) return 'Tidak ada jatuh tempo';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final difference = due.difference(today).inDays;

    if (difference < 0) {
      return 'Terlambat ${-difference} hari';
    } else if (difference == 0) {
      return 'Jatuh tempo hari ini';
    } else if (difference == 1) {
      return 'Jatuh tempo besok';
    } else {
      return 'Jatuh tempo $difference hari lagi';
    }
  }

  // ===== TEXT FORMATTERS =====

  /// Capitalize first letter
  static String capitalize(String? text) {
    if (text == null || text.isEmpty) return '';
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  /// Capitalize each word
  static String capitalizeEachWord(String? text) {
    if (text == null || text.isEmpty) return '';
    return text.split(' ').map((word) => capitalize(word)).join(' ');
  }

  /// Truncate text with ellipsis
  static String truncate(String? text, int maxLength) {
    if (text == null || text.isEmpty) return '';
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  /// Format phone number
  static String formatPhoneNumber(String? phone) {
    if (phone == null || phone.isEmpty) return '-';
    // Simple formatting: add dashes
    final cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.length >= 10) {
      return '${cleaned.substring(0, 4)}-${cleaned.substring(4, 8)}-${cleaned.substring(8)}';
    }
    return phone;
  }

  // ===== PERCENTAGE FORMATTERS =====

  /// Format percentage
  /// Contoh: 0.025 -> "2.5%"
  static String formatPercentage(double? value, {int decimals = 1}) {
    if (value == null) return '0%';
    return '${(value * 100).toStringAsFixed(decimals)}%';
  }

  /// Parse percentage string to double
  /// Contoh: "2.5%" -> 0.025
  static double parsePercentage(String? value) {
    if (value == null || value.isEmpty) return 0;
    final cleaned = value.replaceAll('%', '').trim();
    final parsed = double.tryParse(cleaned) ?? 0;
    return parsed / 100;
  }

  // ===== TRANSACTION CODE =====

  /// Generate transaction code
  /// Format: TRX-YYYYMMDD-XXXX
  static String generateTransactionCode([String prefix = 'TRX']) {
    final now = DateTime.now();
    final datePart = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final timePart = '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
    final randomPart = now.millisecond.toString().padLeft(3, '0');
    return '$prefix-$datePart-$timePart$randomPart';
  }
}
