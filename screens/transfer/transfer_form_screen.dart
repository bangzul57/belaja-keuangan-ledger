import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../models/account.dart';
import '../../providers/account_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/money_input.dart';
import '../../widgets/primary_button.dart';

/// Form untuk transfer antar akun
class TransferFormScreen extends StatefulWidget {
  const TransferFormScreen({super.key});

  @override
  State<TransferFormScreen> createState() => _TransferFormScreenState();
}

class _TransferFormScreenState extends State<TransferFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _adminFeeController = TextEditingController();
  final _notesController = TextEditingController();

  Account? _sourceAccount;
  Account? _destinationAccount;

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

  void _swapAccounts() {
    setState(() {
      final temp = _sourceAccount;
      _sourceAccount = _destinationAccount;
      _destinationAccount = temp;
    });
  }

  Future<void> _submitTransfer() async {
    if (!_formKey.currentState!.validate()) return;

    if (_sourceAccount == null || _destinationAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih akun asal dan tujuan')),
      );
      return;
    }

    if (_sourceAccount!.id == _destinationAccount!.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Akun asal dan tujuan tidak boleh sama'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Validasi saldo
    if (!_sourceAccount!.hasSufficientBalance(_totalDeduction)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saldo ${_sourceAccount!.name} tidak mencukupi'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Konfirmasi
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: 'Konfirmasi Transfer',
      message: _buildConfirmMessage(),
      confirmText: 'Proses',
    );

    if (!confirmed) return;

    final transactionProvider = context.read<TransactionProvider>();

    final success = await transactionProvider.processTransfer(
      sourceAccountId: _sourceAccount!.id!,
      destinationAccountId: _destinationAccount!.id!,
      amount: _amount,
      adminFee: _adminFee,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transfer berhasil'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(transactionProvider.errorMessage ?? 'Transfer gagal'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  String _buildConfirmMessage() {
    final buffer = StringBuffer();
    buffer.writeln('Dari: ${_sourceAccount?.name}');
    buffer.writeln('Ke: ${_destinationAccount?.name}');
    buffer.writeln('');
    buffer.writeln('Nominal: ${Formatters.formatCurrency(_amount)}');
    if (_adminFee > 0) {
      buffer.writeln('Biaya Admin: ${Formatters.formatCurrency(_adminFee)}');
      buffer.writeln('Total Pengurangan: ${Formatters.formatCurrency(_totalDeduction)}');
    }
    buffer.writeln('');
    buffer.writeln('${_sourceAccount?.name}: -${Formatters.formatCurrency(_totalDeduction)}');
    buffer.writeln('${_destinationAccount?.name}: +${Formatters.formatCurrency(_amount)}');

    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accountProvider = context.watch<AccountProvider>();
    final transactionProvider = context.watch<TransactionProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.transfer),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Source Account
            Text(
              'Dari Akun',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildAccountDropdown(
              value: _sourceAccount,
              accounts: accountProvider.assetAccounts,
              excludeId: _destinationAccount?.id,
              onChanged: (account) {
                setState(() {
                  _sourceAccount = account;
                });
              },
              hint: 'Pilih akun asal',
            ),

            const SizedBox(height: 16),

            // Swap Button
            Center(
              child: IconButton.filled(
                onPressed: _swapAccounts,
                icon: const Icon(Icons.swap_vert),
                tooltip: 'Tukar Akun',
              ),
            ),

            const SizedBox(height: 16),

            // Destination Account
            Text(
              'Ke Akun',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildAccountDropdown(
              value: _destinationAccount,
              accounts: accountProvider.assetAccounts,
              excludeId: _sourceAccount?.id,
              onChanged: (account) {
                setState(() {
                  _destinationAccount = account;
                });
              },
              hint: 'Pilih akun tujuan',
            ),

            const SizedBox(height: 24),

            // Amount
            MoneyInput(
              controller: _amountController,
              labelText: 'Nominal Transfer',
              validator: (value) {
                final error = Validators.positiveAmount(value, 'Nominal');
                if (error != null) return error;

                if (_sourceAccount != null) {
                  final total = Validators.parseAmount(value) + _adminFee;
                  if (total > _sourceAccount!.balance) {
                    return 'Saldo tidak mencukupi';
                  }
                }
                return null;
              },
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 16),

            // Admin Fee
            MoneyInput(
              controller: _adminFeeController,
              labelText: 'Biaya Admin (Opsional)',
              hintText: '0',
              helperText: 'Biaya admin akan mengurangi saldo asal',
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 24),

            // Summary
            if (_amount > 0) _buildSummary(theme),

            const SizedBox(height: 16),

            // Notes
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Catatan (Opsional)',
                prefixIcon: Icon(Icons.notes),
              ),
              maxLines: 2,
            ),

            const SizedBox(height: 32),

            // Submit Button
            PrimaryButton(
              text: 'Proses Transfer',
              icon: Icons.swap_horiz,
              isLoading: transactionProvider.isProcessing,
              onPressed: _submitTransfer,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountDropdown({
    required Account? value,
    required List<Account> accounts,
    required ValueChanged<Account?> onChanged,
    required String hint,
    int? excludeId,
  }) {
    final theme = Theme.of(context);
    final filteredAccounts = excludeId != null
        ? accounts.where((a) => a.id != excludeId).toList()
        : accounts;

    return DropdownButtonFormField<Account>(
      value: value,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.account_balance_wallet),
      ),
      items: filteredAccounts.map((account) {
        final color = AppColors.getAccountTypeColor(account.type.value);
        return DropdownMenuItem(
          value: account,
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(account.name),
                    Text(
                      account.type.label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                Formatters.formatCurrency(account.balance),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (value) {
        if (value == null) return 'Pilih akun';
        return null;
      },
    );
  }

  Widget _buildSummary(ThemeData theme) {
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
            'Ringkasan Transfer',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),

          _buildSummaryRow(
            theme,
            label: 'Nominal Transfer',
            value: Formatters.formatCurrency(_amount),
          ),

          if (hasAdminFee) ...[
            const SizedBox(height: 8),
            _buildSummaryRow(
              theme,
              label: 'Biaya Admin',
              value: Formatters.formatCurrency(_adminFee),
              valueColor: AppColors.error,
            ),
          ],

          const Divider(height: 24),

          if (_sourceAccount != null)
            _buildSummaryRow(
              theme,
              label: _sourceAccount!.name,
              value: '- ${Formatters.formatCurrency(_totalDeduction)}',
              valueColor: AppColors.error,
              isBold: true,
            ),

          if (_destinationAccount != null) ...[
            const SizedBox(height: 8),
            _buildSummaryRow(
              theme,
              label: _destinationAccount!.name,
              value: '+ ${Formatters.formatCurrency(_amount)}',
              valueColor: AppColors.success,
              isBold: true,
            ),
          ],

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
                    Icons.info_outline,
                    size: 14,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Biaya admin tidak ditambahkan ke akun tujuan',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.warning,
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
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
