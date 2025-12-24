import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../models/account.dart';
import '../../providers/account_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/money_input.dart';
import '../../widgets/primary_button.dart';

/// Screen untuk top up saldo (Kas → Digital/Bank)
class DigitalTopupScreen extends StatefulWidget {
  const DigitalTopupScreen({super.key});

  @override
  State<DigitalTopupScreen> createState() => _DigitalTopupScreenState();
}

class _DigitalTopupScreenState extends State<DigitalTopupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _adminFeeController = TextEditingController();
  final _notesController = TextEditingController();

  Account? _selectedSourceAccount;
  Account? _selectedDestinationAccount;

  @override
  void initState() {
    super.initState();
    _initDefaults();
  }

  void _initDefaults() {
    final accountProvider = context.read<AccountProvider>();

    // Default source: cash account
    _selectedSourceAccount = accountProvider.cashAccount;

    // Default destination: first digital/bank account
    if (accountProvider.digitalAndBankAccounts.isNotEmpty) {
      _selectedDestinationAccount = accountProvider.digitalAndBankAccounts.first;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _adminFeeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _amount => Validators.parseAmount(_amountController.text);
  double get _adminFee => Validators.parseAmount(_adminFeeController.text);
  double get _totalDeduction => _amount + _adminFee;
  double get _amountReceived => _amount; // Admin tidak mengurangi yang diterima

  Future<void> _submitTopup() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSourceAccount == null || _selectedDestinationAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih akun terlebih dahulu')),
      );
      return;
    }

    // Validasi saldo cukup
    if (!_selectedSourceAccount!.hasSufficientBalance(_totalDeduction)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Saldo ${_selectedSourceAccount!.name} tidak mencukupi',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Konfirmasi
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: 'Konfirmasi Top Up',
      message: _buildConfirmMessage(),
      confirmText: 'Proses',
    );

    if (!confirmed) return;

    final transactionProvider = context.read<TransactionProvider>();

    final success = await transactionProvider.processTransfer(
      sourceAccountId: _selectedSourceAccount!.id!,
      destinationAccountId: _selectedDestinationAccount!.id!,
      amount: _amount,
      adminFee: _adminFee,
      description: 'Top Up ${_selectedDestinationAccount!.name}',
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Top up berhasil'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(transactionProvider.errorMessage ?? 'Gagal melakukan top up'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  String _buildConfirmMessage() {
    final buffer = StringBuffer();
    buffer.writeln('Dari: ${_selectedSourceAccount?.name}');
    buffer.writeln('Ke: ${_selectedDestinationAccount?.name}');
    buffer.writeln('');
    buffer.writeln('Nominal: ${Formatters.formatCurrency(_amount)}');
    if (_adminFee > 0) {
      buffer.writeln('Biaya Admin: ${Formatters.formatCurrency(_adminFee)}');
      buffer.writeln('Total Pengurangan: ${Formatters.formatCurrency(_totalDeduction)}');
    }
    buffer.writeln('');
    buffer.writeln(
      'Saldo ${_selectedDestinationAccount?.name} akan bertambah ${Formatters.formatCurrency(_amountReceived)}',
    );

    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accountProvider = context.watch<AccountProvider>();
    final transactionProvider = context.watch<TransactionProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Top Up Saldo'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Info Card
            _buildInfoCard(theme),

            const SizedBox(height: 24),

            // Source Account
            Text(
              'Dari Akun',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildAccountSelector(
              accounts: accountProvider.cashAccounts,
              selectedAccount: _selectedSourceAccount,
              onSelected: (account) {
                setState(() {
                  _selectedSourceAccount = account;
                });
              },
              emptyMessage: 'Tidak ada akun kas',
            ),

            const SizedBox(height: 24),

            // Arrow Indicator
            _buildArrowIndicator(theme),

            const SizedBox(height: 24),

            // Destination Account
            Text(
              'Ke Akun',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildAccountSelector(
              accounts: accountProvider.digitalAndBankAccounts,
              selectedAccount: _selectedDestinationAccount,
              onSelected: (account) {
                setState(() {
                  _selectedDestinationAccount = account;
                });
              },
              emptyMessage: 'Tidak ada akun digital/bank',
            ),

            const SizedBox(height: 24),

            // Amount Input
            MoneyInput(
              controller: _amountController,
              labelText: 'Nominal Top Up',
              validator: (value) {
                final error = Validators.positiveAmount(value, 'Nominal');
                if (error != null) return error;

                if (_selectedSourceAccount != null) {
                  final totalNeeded = Validators.parseAmount(value) + _adminFee;
                  if (totalNeeded > _selectedSourceAccount!.balance) {
                    return 'Saldo tidak mencukupi (tersedia: ${Formatters.formatCurrency(_selectedSourceAccount!.balance)})';
                  }
                }
                return null;
              },
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 16),

            // Admin Fee Input
            MoneyInput(
              controller: _adminFeeController,
              labelText: 'Biaya Admin Provider (Opsional)',
              hintText: '0',
              helperText: 'Biaya yang dikenakan provider untuk top up',
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 24),

            // Summary Card
            if (_amount > 0) _buildSummaryCard(theme),

            const SizedBox(height: 16),

            // Notes Input
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Catatan (Opsional)',
                prefixIcon: Icon(Icons.notes),
                hintText: 'Tambahkan catatan',
              ),
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
            ),

            const SizedBox(height: 32),

            // Submit Button
            PrimaryButton(
              text: 'Proses Top Up',
              icon: Icons.upload,
              isLoading: transactionProvider.isProcessing,
              onPressed: _submitTopup,
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.info, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Top Up Saldo',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppColors.info,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Transfer saldo dari Kas ke E-Wallet atau Bank. '
                  'Biaya admin adalah biaya yang dikenakan oleh provider (jika ada).',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.info,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArrowIndicator(ThemeData theme) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.arrow_downward,
          color: theme.colorScheme.primary,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildAccountSelector({
    required List<Account> accounts,
    required Account? selectedAccount,
    required ValueChanged<Account> onSelected,
    required String emptyMessage,
  }) {
    final theme = Theme.of(context);

    if (accounts.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 32,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              emptyMessage,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: accounts.map((account) {
        final isSelected = selectedAccount?.id == account.id;
        final color = AppColors.getAccountTypeColor(account.type.value);

        return InkWell(
          onTap: () => onSelected(account),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? color : theme.dividerColor,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        _getAccountIcon(account.type),
                        size: 16,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      account.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? color : null,
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.check_circle, size: 16, color: color),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 30),
                  child: Text(
                    Formatters.formatCurrency(account.balance),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSummaryCard(ThemeData theme) {
    final hasAdminFee = _adminFee > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ringkasan',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),

          // Nominal
          _buildSummaryRow(
            theme,
            label: 'Nominal Top Up',
            value: Formatters.formatCurrency(_amount),
          ),

          if (hasAdminFee) ...[
            const SizedBox(height: 8),
            _buildSummaryRow(
              theme,
              label: 'Biaya Admin',
              value: '- ${Formatters.formatCurrency(_adminFee)}',
              valueColor: AppColors.error,
            ),
          ],

          const Divider(height: 24),

          // Total dari sumber
          _buildSummaryRow(
            theme,
            label: 'Total dari ${_selectedSourceAccount?.name ?? 'Sumber'}',
            value: '- ${Formatters.formatCurrency(_totalDeduction)}',
            valueColor: AppColors.error,
            isBold: true,
          ),

          const SizedBox(height: 8),

          // Total ke tujuan
          _buildSummaryRow(
            theme,
            label: 'Diterima ${_selectedDestinationAccount?.name ?? 'Tujuan'}',
            value: '+ ${Formatters.formatCurrency(_amountReceived)}',
            valueColor: AppColors.success,
            isBold: true,
          ),

          if (hasAdminFee) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber,
                    size: 14,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Biaya admin akan mengurangi saldo sumber tetapi tidak menambah saldo tujuan',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.warning,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    ThemeData theme, {
    required String label,
    required String value,
    Color? valueColor,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: valueColor ?? theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  IconData _getAccountIcon(AccountType type) {
    switch (type) {
      case AccountType.cash:
        return Icons.wallet;
      case AccountType.digital:
        return Icons.smartphone;
      case AccountType.bank:
        return Icons.account_balance;
      case AccountType.receivable:
        return Icons.receipt_long;
    }
  }
}
