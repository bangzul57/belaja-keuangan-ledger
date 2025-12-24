import 'package:sqflite/sqflite.dart';

/// Database Migration Handler
/// Mengelola pembuatan tabel dan migrasi skema database
class DBMigration {
  DBMigration._();

  // ===== TABLE NAMES =====
  static const String tableAccounts = 'accounts';
  static const String tableTransactions = 'transactions';
  static const String tableJournalEntries = 'journal_entries';
  static const String tableInventoryItems = 'inventory_items';
  static const String tableReceivables = 'receivables';
  static const String tableReceivablePayments = 'receivable_payments';
  static const String tableSettings = 'settings';
  static const String tableAuditLogs = 'audit_logs';

  /// Buat semua tabel
  static Future<void> createTables(Database db) async {
    await _createAccountsTable(db);
    await _createTransactionsTable(db);
    await _createJournalEntriesTable(db);
    await _createInventoryItemsTable(db);
    await _createReceivablesTable(db);
    await _createReceivablePaymentsTable(db);
    await _createSettingsTable(db);
    await _createAuditLogsTable(db);
    await _createIndexes(db);
  }

  /// Tabel Accounts (Akun: Kas, E-Wallet, Bank, Piutang)
  static Future<void> _createAccountsTable(Database db) async {
    await db.execute('''
      CREATE TABLE $tableAccounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        balance REAL NOT NULL DEFAULT 0,
        initial_balance REAL NOT NULL DEFAULT 0,
        icon TEXT,
        color TEXT,
        description TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        is_default INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  /// Tabel Transactions (Transaksi Induk)
  static Future<void> _createTransactionsTable(Database db) async {
    await db.execute('''
      CREATE TABLE $tableTransactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_code TEXT UNIQUE,
        transaction_type TEXT NOT NULL,
        transaction_mode TEXT,
        amount REAL NOT NULL,
        admin_fee REAL DEFAULT 0,
        profit REAL DEFAULT 0,
        source_account_id INTEGER,
        destination_account_id INTEGER,
        inventory_item_id INTEGER,
        quantity INTEGER DEFAULT 1,
        buyer_name TEXT,
        description TEXT,
        notes TEXT,
        is_credit INTEGER NOT NULL DEFAULT 0,
        receivable_id INTEGER,
        balance_before_source REAL,
        balance_after_source REAL,
        balance_before_dest REAL,
        balance_after_dest REAL,
        is_voided INTEGER NOT NULL DEFAULT 0,
        voided_at TEXT,
        voided_reason TEXT,
        transaction_date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (source_account_id) REFERENCES $tableAccounts(id) ON DELETE SET NULL,
        FOREIGN KEY (destination_account_id) REFERENCES $tableAccounts(id) ON DELETE SET NULL,
        FOREIGN KEY (inventory_item_id) REFERENCES $tableInventoryItems(id) ON DELETE SET NULL,
        FOREIGN KEY (receivable_id) REFERENCES $tableReceivables(id) ON DELETE SET NULL
      )
    ''');
  }

  /// Tabel Journal Entries (Jurnal Double-Entry)
  static Future<void> _createJournalEntriesTable(Database db) async {
    await db.execute('''
      CREATE TABLE $tableJournalEntries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_id INTEGER NOT NULL,
        account_id INTEGER NOT NULL,
        entry_type TEXT NOT NULL,
        amount REAL NOT NULL,
        balance_before REAL NOT NULL,
        balance_after REAL NOT NULL,
        description TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (transaction_id) REFERENCES $tableTransactions(id) ON DELETE CASCADE,
        FOREIGN KEY (account_id) REFERENCES $tableAccounts(id) ON DELETE CASCADE
      )
    ''');
  }

  /// Tabel Inventory Items (Stok Barang untuk Ritel)
  static Future<void> _createInventoryItemsTable(Database db) async {
    await db.execute('''
      CREATE TABLE $tableInventoryItems (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        sku TEXT UNIQUE,
        category TEXT,
        stock INTEGER NOT NULL DEFAULT 0,
        min_stock INTEGER NOT NULL DEFAULT 5,
        unit TEXT NOT NULL DEFAULT 'pcs',
        buy_price REAL NOT NULL DEFAULT 0,
        sell_price REAL NOT NULL DEFAULT 0,
        description TEXT,
        supplier_name TEXT,
        last_restock_date TEXT,
        last_restock_price REAL,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  /// Tabel Receivables (Piutang)
  static Future<void> _createReceivablesTable(Database db) async {
    await db.execute('''
      CREATE TABLE $tableReceivables (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        buyer_name TEXT NOT NULL,
        phone_number TEXT,
        total_amount REAL NOT NULL,
        paid_amount REAL NOT NULL DEFAULT 0,
        remaining_amount REAL NOT NULL,
        profit_amount REAL DEFAULT 0,
        source_transaction_id INTEGER,
        due_date TEXT,
        status TEXT NOT NULL DEFAULT 'pending',
        notes TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (source_transaction_id) REFERENCES $tableTransactions(id) ON DELETE SET NULL
      )
    ''');
  }

  /// Tabel Receivable Payments (Pembayaran Piutang)
  static Future<void> _createReceivablePaymentsTable(Database db) async {
    await db.execute('''
      CREATE TABLE $tableReceivablePayments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        receivable_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        payment_method TEXT NOT NULL,
        destination_account_id INTEGER,
        notes TEXT,
        payment_date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (receivable_id) REFERENCES $tableReceivables(id) ON DELETE CASCADE,
        FOREIGN KEY (destination_account_id) REFERENCES $tableAccounts(id) ON DELETE SET NULL
      )
    ''');
  }

  /// Tabel Settings (Pengaturan Aplikasi)
  static Future<void> _createSettingsTable(Database db) async {
    await db.execute('''
      CREATE TABLE $tableSettings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        key TEXT NOT NULL UNIQUE,
        value TEXT,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  /// Tabel Audit Logs (Log Aktivitas untuk Undo)
  static Future<void> _createAuditLogsTable(Database db) async {
    await db.execute('''
      CREATE TABLE $tableAuditLogs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT NOT NULL,
        record_id INTEGER NOT NULL,
        action TEXT NOT NULL,
        old_data TEXT,
        new_data TEXT,
        user_note TEXT,
        created_at TEXT NOT NULL
      )
    ''');
  }

  /// Create Indexes untuk optimasi query
  static Future<void> _createIndexes(Database db) async {
    // Index untuk transactions
    await db.execute(
      'CREATE INDEX idx_transactions_date ON $tableTransactions(transaction_date)',
    );
    await db.execute(
      'CREATE INDEX idx_transactions_type ON $tableTransactions(transaction_type)',
    );
    await db.execute(
      'CREATE INDEX idx_transactions_source ON $tableTransactions(source_account_id)',
    );
    await db.execute(
      'CREATE INDEX idx_transactions_dest ON $tableTransactions(destination_account_id)',
    );

    // Index untuk journal_entries
    await db.execute(
      'CREATE INDEX idx_journal_transaction ON $tableJournalEntries(transaction_id)',
    );
    await db.execute(
      'CREATE INDEX idx_journal_account ON $tableJournalEntries(account_id)',
    );

    // Index untuk receivables
    await db.execute(
      'CREATE INDEX idx_receivables_status ON $tableReceivables(status)',
    );
    await db.execute(
      'CREATE INDEX idx_receivables_buyer ON $tableReceivables(buyer_name)',
    );

    // Index untuk inventory
    await db.execute(
      'CREATE INDEX idx_inventory_category ON $tableInventoryItems(category)',
    );
  }

  /// Insert data default
  static Future<void> insertDefaultData(Database db) async {
    final now = DateTime.now().toIso8601String();

    // Insert default Cash account
    await db.insert(tableAccounts, {
      'name': 'Kas',
      'type': 'cash',
      'balance': 0,
      'initial_balance': 0,
      'icon': 'wallet',
      'color': '#66BB6A',
      'description': 'Uang tunai di tangan',
      'is_active': 1,
      'is_default': 1,
      'created_at': now,
      'updated_at': now,
    });

    // Insert default settings
    final defaultSettings = [
      {'key': 'is_dark_mode', 'value': 'false'},
      {'key': 'is_digital_enabled', 'value': 'true'},
      {'key': 'is_retail_enabled', 'value': 'true'},
      {'key': 'default_admin_fee', 'value': '2500'},
      {'key': 'default_admin_percentage', 'value': '2.5'},
      {'key': 'use_percentage_admin', 'value': 'false'},
      {'key': 'low_stock_threshold', 'value': '5'},
      {'key': 'currency_symbol', 'value': 'Rp'},
      {'key': 'date_format', 'value': 'dd/MM/yyyy'},
    ];

    for (final setting in defaultSettings) {
      await db.insert(tableSettings, {
        ...setting,
        'updated_at': now,
      });
    }
  }

  /// Handle migrasi database
  static Future<void> migrate(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // Migrasi bertahap berdasarkan versi
    for (int version = oldVersion + 1; version <= newVersion; version++) {
      switch (version) {
        case 2:
          await _migrateToV2(db);
          break;
        case 3:
          await _migrateToV3(db);
          break;
        // Tambahkan case untuk versi selanjutnya
      }
    }
  }

  /// Migrasi ke versi 2 (contoh)
  static Future<void> _migrateToV2(Database db) async {
    // Contoh: Tambah kolom baru
    // await db.execute('ALTER TABLE $tableAccounts ADD COLUMN new_field TEXT');
  }

  /// Migrasi ke versi 3 (contoh)
  static Future<void> _migrateToV3(Database db) async {
    // Contoh: Buat tabel baru atau modifikasi
  }
}
