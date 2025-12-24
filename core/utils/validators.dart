/// Utility class untuk validasi input
class Validators {
  Validators._();

  // ===== GENERIC VALIDATORS =====

  /// Validasi field tidak boleh kosong
  static String? required(String? value, [String fieldName = 'Field ini']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName wajib diisi';
    }
    return null;
  }

  /// Validasi panjang minimum
  static String? minLength(String? value, int min, [String fieldName = 'Field ini']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName wajib diisi';
    }
    if (value.trim().length < min) {
      return '$fieldName minimal $min karakter';
    }
    return null;
  }

  /// Validasi panjang maksimum
  static String? maxLength(String? value, int max, [String fieldName = 'Field ini']) {
    if (value != null && value.length > max) {
      return '$fieldName maksimal $max karakter';
    }
    return null;
  }

  // ===== AMOUNT/MONEY VALIDATORS =====

  /// Validasi nominal (harus angka positif)
  static String? amount(String? value, [String fieldName = 'Nominal']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName wajib diisi';
    }

    // Bersihkan format mata uang
    final cleaned = value
        .replaceAll('Rp', '')
        .replaceAll('.', '')
        .replaceAll(',', '.')
        .replaceAll(' ', '')
        .trim();

    final amount = double.tryParse(cleaned);
    if (amount == null) {
      return '$fieldName tidak valid';
    }
    if (amount < 0) {
      return '$fieldName tidak boleh negatif';
    }
    return null;
  }

  /// Validasi nominal harus lebih dari 0
  static String? positiveAmount(String? value, [String fieldName = 'Nominal']) {
    final basicValidation = amount(value, fieldName);
    if (basicValidation != null) return basicValidation;

    final cleaned = value!
        .replaceAll('Rp', '')
        .replaceAll('.', '')
        .replaceAll(',', '.')
        .replaceAll(' ', '')
        .trim();

    final parsedAmount = double.tryParse(cleaned) ?? 0;
    if (parsedAmount <= 0) {
      return '$fieldName harus lebih dari 0';
    }
    return null;
  }

  /// Validasi nominal dengan batas minimum
  static String? minAmount(String? value, double min, [String fieldName = 'Nominal']) {
    final basicValidation = amount(value, fieldName);
    if (basicValidation != null) return basicValidation;

    final cleaned = value!
        .replaceAll('Rp', '')
        .replaceAll('.', '')
        .replaceAll(',', '.')
        .replaceAll(' ', '')
        .trim();

    final parsedAmount = double.tryParse(cleaned) ?? 0;
    if (parsedAmount < min) {
      return '$fieldName minimal Rp ${min.toStringAsFixed(0)}';
    }
    return null;
  }

  /// Validasi nominal dengan batas maksimum
  static String? maxAmount(String? value, double max, [String fieldName = 'Nominal']) {
    final basicValidation = amount(value, fieldName);
    if (basicValidation != null) return basicValidation;

    final cleaned = value!
        .replaceAll('Rp', '')
        .replaceAll('.', '')
        .replaceAll(',', '.')
        .replaceAll(' ', '')
        .trim();

    final parsedAmount = double.tryParse(cleaned) ?? 0;
    if (parsedAmount > max) {
      return '$fieldName maksimal Rp ${max.toStringAsFixed(0)}';
    }
    return null;
  }

  /// Validasi saldo mencukupi
  static String? sufficientBalance(
    String? value,
    double availableBalance, [
    String fieldName = 'Nominal',
  ]) {
    final basicValidation = positiveAmount(value, fieldName);
    if (basicValidation != null) return basicValidation;

    final cleaned = value!
        .replaceAll('Rp', '')
        .replaceAll('.', '')
        .replaceAll(',', '.')
        .replaceAll(' ', '')
        .trim();

    final parsedAmount = double.tryParse(cleaned) ?? 0;
    if (parsedAmount > availableBalance) {
      return 'Saldo tidak mencukupi (tersedia: Rp ${availableBalance.toStringAsFixed(0)})';
    }
    return null;
  }

  // ===== STOCK/QUANTITY VALIDATORS =====

  /// Validasi quantity/jumlah (bilangan bulat positif)
  static String? quantity(String? value, [String fieldName = 'Jumlah']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName wajib diisi';
    }

    final qty = int.tryParse(value.trim());
    if (qty == null) {
      return '$fieldName harus berupa bilangan bulat';
    }
    if (qty < 0) {
      return '$fieldName tidak boleh negatif';
    }
    return null;
  }

  /// Validasi quantity harus lebih dari 0
  static String? positiveQuantity(String? value, [String fieldName = 'Jumlah']) {
    final basicValidation = quantity(value, fieldName);
    if (basicValidation != null) return basicValidation;

    final qty = int.tryParse(value!.trim()) ?? 0;
    if (qty <= 0) {
      return '$fieldName harus lebih dari 0';
    }
    return null;
  }

  /// Validasi stok mencukupi
  static String? sufficientStock(
    String? value,
    int availableStock, [
    String fieldName = 'Jumlah',
  ]) {
    final basicValidation = positiveQuantity(value, fieldName);
    if (basicValidation != null) return basicValidation;

    final qty = int.tryParse(value!.trim()) ?? 0;
    if (qty > availableStock) {
      return 'Stok tidak mencukupi (tersedia: $availableStock)';
    }
    return null;
  }

  // ===== SELECTION VALIDATORS =====

  /// Validasi dropdown/selection tidak boleh null
  static String? selection<T>(T? value, [String fieldName = 'Pilihan']) {
    if (value == null) {
      return 'Silakan pilih $fieldName';
    }
    return null;
  }

  /// Validasi akun asal dan tujuan tidak boleh sama
  static String? differentAccounts(int? sourceId, int? destId) {
    if (sourceId != null && destId != null && sourceId == destId) {
      return 'Akun asal dan tujuan tidak boleh sama';
    }
    return null;
  }

  // ===== DATE VALIDATORS =====

  /// Validasi tanggal tidak boleh kosong
  static String? requiredDate(DateTime? value, [String fieldName = 'Tanggal']) {
    if (value == null) {
      return '$fieldName wajib diisi';
    }
    return null;
  }

  /// Validasi tanggal tidak boleh di masa depan
  static String? notFutureDate(DateTime? value, [String fieldName = 'Tanggal']) {
    if (value == null) {
      return '$fieldName wajib diisi';
    }
    if (value.isAfter(DateTime.now())) {
      return '$fieldName tidak boleh di masa depan';
    }
    return null;
  }

  /// Validasi tanggal tidak boleh di masa lalu
  static String? notPastDate(DateTime? value, [String fieldName = 'Tanggal']) {
    if (value == null) {
      return '$fieldName wajib diisi';
    }
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final valueOnly = DateTime(value.year, value.month, value.day);
    if (valueOnly.isBefore(todayOnly)) {
      return '$fieldName tidak boleh di masa lalu';
    }
    return null;
  }

  /// Validasi tanggal jatuh tempo (minimal hari ini)
  static String? dueDate(DateTime? value, [String fieldName = 'Tanggal jatuh tempo']) {
    if (value == null) return null; // Due date optional
    
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final valueOnly = DateTime(value.year, value.month, value.day);
    
    if (valueOnly.isBefore(todayOnly)) {
      return '$fieldName tidak boleh di masa lalu';
    }
    return null;
  }

  // ===== TEXT PATTERN VALIDATORS =====

  /// Validasi nama (hanya huruf dan spasi)
  static String? name(String? value, [String fieldName = 'Nama']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName wajib diisi';
    }
    // Allow letters, spaces, and common name characters
    if (!RegExp(r"^[a-zA-Z\s\.\-']+$").hasMatch(value.trim())) {
      return '$fieldName hanya boleh berisi huruf';
    }
    return null;
  }

  /// Validasi nomor telepon
  static String? phoneNumber(String? value, [String fieldName = 'Nomor telepon']) {
    if (value == null || value.trim().isEmpty) {
      return null; // Phone number optional
    }
    final cleaned = value.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.length < 10 || cleaned.length > 15) {
      return '$fieldName tidak valid';
    }
    return null;
  }

  /// Validasi persentase (0-100)
  static String? percentage(String? value, [String fieldName = 'Persentase']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName wajib diisi';
    }

    final cleaned = value.replaceAll('%', '').trim();
    final pct = double.tryParse(cleaned);
    
    if (pct == null) {
      return '$fieldName tidak valid';
    }
    if (pct < 0 || pct > 100) {
      return '$fieldName harus antara 0-100';
    }
    return null;
  }

  // ===== COMBINATION VALIDATORS =====

  /// Combine multiple validators
  static String? combine(List<String? Function()> validators) {
    for (final validator in validators) {
      final result = validator();
      if (result != null) return result;
    }
    return null;
  }

  // ===== HELPER METHODS =====

  /// Parse amount string to double safely
  static double parseAmount(String? value) {
    if (value == null || value.isEmpty) return 0;
    final cleaned = value
        .replaceAll('Rp', '')
        .replaceAll('.', '')
        .replaceAll(',', '.')
        .replaceAll(' ', '')
        .trim();
    return double.tryParse(cleaned) ?? 0;
  }

  /// Parse quantity string to int safely
  static int parseQuantity(String? value) {
    if (value == null || value.isEmpty) return 0;
    return int.tryParse(value.trim()) ?? 0;
  }
}
