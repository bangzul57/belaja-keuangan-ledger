import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../models/account.dart';
import '../../models/receivable.dart';
import '../../providers/account_provider.dart';
import '../../providers/receivable_provider.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/money_input.dart';
import '../../widgets/primary_button.dart';

/// Screen untuk menerima pembayaran piutang
class ReceivePaymentScreen extends StatefulWidget {
  const ReceivePaymentScreen({super.key});

  @override
  State<ReceivePaymentScreen> createState() => _ReceivePaymentScreenState();
}

class _ReceivePaymentScreenState extends State<ReceivePaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  Receivable? _receivable;
  Account? _selectedAccount;
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  bool _payFull = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initData();
    });
  }

  void _initData() {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Receivable) {
      setState(() {
        _receivable = args;
        _amountController.text = Formatters.formatNumber(args.remainingAmount);
      });
    }

    final accountProvider = context.read<AccountProvider>();
    _selectedAccount = accountProvider.cashAccount;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _amount => Validators.parseAmount(_amountController.text);

  Future<void> _submitPayment() async {
    if (!_formKey.currentState!.validate()) return;

    if (_receivable == null) return;

    if (_selectedAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih akun tujuan')),
      );
      return;
    }

    // Konfirmasi
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: 'Konfirmasi Pembayaran',
      message: _buildConfirmMessage(),
      confirmText: 'Proses',
    );

    if (!confirmed) return;

    final provider = context.read<ReceivableProvider>();

    final success = await provider.receivePayment(
      receivableId: _receivable!.id!,
      amount: _amount,
      paymentMethod: _paymentMethod,
      destinationAccountId: _selectedAccount!.id!,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pembayaran berhasil dicatat'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Gagal memproses pembayaran'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  String _buildConfirmMessage() {
    final buffer = StringBuffer();
    buffer.writeln('Pembeli: ${_receivable?.buyerName}');
    buffer.writeln('Nominal: ${Formatters.formatCurrency(_amount)}');
    buffer.writeln('Metode: ${_paymentMethod.label}');
    buffer.writeln('Ke Akun: ${_selectedAccount?.name}');

    final remaining = (_receivable?.remainingAmount ?? 0) - _amount;
    if (remaining <= 0) {
      buffer.writeln('\n✅ Piutang akan LUNAS');
    } else {
      buffer.writeln('\nSisa: ${Formatters.formatCurrency(remaining)}');
    }

    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accountProvider = context.watch<AccountProvider>();
    final receivableProvider = context.watch<ReceivableProvider>();

    if (_receivable == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Terima Pembayaran')),
        body: const Center(child: Text('Data tidak ditemukan')),
      );
    }

    final receivable = _receivable!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Terima Pembayaran'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Receivable Info
            _buildReceivableInfo(theme, receivable),

            const SizedBox(height: 24),

            // Quick Amount Buttons
            _buildQuickAmountButtons(theme, receivable),

            const SizedBox(height: 16),

            // Amount Input
            MoneyInput(
              controller: _amountController,
              labelText: 'Nominal Pembayaran',
              validator: (value) {
                final error = Validators.positiveAmount(value, 'Nominal');
                if (error != null) return error;

                final amount = Validators.parseAmount(value);
                if (amount > receivable.remainingAmount) {
                  return 'Nominal melebihi sisa hutang';
                }
                return null;
              },
              onChanged: (_) {
                setState(() {
                  _payFull = _amount >= receivable.remainingAmount;
                });
              },
            ),

            const SizedBox(height: 24),

            // Payment Method
            Text(
              'Metode Pembayaran',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildPaymentMethodSelector(theme),

            const SizedBox(height: 24),

            // Destination Account
            Text(
              'Masuk ke Akun',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildAccountSelector(theme, accountProvider),

            const SizedBox(height: 24),

            // Summary
            _buildSummary(theme, receivable),

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
              text: _payFull ? 'Lunasi Piutang' : 'Catat Pembayaran',
              icon: Icons.check,
              isLoading: receivableProvider.isProcessing,
              onPressed: _submitPayment,
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildReceivableInfo(ThemeData theme, Receivable receivable) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: theme.colorScheme.primary,
            child: Text(
              receivable.buyerName[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  receivable.buyerName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Sisa: ${Formatters.formatCurrency(receivable.remainingAmount)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAmountButtons(ThemeData theme, Receivable receivable) {
    final remaining = receivable.remainingAmount;
    final half = remaining / 2;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              _amountController.text = Formatters.formatNumber(remaining);
              setState(() {
                _payFull = true;
              });
            },
            child: const Text('Lunas'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              _amountController.text = Formatters.formatNumber(half);
              setState(() {
                _payFull = false;
              });
            },
            child: const Text('Setengah'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              _amountController.clear();
              setState(() {
                _payFull = false;
              });
            },
            child: const Text('Custom'),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodSelector(ThemeData theme) {
    return Wrap(
      spacing: 8,
      children: PaymentMethod.values.map((method) {
        final isSelected = _paymentMethod == method;
        return ChoiceChip(
          label: Text(method.label),
          selected: isSelected,
          onSelected: (_) {
            setState(() {
              _paymentMethod = method;
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildAccountSelector(ThemeData theme, AccountProvider provider) {
    return DropdownButtonFormField<Account>(
      value: _selectedAccount,
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.account_balance_wallet),
      ),
      items: provider.assetAccounts.map((account) {
        return DropdownMenuItem(
          value: account,
          child: Row(
            children: [
              Expanded(child: Text(account.name)),
              Text(
                Formatters.formatCurrency(account.balance),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: (account) {
        setState(() {
          _selectedAccount = account;
        });
      },
      validator: (value) {
        if (value == null) return 'Pilih akun';
        return null;
      },
    );
  }

  Widget _buildSummary(ThemeData theme, Receivable receivable) {
    final remaining = receivable.remainingAmount - _amount;
    final isFullPayment = remaining <= 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isFullPayment
            ? AppColors.success.withOpacity(0.1)
            : theme.colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFullPayment
              ? AppColors.success.withOpacity(0.3)
              : theme.dividerColor,
        ),
      ),
      child: Column(
        children: [
          _buildSummaryRow(
            theme,
            'Sisa Hutang Saat Ini',
            Formatters.formatCurrency(receivable.remainingAmount),
          ),
          const SizedBox(height: 8),
          _buildSummaryRow(
            theme,
            'Pembayaran',
            '- ${Formatters.formatCurrency(_amount)}',
            valueColor: AppColors.success,
          ),
          const Divider(height: 24),
          _buildSummaryRow(
            theme,
            'Sisa Setelah Bayar',
            isFullPayment ? 'LUNAS' : Formatters.formatCurrency(remaining),
            isBold: true,
            valueColor: isFullPayment ? AppColors.success : AppColors.error,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    ThemeData theme,
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
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
}
