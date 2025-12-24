import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/journal_entry.dart';
import '../../models/transaction_model.dart';
import '../../providers/ledger_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/confirm_dialog.dart';

/// Screen detail transaksi
class TransactionDetailScreen extends StatefulWidget {
  const TransactionDetailScreen({super.key});

  @override
  State<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  TransactionModel? _transaction;
  List<JournalEntry> _journalEntries = [];
  bool _isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadData();
  }

  Future<void> _loadData() async {
    final args = ModalRoute.of(context)?.settings.arguments;

    TransactionModel? transaction;

    if (args is TransactionModel) {
      transaction = args;
    } else if (args is Map<String, dynamic>) {
      final transactionId = args['transactionId'] as int?;
      if (transactionId != null) {
        transaction = context.read<TransactionProvider>().getTransactionById(transactionId);
      }
    }

    if (transaction != null) {
      final ledgerProvider = context.read<LedgerProvider>();
      final entries = await ledgerProvider.loadEntriesForTransaction(transaction.id!);

      if (mounted) {
        setState(() {
          _transaction = transaction;
          _journalEntries = entries;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _voidTransaction() async {
    if (_transaction == null) return;

    final reason = await InputDialog.show(
      context: context,
      title: 'Batalkan Transaksi',
      message: 'Masukkan alasan pembatalan:',
      hintText: 'Alasan pembatalan',
      confirmText: 'Batalkan',
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Alasan wajib diisi';
        }
        return null;
      },
    );

    if (reason == null || reason.isEmpty) return;

    final provider = context.read<TransactionProvider>();
    final success = await provider.voidTransaction(_transaction!.id!, reason);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaksi berhasil dibatalkan'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Gagal membatalkan transaksi'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Transaksi')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_transaction == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Transaksi')),
        body: const Center(child: Text('Transaksi tidak ditemukan')),
      );
    }

    final transaction = _transaction!;
    final isVoided = transaction.isVoided;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Transaksi'),
        actions: [
          if (!isVoided)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'void') {
                  _voidTransaction();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'void',
                  child: Row(
                    children: [
                      Icon(Icons.cancel, color: AppColors.error),
                      SizedBox(width: 8),
                      Text('Batalkan Transaksi'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Voided Warning
          if (isVoided) _buildVoidedWarning(theme, transaction),

          // Transaction Header
          _buildTransactionHeader(theme, transaction),

          const SizedBox(height: 16),

          // Amount Card
          _buildAmountCard(theme, transaction),

          const SizedBox(height: 16),

          // Details Card
          _buildDetailsCard(theme, transaction),

          const SizedBox(height: 16),

          // Audit Trail Card
          _buildAuditTrailCard(theme, transaction),

          const SizedBox(height: 16),

          // Journal Entries
          _buildJournalEntriesCard(theme),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildVoidedWarning(ThemeData theme, TransactionModel transaction) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cancel, color: AppColors.error),
              const SizedBox(width: 8),
              Text(
                'TRANSAKSI DIBATALKAN',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (transaction.voidedReason != null) ...[
            const SizedBox(height: 8),
            Text(
              'Alasan: ${transaction.voidedReason}',
              style: theme.textTheme.bodyMedium,
            ),
          ],
          if (transaction.voidedAt != null) ...[
            const SizedBox(height: 4),
            Text(
              'Dibatalkan pada: ${Formatters.formatDateTime(transaction.voidedAt)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTransactionHeader(ThemeData theme, TransactionModel transaction) {
    final typeColor = _getTypeColor(transaction.transactionType);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: typeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: typeColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getTypeIcon(transaction.transactionType),
              color: typeColor,
              size: 32,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            transaction.transactionType.label,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (transaction.transactionMode != null)
            Text(
              transaction.transactionMode!.label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          if (transaction.transactionCode != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                transaction.transactionCode!,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAmountCard(ThemeData theme, TransactionModel transaction) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nominal',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            _buildAmountRow(
              theme,
              'Nominal Transaksi',
              Formatters.formatCurrency(transaction.amount),
            ),
            if (transaction.adminFee > 0)
              _buildAmountRow(
                theme,
                'Biaya Admin',
                Formatters.formatCurrency(transaction.adminFee),
              ),
            if (transaction.quantity > 1)
              _buildAmountRow(
                theme,
                'Jumlah',
                '${transaction.quantity} item',
              ),
            const Divider(),
            _buildAmountRow(
              theme,
              'Profit',
              Formatters.formatCurrency(transaction.profit),
              valueColor: transaction.profit >= 0 ? AppColors.success : AppColors.error,
              isBold: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard(ThemeData theme, TransactionModel transaction) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detail',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            if (transaction.sourceAccountName != null)
              _buildDetailRow(
                theme,
                Icons.logout,
                'Dari Akun',
                transaction.sourceAccountName!,
              ),
            if (transaction.destinationAccountName != null)
              _buildDetailRow(
                theme,
                Icons.login,
                'Ke Akun',
                transaction.destinationAccountName!,
              ),
            if (transaction.inventoryItemName != null)
              _buildDetailRow(
                theme,
                Icons.inventory_2,
                'Barang',
                transaction.inventoryItemName!,
              ),
            if (transaction.buyerName != null)
              _buildDetailRow(
                theme,
                Icons.person,
                'Pembeli',
                transaction.buyerName!,
              ),
            if (transaction.description != null)
              _buildDetailRow(
                theme,
                Icons.description,
                'Keterangan',
                transaction.description!,
              ),
            if (transaction.notes != null)
              _buildDetailRow(
                theme,
                Icons.notes,
                'Catatan',
                transaction.notes!,
              ),
            _buildDetailRow(
              theme,
              Icons.access_time,
              'Tanggal',
              Formatters.formatDateTime(transaction.transactionDate),
            ),
            if (transaction.isCredit)
              _buildDetailRow(
                theme,
                Icons.warning,
                'Status',
                'HUTANG',
                valueColor: AppColors.warning,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuditTrailCard(ThemeData theme, TransactionModel transaction) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Audit Trail',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            if (transaction.balanceBeforeSource != null)
              _buildAuditRow(
                theme,
                'Saldo Asal (Sebelum)',
                Formatters.formatCurrency(transaction.balanceBeforeSource!),
              ),
            if (transaction.balanceAfterSource != null)
              _buildAuditRow(
                theme,
                'Saldo Asal (Sesudah)',
                Formatters.formatCurrency(transaction.balanceAfterSource!),
              ),
            if (transaction.balanceBeforeDest != null) ...[
              const Divider(height: 16),
              _buildAuditRow(
                theme,
                'Saldo Tujuan (Sebelum)',
                Formatters.formatCurrency(transaction.balanceBeforeDest!),
              ),
            ],
            if (transaction.balanceAfterDest != null)
              _buildAuditRow(
                theme,
                'Saldo Tujuan (Sesudah)',
                Formatters.formatCurrency(transaction.balanceAfterDest!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildJournalEntriesCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Jurnal Entry',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_journalEntries.length} entry',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            const Divider(),
            if (_journalEntries.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'Tidak ada jurnal entry',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else
              ..._journalEntries.map((entry) => _buildJournalEntryRow(theme, entry)),
          ],
        ),
      ),
    );
  }

  Widget _buildJournalEntryRow(ThemeData theme, JournalEntry entry) {
    final isDebit = entry.isDebit;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isDebit ? AppColors.success : AppColors.error,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              entry.entryType.label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              entry.accountName ?? 'Akun #${entry.accountId}',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Text(
            Formatters.formatCurrency(entry.amount),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDebit ? AppColors.success : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountRow(
    ThemeData theme,
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    ThemeData theme,
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(TransactionType type) {
    switch (type) {
      case TransactionType.digital:
        return AppColors.digitalAccount;
      case TransactionType.retail:
        return AppColors.success;
      case TransactionType.transfer:
        return AppColors.info;
      case TransactionType.prive:
        return AppColors.error;
      case TransactionType.adjustment:
        return AppColors.warning;
      case TransactionType.receivablePayment:
        return AppColors.success;
    }
  }

  IconData _getTypeIcon(TransactionType type) {
    switch (type) {
      case TransactionType.digital:
        return Icons.smartphone;
      case TransactionType.retail:
        return Icons.store;
      case TransactionType.transfer:
        return Icons.swap_horiz;
      case TransactionType.prive:
        return Icons.account_balance_wallet;
      case TransactionType.adjustment:
        return Icons.tune;
      case TransactionType.receivablePayment:
        return Icons.payments;
    }
  }
}
