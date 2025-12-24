/// Konstanta untuk nama-nama route navigasi
/// Dipisahkan berdasarkan fitur/modul
class AppRoutes {
  AppRoutes._(); // Private constructor

  // ===== DASHBOARD =====
  static const String dashboard = '/';

  // ===== ACCOUNTS =====
  static const String addAssetAccount = '/account/add';
  static const String accountDetail = '/account/detail';
  static const String editBalance = '/account/edit-balance';

  // ===== DIGITAL TRANSACTIONS =====
  static const String digitalList = '/digital';
  static const String digitalForm = '/digital/form';
  static const String digitalTopup = '/digital/topup';

  // ===== RETAIL TRANSACTIONS =====
  static const String retailList = '/retail';
  static const String retailForm = '/retail/form';
  
  // ===== INVENTORY =====
  static const String inventoryList = '/inventory';
  static const String inventoryForm = '/inventory/form';
  static const String inventoryDetail = '/inventory/detail';

  // ===== RECEIVABLE (PIUTANG) =====
  static const String receivableList = '/receivable';
  static const String addReceivable = '/receivable/add';
  static const String receivableDetail = '/receivable/detail';
  static const String receivePayment = '/receivable/payment';

  // ===== TRANSFER =====
  static const String transferForm = '/transfer';

  // ===== PRIVE (PENARIKAN PRIBADI) =====
  static const String priveForm = '/prive';

  // ===== LEDGER =====
  static const String ledger = '/ledger';
  static const String ledgerDetail = '/ledger/detail';
  static const String transactionDetail = '/transaction/detail';

  // ===== REPORTS & ANALYTICS =====
  static const String reports = '/reports';
  static const String analytics = '/analytics';

  // ===== SETTINGS =====
  static const String settings = '/settings';
  static const String backup = '/settings/backup';
  static const String about = '/settings/about';
}
