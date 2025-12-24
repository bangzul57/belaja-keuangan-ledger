import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/formatters.dart';
import '../../models/journal_entry.dart';
import '../../providers/account_provider.dart';
import '../../providers/ledger_provider.dart';

/// Screen buku besar (ledger)
class LedgerScreen extends StatefulWidget {
  const LedgerScreen({super.key});

  @override
  State<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends State<LedgerScreen> {
  int? _selectedAccountId;
  DateTimeRange? _dateFilter;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await context.read<LedgerProvider>().loadEntries();
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateFilter,
    );

    if (picked != null) {
      setState(() {
        _dateFilter = picked;
      });
      context.read<LedgerProvider>().setDateFilter(picked.start, picked.end);
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedAccountId = null;
      _dateFilter = null;
    });
    context.read<LedgerProvider>().clearFilters();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ledgerProvider = context.watch<LedgerProvider>();
    final accountProvider = context.watch<AccountProvider>();

    final entries = ledgerProvider.filteredEntries;
    final hasFilter = ledgerProvider.hasActiveFilter;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.ledger),
        actions: [
          if (hasFilter)
            IconButton(
              icon: const Icon(Icons.clear_all),
              tooltip: 'Hapus Filter',
              onPressed: _clearFilters,
            ),
          IconButton(
            icon: const Icon(Icons.date_range),
            tooltip: 'Filter Tanggal',
            onPressed: _selectDateRange,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Section
          _buildFilterSection(theme, accountProvider),

          // Summary Card
          _buildSummaryCard(theme, ledgerProvider),

          // Date Filter Chip
          if (_dateFilter != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Chip(
                    label: Text(
                      '${Formatters.formatDate(_dateFilter!.start)} - ${Formatters.formatDate(_dateFilter!.end)}',
                    ),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () {
                      setState(() {
                        _dateFilter = null;
                      });
                      ledgerProvider.setDateFilter(null, null);
                    },
                  ),
                ],
              ),
            ),

          // Entry List
          Expanded(
            child: ledgerProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : entries.isEmpty
                    ? _buildEmptyState(theme)
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: entries.length,
                          itemBuilder: (context, index) {
                            final entry = entries[index];
                            return _buildEntryCard(context, entry);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(ThemeData theme, AccountProvider accountProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: DropdownButtonFormField<int?>(
        value: _selectedAccountId,
        decoration: InputDecoration(
          labelText: 'Filter Akun',
          prefixIcon: const Icon(Icons.account_balance_wallet),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        items: [
          const DropdownMenuItem<int?>(
            value: null,
            child: Text('Semua Akun'),
          ),
          ...accountProvider.assetAccounts.map((account) {
            return DropdownMenuItem<int?>(
              value: account.id,
              child: Text(account.name),
            );
          }),
        ],
        onChanged: (value) {
          setState(() {
            _selectedAccountId = value;
          });
          context.read<LedgerProvider>().setAccountFilter(value);
        },
      ),
    );
  }

  Widget _buildSummaryCard(ThemeData theme, LedgerProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Text(
                  'Total Debit',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  Formatters.formatCurrency(provider.filteredTotalDebit),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: theme.dividerColor,
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'Total Credit',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  Formatters.formatCurrency(provider.filteredTotalCredit),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: theme.dividerColor,
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'Balance',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Icon(
                  provider.isBalanced ? Icons.check_circle : Icons.warning,
                  color: provider.isBalanced ? AppColors.success : AppColors.warning,
                  size: 24,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryCard(BuildContext context, JournalEntry entry) {
    final theme = Theme.of(context);
    final isDebit = entry.isDebit;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.ledgerDetail,
            arguments: entry,
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Type Indicator
              Container(
                width: 4,
                height: 50,
                decoration: BoxDecoration(
                  color: isDebit ? AppColors.success : AppColors.error,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),

              // Entry Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isDebit
                                ? AppColors.success.withOpacity(0.1)
                                : AppColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            entry.entryType.label,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: isDebit ? AppColors.success : AppColors.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            entry.accountName ?? 'Akun #${entry.accountId}',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry.description ?? 'Transaksi #${entry.transactionId}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Formatters.formatDateTime(entry.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              // Amount
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isDebit ? '+' : '-'}${Formatters.formatCurrency(entry.amount)}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDebit ? AppColors.success : AppColors.error,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Saldo: ${Formatters.formatCurrency(entry.balanceAfter)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada jurnal',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Jurnal akan terisi otomatis saat Anda melakukan transaksi',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
