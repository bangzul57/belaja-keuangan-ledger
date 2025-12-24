import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/utils/formatters.dart';
import '../core/utils/validators.dart';

/// Widget input untuk nominal uang dengan formatting otomatis
class MoneyInput extends StatefulWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? helperText;
  final String? prefixText;
  final IconData? prefixIcon;
  final Widget? suffix;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final bool showClearButton;
  final double? maxAmount;
  final double? minAmount;
  final String? Function(String?)? validator;
  final void Function(double)? onChanged;
  final void Function(double)? onSubmitted;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;

  const MoneyInput({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.helperText,
    this.prefixText = 'Rp',
    this.prefixIcon,
    this.suffix,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.showClearButton = true,
    this.maxAmount,
    this.minAmount,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.textInputAction,
  });

  @override
  State<MoneyInput> createState() => _MoneyInputState();
}

class _MoneyInputState extends State<MoneyInput> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isControllerOwned = false;
  bool _isFocusNodeOwned = false;

  @override
  void initState() {
    super.initState();

    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = TextEditingController();
      _isControllerOwned = true;
    }

    if (widget.focusNode != null) {
      _focusNode = widget.focusNode!;
    } else {
      _focusNode = FocusNode();
      _isFocusNodeOwned = true;
    }

    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);

    if (_isControllerOwned) {
      _controller.dispose();
    }
    if (_isFocusNodeOwned) {
      _focusNode.dispose();
    }

    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      // Format saat kehilangan fokus
      _formatValue();
    }
  }

  void _formatValue() {
    final value = Validators.parseAmount(_controller.text);
    if (value > 0) {
      _controller.text = Formatters.formatNumber(value);
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
    }
  }

  double _parseValue() {
    return Validators.parseAmount(_controller.text);
  }

  void _onTextChanged(String text) {
    final value = Validators.parseAmount(text);
    widget.onChanged?.call(value);
  }

  String? _validate(String? value) {
    // Custom validator first
    if (widget.validator != null) {
      final customError = widget.validator!(value);
      if (customError != null) return customError;
    }

    // Min amount validation
    if (widget.minAmount != null) {
      final amount = Validators.parseAmount(value);
      if (amount < widget.minAmount!) {
        return 'Minimal ${Formatters.formatCurrency(widget.minAmount!)}';
      }
    }

    // Max amount validation
    if (widget.maxAmount != null) {
      final amount = Validators.parseAmount(value);
      if (amount > widget.maxAmount!) {
        return 'Maksimal ${Formatters.formatCurrency(widget.maxAmount!)}';
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextFormField(
      controller: _controller,
      focusNode: _focusNode,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      autofocus: widget.autofocus,
      keyboardType: const TextInputType.numberWithOptions(decimal: false),
      textInputAction: widget.textInputAction ?? TextInputAction.next,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        _ThousandSeparatorFormatter(),
      ],
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: widget.hintText ?? '0',
        helperText: widget.helperText,
        prefixIcon: widget.prefixIcon != null
            ? Icon(widget.prefixIcon)
            : null,
        prefixText: widget.prefixText,
        prefixStyle: TextStyle(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
        suffix: widget.suffix,
        suffixIcon: widget.showClearButton && _controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () {
                  _controller.clear();
                  widget.onChanged?.call(0);
                },
              )
            : null,
      ),
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
      validator: _validate,
      onChanged: _onTextChanged,
      onFieldSubmitted: (value) {
        final amount = Validators.parseAmount(value);
        widget.onSubmitted?.call(amount);
      },
    );
  }
}

/// Formatter untuk menambahkan separator ribuan
class _ThousandSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Remove all non-digits
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (digitsOnly.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // Parse to number and format
    final number = int.tryParse(digitsOnly) ?? 0;
    final formatted = Formatters.formatNumber(number);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Widget untuk input quantity (jumlah)
class QuantityInput extends StatefulWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? unit;
  final int minValue;
  final int? maxValue;
  final bool enabled;
  final bool showButtons;
  final void Function(int)? onChanged;
  final String? Function(String?)? validator;

  const QuantityInput({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.unit,
    this.minValue = 1,
    this.maxValue,
    this.enabled = true,
    this.showButtons = true,
    this.onChanged,
    this.validator,
  });

  @override
  State<QuantityInput> createState() => _QuantityInputState();
}

class _QuantityInputState extends State<QuantityInput> {
  late TextEditingController _controller;
  bool _isOwned = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = TextEditingController(text: widget.minValue.toString());
      _isOwned = true;
    }
  }

  @override
  void dispose() {
    if (_isOwned) {
      _controller.dispose();
    }
    super.dispose();
  }

  int get _currentValue {
    return int.tryParse(_controller.text) ?? widget.minValue;
  }

  void _increment() {
    final newValue = _currentValue + 1;
    if (widget.maxValue == null || newValue <= widget.maxValue!) {
      _controller.text = newValue.toString();
      widget.onChanged?.call(newValue);
    }
  }

  void _decrement() {
    final newValue = _currentValue - 1;
    if (newValue >= widget.minValue) {
      _controller.text = newValue.toString();
      widget.onChanged?.call(newValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showButtons) ...[
          _buildButton(
            icon: Icons.remove,
            onPressed: widget.enabled ? _decrement : null,
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: TextFormField(
            controller: _controller,
            enabled: widget.enabled,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: InputDecoration(
              labelText: widget.labelText,
              hintText: widget.hintText ?? widget.minValue.toString(),
              suffixText: widget.unit,
            ),
            validator: widget.validator ??
                (value) => Validators.positiveQuantity(value, widget.labelText),
            onChanged: (value) {
              final qty = int.tryParse(value) ?? 0;
              widget.onChanged?.call(qty);
            },
          ),
        ),
        if (widget.showButtons) ...[
          const SizedBox(width: 8),
          _buildButton(
            icon: Icons.add,
            onPressed: widget.enabled ? _increment : null,
          ),
        ],
      ],
    );
  }

  Widget _buildButton({
    required IconData icon,
    VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: 48,
      height: 48,
      child: IconButton.filled(
        onPressed: onPressed,
        icon: Icon(icon),
        style: IconButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
