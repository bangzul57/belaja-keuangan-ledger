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

/// Form untuk transaksi digital
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
  bool _useCustomAdminFee = false;
  DateTime? _dueDate;

  double _calculatedProfit = 0;
  double _calculatedTotal = 0;

  @override
  void initState() {
    super.initState();
    _initDefaultValues();
  }

  void _initDefaultValues() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final accountProvider = context.read<AccountProvider>();
      final settingsProvider = context.read<SettingsProvider>();

      // Set default accounts
      final digitalAccounts = accountProvider.digitalAndBankAccounts;
      final cashAccount = accountProvider.cashAccount;

      if (digitalAccounts.isNotEmpty) {
        setState(() {
          _selectedDigitalAccount = digitalAccounts.first;
        });
      }

      if (cashAccount != null) {
        setState(() {
          _selectedCashAccount = cashAccount;
        });
      }

      // Set default admin fee
      _adminFeeController.text = Formatters.formatNumber(
        settingsProvider.defaultAdminFee,
      );
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _adminFeeController.dispose();
    _buyerNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _calculateProfit() {
    final amount = Validators.parseAmount(_amountController.text);
    final adminFee = Validators.parseAmount(_adminFeeController.text);

    setState(() {
      _calculatedProfit = adminFee;
      switch (_selectedMode) {
        case DigitalTransactionMode.buyBalance:
          _calculatedTotal = amount + adminFee;
          break;
        case DigitalTransactionMode.sellBalanceDeduct:
          _calculatedTotal = amount - adminFee;
          break;
        case DigitalTransactionMode.sellBalanceCash:
          _calculatedTotal = amount;
          break;
        default:
          _calculatedTotal = amount;
      }
    });
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

    // Confirm dialog
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: AppStrings.confirmTransaction,
      message: _buildConfirmMessage(),
      confirmText: 'Simpan',
      type: ConfirmDialogType.confirm,
    );

    if (!confirmed) return;

    final transactionProvider = context.read<TransactionProvider>();

    final amount = Validators.parseAmount(_amountController.text);
    final adminFee = Validators.parseAmount(_adminFeeController.text);

    final success = await transactionProvider.processDigitalTransaction(
      mode: _selectedMode,
      digitalAccountId: _selectedDigitalAccount!.id!,
      cashAccountId: _selectedCashAccount!.id!,
      amount: amount,
      adminFee: adminFee,
      buyerName: _buyerNameController.text.trim().isNotEmpty
          ? _buyerNameController.text.trim()
          : null,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
      isCredit: _isCredit,
      dueDate: _dueDate,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.transactionSaved),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(transactionProvider.errorMessage ?? AppStrings.errorSaving),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  String _buildConfirmMessage() {
    final amount = Validators.parseAmount(_amountController.text);
    final adminFee = Validators.parseAmount(_adminFeeController.text);

    final buffer = StringBuffer();
    buffer.writeln('Mode: ${_selectedMode.label}');
    buffer.writeln('Nominal: ${Formatters.formatCurrency(amount)}');
    buffer.writeln('Admin: ${Formatters.formatCurrency(adminFee)}');
    buffer.writeln('');
    buffer.writeln('Akun Digital: ${_selectedDigitalAccount?.name}');
    buffer.writeln('Akun Kas: ${_selectedCashAccount?.name}');

    if (_isCredit) {
      buffer.writeln('');
      buffer.writeln('⚠️ Transaksi ini adalah HUTANG');
      if (_buyerNameController.text.isNotEmpty) {
        buffer.writeln('Pembeli: ${_buyerNameController.text}');
      }
    }

    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaksi Digital'),
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, transactionProvider, _) {
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Mode Selection
                _buildModeSelection(theme),

                const SizedBox(height: 24),

                // Account Selection
                _buildAccountSelection(),

                const SizedBox(height: 24),

                // Amount Input
                _buildAmountSection(),

                const SizedBox(height: 24),

                // Credit Option
                _buildCreditOption(theme),

                const SizedBox(height: 24),

                // Buyer Name (for credit or optional)
                _buildBuyerNameInput(),

                const SizedBox(height: 16),

                // Notes
                _buildNotesInput(),

                const SizedBox(height: 24),

                // Summary Card
                _buildSummaryCard(theme),

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
          );
        },
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
            final color = _getModeColor(mode);

            return InkWell(
              onTap: () {
                setState(() {
                  _selectedMode = mode;
                });
                _calculateProfit();
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? color.withOpacity(0.15) : null,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? color : theme.colorScheme.outline,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getModeIcon(mode),
                      color: isSelected ? color : theme.colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      mode.label,
                      style: TextStyle(
                        color: isSelected ? color : null,
                        fontWeight: isSelected ? FontWeight.bold : null,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Text(
          _selectedMode.description,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildAccountSelection() {
    return Consumer<AccountProvider>(
      builder: (context, accountProvider, _) {
        final digitalAccounts = accountProvider.digitalAndBankAccounts;
        final cashAccounts = accountProvider.cashAccounts;

        return Column(
          children: [
            // Digital Account
            DropdownButtonFormField<Account>(
              value: _selectedDigitalAccount,
              decoration: const InputDecoration(
                labelText: 'Akun Digital / Bank',
                prefixIcon: Icon(Icons.smartphone),
              ),
              items: digitalAccounts.map((account) {
                return DropdownMenuItem(
                  value: account,
                  child: Row(
                    children: [
                      Expanded(child: Text(account.name)),
                      Text(
                        Formatters.formatCurrency(account.balance),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedDigitalAccount = value;
                });
              },
              validator: (value) {
                if (value == null) return 'Pilih akun digital';
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Cash Account
            DropdownButtonFormField<Account>(
              value: _selectedCashAccount,
              decoration: const InputDecoration(
                labelText: 'Akun Kas',
                prefixIcon: Icon(Icons.account_balance_wallet),
              ),
              items: cashAccounts.map((account) {
                return DropdownMenuItem(
                  value: account,
                  child: Row(
                    children: [
                      Expanded(child: Text(account.name)),
                      Text(
                        Formatters.formatCurrency(account.balance),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCashAccount = value;
                });
              },
              validator: (value) {
                if (value == null) return 'Pilih akun kas';
                return null;
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildAmountSection() {
    return Column(
      children: [
        // Amount
        MoneyInput(
          controller: _amountController,
          labelText: 'Nominal Saldo',
          hintText: 'Contoh: 50.000',
          validator: (value) => Validators.positiveAmount(value, 'Nominal'),
          onChanged: (_) => _calculateProfit(),
        ),

        const SizedBox(height: 16),

        // Admin Fee
        Row(
          children: [
            Expanded(
              child: MoneyInput(
                controller: _adminFeeController,
                labelText: 'Biaya Admin',
                enabled: _useCustomAdminFee,
                onChanged: (_) => _calculateProfit(),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              children: [
                const Text('Custom', style: TextStyle(fontSize: 12)),
                Switch(
                  value: _useCustomAdminFee,
                  onChanged: (value) {
                    setState(() {
                      _useCustomAdminFee = value;
                      if (!value) {
                        // Reset to default
                        final settings = context.read<SettingsProvider>();
                        _adminFeeController.text = Formatters.formatNumber(
                          settings.defaultAdminFee,
                        );
                        _calculateProfit();
                      }
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCreditOption(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isCredit
            ? AppColors.warning.withOpacity(0.1)
            : theme.colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isCredit
              ? AppColors.warning.withOpacity(0.3)
              : theme.colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.access_time,
                color: _isCredit ? AppColors.warning : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Transaksi Hutang',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _isCredit ? AppColors.warning : null,
                      ),
                    ),
                    Text(
                      'Pembeli belum membayar (dicatat sebagai piutang)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _isCredit,
                activeColor: AppColors.warning,
                onChanged: (value) {
                  setState(() {
                    _isCredit = value;
                    if (!value) {
                      _dueDate = null;
                    }
                  });
                },
              ),
            ],
          ),

          // Due Date (if credit)
          if (_isCredit) ...[
            const SizedBox(height: 16),
            InkWell(
              onTap: _selectDueDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Jatuh Tempo (Opsional)',
                  prefixIcon: Icon(Icons.event),
                  border: OutlineInputBorder(),
                ),
                child: Text(
                  _dueDate != null
                      ? Formatters.formatDate(_dueDate)
                      : 'Pilih tanggal jatuh tempo',
                  style: TextStyle(
                    color: _dueDate != null
                        ? null
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBuyerNameInput() {
    return TextFormField(
      controller: _buyerNameController,
      decoration: InputDecoration(
        labelText: _isCredit ? 'Nama Pembeli *' : 'Nama Pembeli (Opsional)',
        prefixIcon: const Icon(Icons.person_outline),
        hintText: 'Contoh: Budi',
      ),
      textCapitalization: TextCapitalization.words,
      validator: _isCredit
          ? (value) => Validators.required(value, 'Nama pembeli')
          : null,
    );
  }

  Widget _buildNotesInput() {
    return TextFormField(
      controller: _notesController,
      decoration: const InputDecoration(
        labelText: 'Catatan (Opsional)',
        prefixIcon: Icon(Icons.notes),
        hintText: 'Tambahkan catatan...',
      ),
      maxLines: 2,
    );
  }

  Widget _buildSummaryCard(ThemeData theme) {
    final amount = Validators.parseAmount(_amountController.text);
    final adminFee = Validators.parseAmount(_adminFeeController.text);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ringkasan Transaksi',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          _buildSummaryRow('Nominal Saldo', Formatters.formatCurrency(amount)),
          const SizedBox(height: 8),
          _buildSummaryRow(
            'Biaya Admin',
            Formatters.formatCurrency(adminFee),
            color: AppColors.success,
          ),
          const Divider(height: 24),
          _buildSummaryRow(
            _getTotalLabel(),
            Formatters.formatCurrency(_calculatedTotal),
            isBold: true,
          ),
          const SizedBox(height: 8),
          _buildSummaryRow(
            'Profit',
            '+${Formatters.formatCurrency(_calculatedProfit)}',
            color: AppColors.success,
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    Color? color,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : null,
            color: color,
          ),
        ),
      ],
    );
  }

  String _getTotalLabel() {
    switch (_selectedMode) {
      case DigitalTransactionMode.buyBalance:
        return 'Pembeli Bayar';
      case DigitalTransactionMode.sellBalanceDeduct:
        return 'Pembeli Terima';
      case DigitalTransactionMode.sellBalanceCash:
        return 'Pembeli Terima + Admin Tunai';
      default:
        return 'Total';
    }
  }

  Future<void> _selectDueDate() async {
    final result = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (result != null) {
      setState(() {
        _dueDate = result;
      });
    }
  }

  Color _getModeColor(DigitalTransactionMode mode) {
    switch (mode) {
      case DigitalTransactionMode.buyBalance:
        return AppColors.expense;
      case DigitalTransactionMode.sellBalanceDeduct:
      case DigitalTransactionMode.sellBalanceCash:
        return AppColors.income;
      default:
        return AppColors.primary;
    }
  }

  IconData _getModeIcon(DigitalTransactionMode mode) {
    switch (mode) {
      case DigitalTransactionMode.buyBalance:
        return Icons.arrow_upward;
      case DigitalTransactionMode.sellBalanceDeduct:
      case DigitalTransactionMode.sellBalanceCash:
        return Icons.arrow_downward;
      default:
        return Icons.swap_horiz;
    }
  }
}
