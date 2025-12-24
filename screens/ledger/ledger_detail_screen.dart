import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../core/utils/formatters.dart';
import '../../models/journal_entry.dart';

/// Screen detail jurnal entry
class LedgerDetailScreen extends StatelessWidget {
  const LedgerDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entry = ModalRoute.of(context)?.settings.arguments as JournalEntry?;

    if (entry == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Jurnal')),
        body: const Center(child: Text('Data tidak ditemukan')),
      );
    }

    final isDebit = entry.isDebit;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Jurnal'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Entry Type Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDebit
                  ? AppColors.success.withOpacity(0.1)
                  : AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDebit
                    ? AppColors.success.withOpacity(0.3)
                    : AppColors.error.withOpacity(0.3),
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isDebit ? AppColors.success : AppColors.error,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    entry.entryType.label.toUpperCase(),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${isDebit ? '+' : '-'}${Formatters.formatCurrency(entry.amount)}',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDebit ? AppColors.success : AppColors.error,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Account Info
          _buildInfoCard(
            context,
            title: 'Informasi Akun',
            children: [
              _buildInfoRow(
                context,
                icon: Icons.account_balance_wallet,
                label: 'Nama Akun',
                value: entry.accountName ?? 'Akun #${entry.accountId}',
              ),
              if (entry.accountType != null)
                _buildInfoRow(
                  context,
                  icon: Icons.category,
                  label: 'Tipe Akun',
                  value: entry.accountType!,
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Balance Info
          _buildInfoCard(
            context,
            title: 'Perubahan Saldo',
            children: [
              _buildInfoRow(
                context,
                icon: Icons.account_balance,
                label: 'Saldo Sebelum',
                value: Formatters.formatCurrency(entry.balanceBefore),
              ),
              _buildInfoRow(
                context,
                icon: isDebit ? Icons.add_circle : Icons.remove_circle,
                label: isDebit ? 'Penambahan' : 'Pengurangan',
                value: Formatters.formatCurrency(entry.amount),
                valueColor: isDebit ? AppColors.success : AppColors.error,
              ),
              const Divider(),
              _buildInfoRow(
                context,
                icon: Icons.account_balance,
                label: 'Saldo Sesudah',
                value: Formatters.formatCurrency(entry.balanceAfter),
                isBold: true,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Transaction Info
          _buildInfoCard(
            context,
            title: 'Informasi Transaksi',
            children: [
              _buildInfoRow(
                context,
                icon: Icons.tag,
                label: 'ID Transaksi',
                value: '#${entry.transactionId}',
              ),
              if (entry.transactionCode != null)
                _buildInfoRow(
                  context,
                  icon: Icons.qr_code,
                  label: 'Kode Transaksi',
                  value: entry.transactionCode!,
                ),
              if (entry.description != null)
                _buildInfoRow(
                  context,
                  icon: Icons.description,
                  label: 'Keterangan',
                  value: entry.description!,
                ),
              _buildInfoRow(
                context,
                icon: Icons.access_time,
                label: 'Waktu',
                value: Formatters.formatDateTime(entry.createdAt),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // View Transaction Button
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pushNamed(
                context,
                AppRoutes.transactionDetail,
                arguments: {'transactionId': entry.transactionId},
              );
            },
            icon: const Icon(Icons.receipt_long),
            label: const Text('Lihat Detail Transaksi'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    bool isBold = false,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: theme.colorScheme.primary,
          ),
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
                    fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
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
}
