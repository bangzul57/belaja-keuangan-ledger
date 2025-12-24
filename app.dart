import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_colors.dart';
import 'core/constants/app_routes.dart';
import 'core/constants/app_strings.dart';
import 'providers/settings_provider.dart';

// Screens
import 'screens/accounts/account_detail_screen.dart';
import 'screens/accounts/add_asset_account_screen.dart';
import 'screens/accounts/edit_balance_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/digital/digital_form_screen.dart';
import 'screens/digital/digital_list_screen.dart';
import 'screens/digital/digital_topup_screen.dart';
import 'screens/ledger/ledger_detail_screen.dart';
import 'screens/ledger/ledger_screen.dart';
import 'screens/ledger/transaction_detail_screen.dart';
import 'screens/prive/prive_form_screen.dart';
import 'screens/receivable/add_receivable_screen.dart';
import 'screens/receivable/receivable_detail_screen.dart';
import 'screens/receivable/receivable_list_screen.dart';
import 'screens/receivable/receive_payment_screen.dart';
import 'screens/retail/retail_form_screen.dart';
import 'screens/retail/retail_list_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/transfer/transfer_form_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, _) {
        return MaterialApp(
          title: AppStrings.appName,
          debugShowCheckedModeBanner: false,
          theme: _buildTheme(Brightness.light),
          darkTheme: _buildTheme(Brightness.dark),
          themeMode: settingsProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          initialRoute: AppRoutes.dashboard,
          routes: _buildRoutes(),
          onUnknownRoute: (settings) => MaterialPageRoute(
            builder: (_) => const _NotFoundScreen(),
          ),
        );
      },
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: brightness,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: isDark ? colorScheme.surface : colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: colorScheme.outlineVariant.withOpacity(0.5),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? colorScheme.surfaceVariant.withOpacity(0.3)
            : colorScheme.surfaceVariant.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.outlineVariant.withOpacity(0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.error,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.error,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withOpacity(0.5),
        thickness: 1,
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
      ),
      dialogTheme: DialogTheme(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Map<String, WidgetBuilder> _buildRoutes() {
    return {
      // Dashboard
      AppRoutes.dashboard: (_) => const DashboardScreen(),

      // Accounts
      AppRoutes.addAssetAccount: (_) => const AddAssetAccountScreen(),
      AppRoutes.accountDetail: (_) => const AccountDetailScreen(),
      AppRoutes.editBalance: (_) => const EditBalanceScreen(),

      // Digital Transactions
      AppRoutes.digitalList: (_) => const DigitalListScreen(),
      AppRoutes.digitalForm: (_) => const DigitalFormScreen(),
      AppRoutes.digitalTopup: (_) => const DigitalTopupScreen(),

      // Retail Transactions
      AppRoutes.retailList: (_) => const RetailListScreen(),
      AppRoutes.retailForm: (_) => const RetailFormScreen(),

      // Receivable (Piutang)
      AppRoutes.receivableList: (_) => const ReceivableListScreen(),
      AppRoutes.addReceivable: (_) => const AddReceivableScreen(),
      AppRoutes.receivableDetail: (_) => const ReceivableDetailScreen(),
      AppRoutes.receivePayment: (_) => const ReceivePaymentScreen(),

      // Transfer
      AppRoutes.transferForm: (_) => const TransferFormScreen(),

      // Prive (Penarikan Pribadi)
      AppRoutes.priveForm: (_) => const PriveFormScreen(),

      // Ledger
      AppRoutes.ledger: (_) => const LedgerScreen(),
      AppRoutes.ledgerDetail: (_) => const LedgerDetailScreen(),
      AppRoutes.transactionDetail: (_) => const TransactionDetailScreen(),

      // Settings
      AppRoutes.settings: (_) => const SettingsScreen(),
    };
  }
}

/// Screen untuk menangani route yang tidak ditemukan
class _NotFoundScreen extends StatelessWidget {
  const _NotFoundScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Halaman Tidak Ditemukan'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 80,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 24),
              Text(
                '404',
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.error,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Halaman tidak ditemukan',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Halaman yang Anda cari tidak ada atau telah dipindahkan.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.dashboard,
                  (route) => false,
                ),
                icon: const Icon(Icons.home),
                label: const Text('Kembali ke Dashboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
