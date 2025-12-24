import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../models/account.dart';
import '../../models/inventory_item.dart';
import '../../providers/account_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/money_input.dart';
import '../../widgets/primary_button.dart';

/// Form untuk transaksi ritel (penjualan barang)
class RetailFormScreen extends StatefulWidget {
  const RetailFormScreen({super.key});

  @override
  State<RetailFormScreen> createState() => _RetailFormScreenState();
}

class _RetailFormScreenState extends State<RetailFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController(text: '1');
  final _customPriceController = TextEditingController();
  final _buyerNameController = TextEditingController();
  final _notesController = TextEditingController();

  InventoryItem? _selectedItem;
  Account? _selectedAccount;
  bool _isCredit = false;
  bool _useCustomPrice = false;
  bool _showQuickCalc = false;
  DateTime? _dueDate;

  // Quick calc
  final _receivedController = TextEditingController();
  double _changeAmount = 0;

  @override
  void initState() {
    super.initState();
    _initDefaults();
  }

  void _initDefaults() {
    final accountProvider = context.read<AccountProvider>();
    _selectedAccount = accountProvider.cashAccount;
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _customPriceController.dispose();
    _buyerNameController.dispose();
    _notesController.dispose();
    _receivedController.dispose();
    super.dispose();
  }

  int get _quantity => int.tryParse(_quantityController.text) ?? 1;

  double get _sellPrice {
    if (_useCustomPrice) {
      return Validators.parseAmount(_customPriceController.text);
    }
    return _selectedItem?.sellPrice ?? 0;
  }

  double get _totalAmount => _sellPrice * _quantity;

  double get _totalProfit {
    if (_selectedItem == null) return 0;
    final costPerItem = _selectedItem!.buyPrice;
    return (_sellPrice - costPerItem) * _quantity;
  }

  void _calculateChange() {
    final received = Validators.parseAmount(_receivedController.text);
    setState(() {
      _changeAmount = received - _totalAmount;
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

    if (_selectedItem == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih barang terlebih dahulu')),
      );
      return;
    }

    if (_selectedAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih akun tujuan terlebih dahulu')),
      );
      return;
    }

    // Validasi stok
    if (!_selectedItem!.hasSufficientStock(_quantity)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Stok tidak mencukupi (tersedia: ${_selectedItem!.stock})'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Konfirmasi
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: AppStrings.confirmTransaction,
      message: _buildConfirmationMessage(),
      confirmText: 'Proses',
    );

    if (!confirmed) return;

    final transactionProvider = context.read<TransactionProvider>();

    final success = await transactionProvider.processRetailTransaction(
      itemId: _selectedItem!.id!,
      quantity: _quantity,
      destinationAccountId: _selectedAccount!.id!,
      customSellPrice: _useCustomPrice ? _sellPrice : null,
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

  String _buildConfirmationMessage() {
    final buffer = StringBuffer();
    buffer.writeln('Barang: ${_selectedItem?.name}');
    buffer.writeln('Jumlah: $_quantity ${_selectedItem?.unit ?? 'pcs'}');
    buffer.writeln('Harga: ${Formatters.formatCurrency(_sellPrice)}');
    buffer.writeln('Total: ${Formatters.formatCurrency(_totalAmount)}');
    buffer.writeln('Profit: ${Formatters.formatCurrency(_totalProfit)}');
    buffer.writeln('');
    buffer.writeln('Pembayaran ke: ${_selectedAccount?.name}');

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
    final inventoryProvider = context.watch<InventoryProvider>();
    final accountProvider = context.watch<AccountProvider>();
    final transactionProvider = context.watch<TransactionProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaksi Ritel'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Item Selection
            _buildItemSelection(context, inventoryProvider),

            const SizedBox(height: 24),

            // Quantity Input
            _buildQuantityInput(theme),

            const SizedBox(height: 16),

            // Custom Price Toggle
            SwitchListTile(
              title: const Text('Harga Custom'),
              subtitle: const Text('Gunakan harga berbeda dari harga jual'),
              value: _useCustomPrice,
              onChanged: (value) {
                setState(() {
                  _useCustomPrice = value;
                  if (!value) {
                    _customPriceController.clear();
                  }
                });
              },
              contentPadding: EdgeInsets.zero,
            ),

            // Custom Price Input
            if (_useCustomPrice) ...[
              const SizedBox(height: 8),
              MoneyInput(
                controller: _customPriceController,
                labelText: 'Harga Custom',
                validator: (value) => Validators.positiveAmount(value, 'Harga'),
                onChanged: (_) => setState(() {}),
              ),
            ],

            const SizedBox(height: 24),

            // Transaction Summary
            if (_selectedItem != null) _buildTransactionSummary(theme),

            const SizedBox(height: 24),

            // Destination Account
            _buildAccountDropdown(context, accountProvider),

            const SizedBox(height: 16),

            // Buyer Name
            TextFormField(
              controller: _buyerNameController,
              decoration: const InputDecoration(
                labelText: 'Nama Pembeli (Opsional)',
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

            // Due Date
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

  Widget _buildItemSelection(BuildContext context, InventoryProvider provider) {
    final theme = Theme.of(context);
    final inStockItems = provider.inStockItems;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Pilih Barang',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_selectedItem != null)
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedItem = null;
                  });
                },
                child: const Text('Reset'),
              ),
          ],
        ),
        const SizedBox(height: 8),

        if (inStockItems.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 48,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tidak ada barang dengan stok',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          )
        else
          DropdownButtonFormField<InventoryItem>(
            value: _selectedItem,
            decoration: const InputDecoration(
              labelText: 'Barang',
              prefixIcon: Icon(Icons.inventory_2),
            ),
            items: inStockItems.map((item) {
              final isLow = item.isLowStock;
              return DropdownMenuItem(
                value: item,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(item.name),
                          Text(
                            'Stok: ${item.stock} ${item.unit}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isLow
                                  ? AppColors.warning
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      Formatters.formatCurrency(item.sellPrice),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (item) {
              setState(() {
                _selectedItem = item;
                if (item != null && !_useCustomPrice) {
                  _customPriceController.text = Formatters.formatNumber(item.sellPrice);
                }
              });
              _calculateChange();
            },
            validator: (value) {
              if (value == null) return 'Pilih barang';
              return null;
            },
          ),

        // Selected Item Info
        if (_selectedItem != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.success.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Harga Jual',
                        style: theme.textTheme.bodySmall,
                      ),
                      Text(
                        Formatters.formatCurrency(_selectedItem!.sellPrice),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 40, color: theme.dividerColor),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Modal',
                        style: theme.textTheme.bodySmall,
                      ),
                      Text(
                        Formatters.formatCurrency(_selectedItem!.buyPrice),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 40, color: theme.dividerColor),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Profit/item',
                        style: theme.textTheme.bodySmall,
                      ),
                      Text(
                        Formatters.formatCurrency(_selectedItem!.profitPerItem),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildQuantityInput(ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Decrease Button
        IconButton.filled(
          onPressed: () {
            final current = _quantity;
            if (current > 1) {
              _quantityController.text = (current - 1).toString();
              setState(() {});
              _calculateChange();
            }
          },
          icon: const Icon(Icons.remove),
        ),
        const SizedBox(width: 8),

        // Quantity Input
        Expanded(
          child: TextFormField(
            controller: _quantityController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              labelText: 'Jumlah',
              suffixText: _selectedItem?.unit ?? 'pcs',
            ),
            validator: (value) {
              final error = Validators.positiveQuantity(value, 'Jumlah');
              if (error != null) return error;

              if (_selectedItem != null) {
                final qty = int.tryParse(value ?? '') ?? 0;
                if (qty > _selectedItem!.stock) {
                  return 'Stok tidak cukup';
                }
              }
              return null;
            },
            onChanged: (value) {
              setState(() {});
              _calculateChange();
            },
          ),
        ),
        const SizedBox(width: 8),

        // Increase Button
        IconButton.filled(
          onPressed: () {
            final current = _quantity;
            final maxStock = _selectedItem?.stock ?? 999;
            if (current < maxStock) {
              _quantityController.text = (current + 1).toString();
              setState(() {});
              _calculateChange();
            }
          },
          icon: const Icon(Icons.add),
        ),
      ],
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
            theme,
            label: 'Harga per item',
            value: Formatters.formatCurrency(_sellPrice),
          ),
          const SizedBox(height: 8),
          _buildSummaryRow(
            theme,
            label: 'Jumlah',
            value: '$_quantity ${_selectedItem?.unit ?? 'pcs'}',
          ),
          const Divider(height: 24),
          _buildSummaryRow(
            theme,
            label: 'Total',
            value: Formatters.formatCurrency(_totalAmount),
            isBold: true,
          ),
          const SizedBox(height: 8),
          _buildSummaryRow(
            theme,
            label: 'Profit',
            value: Formatters.formatCurrency(_totalProfit),
            valueColor: _totalProfit >= 0 ? AppColors.success : AppColors.error,
          ),
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

  Widget _buildAccountDropdown(BuildContext context, AccountProvider provider) {
    final theme = Theme.of(context);

    return DropdownButtonFormField<Account>(
      value: _selectedAccount,
      decoration: const InputDecoration(
        labelText: 'Pembayaran ke Akun',
        prefixIcon: Icon(Icons.wallet),
      ),
      items: provider.assetAccounts.map((account) {
        return DropdownMenuItem(
          value: account,
          child: Row(
            children: [
              Expanded(child: Text(account.name)),
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
      onChanged: (account) {
        setState(() {
          _selectedAccount = account;
        });
      },
      validator: (value) {
        if (value == null) return 'Pilih akun tujuan';
        return null;
      },
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
