import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../models/account.dart';
import '../../models/digital_transaction_mode.dart';
import '../../providers/account_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/money_input.dart';
import '../../widgets/primary_button.dart';

/// Form untuk transaksi digital (beli/jual saldo)
class DigitalFormScreen extends StatefulWidget {
  const DigitalFormScreen({super.key});

  @override
  State<DigitalFormScreen> createState() => _DigitalFormScreenState();
}

class _DigitalFormScreenState extends State<DigitalFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _adminFeeController = TextEditingController();
  final _buyerNameController = TextEditingController();
  final _notesController = TextEditingController();

  DigitalTransactionMode _selectedMode = DigitalTransactionMode.buyBalance;
  Account? _selectedDigitalAccount;
  Account? _selectedCashAccount;
  bool _isCredit = false;
  bool _usePercentageAdmin = false;
  bool _showQuickCalc = false;
  DateTime? _dueDate;

  // Quick calc
  final _receivedController = TextEditingController();
  double _changeAmount = 0;

  @override
  void initState() {
    super.initState();
    _initializeDefaults();
  }

  void _initializeDefaults() {
    final settingsProvider = context.read<SettingsProvider>();
    final accountProvider = context.read<AccountProvider>();

    _usePercentageAdmin = settingsProvider.usePercentageAdmin;
    _adminFeeController.text = _usePercentageAdmin
        ? settingsProvider.defaultAdminPercentage.toString()
        : Formatters.formatNumber(settingsProvider.defaultAdminFee);

    // Set default cash account
    _selectedCashAccount = accountProvider.cashAccount;

    // Set default digital account (first one)
    if (accountProvider.digitalAndBankAccounts.isNotEmpty) {
      _selectedDigitalAccount = accountProvider.digitalAndBankAccounts.first;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _adminFeeController.dispose();
    _buyerNameController.dispose();
    _notesController.dispose();
    _receivedController.dispose();
    super.dispose();
  }

  double get _amount => Validators.parseAmount(_amountController.text);

  double get _adminFee {
    if (_usePercentageAdmin) {
      final percentage = double.tryParse(_adminFeeController.text) ?? 0;
      return _amount * (percentage / 100);
    }
    return Validators.parseAmount(_adminFeeController.text);
  }

  double get _totalTransaction {
    switch (_selectedMode) {
      case DigitalTransactionMode.buyBalance:
        return _amount + _adminFee; // Pembeli bayar nominal + admin
      case DigitalTransactionMode.sellBalanceDeduct:
        return _amount - _adminFee; // Owner bayar nominal - admin
      case DigitalTransactionMode.sellBalanceCash:
        return _amount; // Owner bayar nominal penuh, admin terpisah
      default:
        return _amount;
    }
  }

  void _calculateChange() {
    final received = Validators.parseAmount(_receivedController.text);
    setState(() {
      _changeAmount = received - _totalTransaction;
    });
  }

  Future<void> _selectDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  Future<void> _submitTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDigitalAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih akun digital terlebih dahulu')),
      );
      return;
    }

    if (_selectedCashAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih akun kas terlebih dahulu')),
      );
      return;
    }

    // Konfirmasi
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: AppStrings.confirmTransaction,
      message: _buildConfirmationMessage(),
      confirmText: 'Proses',
      type: ConfirmDialogType.confirm,
    );

    if (!confirmed) return;

    final transactionProvider = context.read<TransactionProvider>();

    final success = await transactionProvider.processDigitalTransaction(
      mode: _selectedMode,
      digitalAccountId: _selectedDigitalAccount!.id!,
      cashAccountId: _selectedCashAccount!.id!,
      amount: _amount,
      adminFee: _adminFee,
      buyerName: _buyerNameController.text.trim().isNotEmpty
          ? _buyerNameController.text.trim()
          : null,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
      isCredit: _isCredit,
      dueDate: _isCredit ? _dueDate : null,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(AppStrings.transactionSaved),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(transactionProvider.errorMessage ?? AppStrings.errorSaving),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _buildConfirmationMessage() {
    final buffer = StringBuffer();
    buffer.writeln('Mode: ${_selectedMode.label}');
    buffer.writeln('Akun Digital: ${_selectedDigitalAccount?.name}');
    buffer.writeln('Akun Kas: ${_selectedCashAccount?.name}');
    buffer.writeln('Nominal: ${Formatters.formatCurrency(_amount)}');
    buffer.writeln('Admin: ${Formatters.formatCurrency(_adminFee)}');
    buffer.writeln('Total: ${Formatters.formatCurrency(_totalTransaction)}');

    if (_isCredit) {
      buffer.writeln('\n⚠️ Transaksi ini akan dicatat sebagai HUTANG');
      if (_dueDate != null) {
        buffer.writeln('Jatuh Tempo: ${Formatters.formatDate(_dueDate)}');
      }
    }

    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accountProvider = context.watch<AccountProvider>();
    final transactionProvider = context.watch<TransactionProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaksi Digital'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Transaction Mode Selection
            _buildModeSelection(theme),

            const SizedBox(height: 24),

            // Digital Account Selection
            _buildAccountDropdown(
              label: 'Akun Digital / Bank',
              value: _selectedDigitalAccount,
              accounts: accountProvider.digitalAndBankAccounts,
              onChanged: (account) {
                setState(() {
                  _selectedDigitalAccount = account;
                });
              },
              icon: Icons.smartphone,
            ),

            const SizedBox(height: 16),

            // Cash Account Selection
            _buildAccountDropdown(
              label: 'Akun Kas',
              value: _selectedCashAccount,
              accounts: accountProvider.cashAccounts,
              onChanged: (account) {
                setState(() {
                  _selectedCashAccount = account;
                });
              },
              icon: Icons.wallet,
            ),

            const SizedBox(height: 24),

            // Amount Input
            MoneyInput(
              controller: _amountController,
              labelText: 'Nominal Saldo',
              hintText: 'Masukkan nominal',
              validator: (value) => Validators.positiveAmount(value, 'Nominal'),
              onChanged: (_) {
                setState(() {});
                _calculateChange();
              },
            ),

            const SizedBox(height: 16),

            // Admin Fee Input
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _usePercentageAdmin
                      ? TextFormField(
                          controller: _adminFeeController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Admin (%)',
                            suffixText: '%',
                            helperText: 'Admin: ${Formatters.formatCurrency(_adminFee)}',
                          ),
                          validator: (value) => Validators.percentage(value),
                          onChanged: (_) {
                            setState(() {});
                            _calculateChange();
                          },
                        )
                      : MoneyInput(
                          controller: _adminFeeController,
                          labelText: 'Biaya Admin',
                          onChanged: (_) {
                            setState(() {});
                            _calculateChange();
                          },
                        ),
                ),
                const SizedBox(width: 8),
                Column(
                  children: [
                    const SizedBox(height: 8),
                    ChoiceChip(
                      label: Text(_usePercentageAdmin ? '%' : 'Rp'),
                      selected: true,
                      onSelected: (_) {
                        setState(() {
                          _usePercentageAdmin = !_usePercentageAdmin;
                          _adminFeeController.clear();
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Transaction Summary
            _buildTransactionSummary(theme),

            const SizedBox(height: 24),

            // Buyer Name (Optional)
            TextFormField(
              controller: _buyerNameController,
              decoration: const InputDecoration(
                labelText: 'Nama Pembeli (Opsional)',
                hintText: 'Masukkan nama pembeli',
                prefixIcon: Icon(Icons.person_outline),
              ),
              textCapitalization: TextCapitalization.words,
            ),

            const SizedBox(height: 16),

            // Credit Toggle
            SwitchListTile(
              title: const Text('Transaksi Hutang'),
              subtitle: const Text('Pembeli belum membayar'),
              value: _isCredit,
              onChanged: (value) {
                setState(() {
                  _isCredit = value;
                  if (!value) {
                    _dueDate = null;
                  }
                });
              },
              contentPadding: EdgeInsets.zero,
            ),

            // Due Date (if credit)
            if (_isCredit) ...[
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event),
                title: Text(
                  _dueDate != null
                      ? Formatters.formatDate(_dueDate)
                      : 'Pilih Jatuh Tempo',
                ),
                trailing: _dueDate != null
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _dueDate = null;
                          });
                        },
                      )
                    : null,
                onTap: _selectDueDate,
              ),
            ],

            const SizedBox(height: 16),

            // Quick Calc Toggle
            SwitchListTile(
              title: const Text('Hitung Kembalian'),
              value: _showQuickCalc,
              onChanged: (value) {
                setState(() {
                  _showQuickCalc = value;
                });
              },
              contentPadding: EdgeInsets.zero,
            ),

            // Quick Calc
            if (_showQuickCalc) ...[
              const SizedBox(height: 8),
              _buildQuickCalc(theme),
            ],

            const SizedBox(height: 16),

            // Notes
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Catatan (Opsional)',
                hintText: 'Tambahkan catatan',
                prefixIcon: Icon(Icons.notes),
              ),
              maxLines: 2,
            ),

            const SizedBox(height: 32),

            // Submit Button
            PrimaryButton(
              text: 'Simpan Transaksi',
              isLoading: transactionProvider.isProcessing,
              onPressed: _submitTransaction,
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSelection(ThemeData theme) {
    final modes = DigitalTransactionMode.values.buyerModes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Jenis Transaksi',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: modes.map((mode) {
            final isSelected = _selectedMode == mode;
            return ChoiceChip(
              label: Text(mode.label),
              selected: isSelected,
              onSelected: (_) {
                setState(() {
                  _selectedMode = mode;
                });
              },
              selectedColor: theme.colorScheme.primary.withOpacity(0.2),
              labelStyle: TextStyle(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _selectedMode.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccountDropdown({
    required String label,
    required Account? value,
    required List<Account> accounts,
    required ValueChanged<Account?> onChanged,
    required IconData icon,
  }) {
    final theme = Theme.of(context);

    return DropdownButtonFormField<Account>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
      items: accounts.map((account) {
        return DropdownMenuItem(
          value: account,
          child: Row(
            children: [
              Expanded(
                child: Text(account.name),
              ),
              Text(
                Formatters.formatCurrency(account.balance),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
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

  Widget _buildTransactionSummary(ThemeData theme) {
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
        children: [
          _buildSummaryRow(
            'Nominal Saldo',
            Formatters.formatCurrency(_amount),
            theme,
          ),
          const Divider(height: 16),
          _buildSummaryRow(
            'Biaya Admin',
            '${_selectedMode.isBuyMode ? '+' : '-'}${Formatters.formatCurrency(_adminFee)}',
            theme,
            valueColor: _selectedMode.isBuyMode
                ? AppColors.success
                : AppColors.error,
          ),
          const Divider(height: 16),
          _buildSummaryRow(
            _selectedMode.isBuyMode ? 'Pembeli Bayar' : 'Owner Bayar',
            Formatters.formatCurrency(_totalTransaction),
            theme,
            isBold: true,
          ),
          const SizedBox(height: 8),
          _buildSummaryRow(
            'Profit',
            Formatters.formatCurrency(_adminFee),
            theme,
            valueColor: AppColors.success,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value,
    ThemeData theme, {
    Color? valueColor,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
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

  Widget _buildQuickCalc(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hitung Kembalian',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          MoneyInput(
            controller: _receivedController,
            labelText: 'Uang Diterima',
            onChanged: (_) => _calculateChange(),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Kembalian:'),
              Text(
                Formatters.formatCurrency(_changeAmount),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _changeAmount >= 0 ? AppColors.success : AppColors.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
