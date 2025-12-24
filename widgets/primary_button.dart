import 'package:flutter/material.dart';

/// Tombol utama dengan berbagai variasi
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isExpanded;
  final bool isOutlined;
  final bool isText;
  final bool isDanger;
  final IconData? icon;
  final IconData? trailingIcon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final double borderRadius;
  final TextStyle? textStyle;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isExpanded = true,
    this.isOutlined = false,
    this.isText = false,
    this.isDanger = false,
    this.icon,
    this.trailingIcon,
    this.backgroundColor,
    this.foregroundColor,
    this.padding,
    this.width,
    this.height,
    this.borderRadius = 12,
    this.textStyle,
  });

  /// Factory untuk tombol outlined
  factory PrimaryButton.outlined({
    required String text,
    VoidCallback? onPressed,
    bool isLoading = false,
    bool isExpanded = true,
    IconData? icon,
    Color? foregroundColor,
  }) {
    return PrimaryButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      isExpanded: isExpanded,
      isOutlined: true,
      icon: icon,
      foregroundColor: foregroundColor,
    );
  }

  /// Factory untuk tombol text
  factory PrimaryButton.text({
    required String text,
    VoidCallback? onPressed,
    bool isLoading = false,
    IconData? icon,
    Color? foregroundColor,
  }) {
    return PrimaryButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      isExpanded: false,
      isText: true,
      icon: icon,
      foregroundColor: foregroundColor,
    );
  }

  /// Factory untuk tombol danger
  factory PrimaryButton.danger({
    required String text,
    VoidCallback? onPressed,
    bool isLoading = false,
    bool isExpanded = true,
    IconData? icon,
  }) {
    return PrimaryButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      isExpanded: isExpanded,
      isDanger: true,
      icon: icon,
    );
  }

  /// Factory untuk tombol icon only
  factory PrimaryButton.icon({
    required IconData icon,
    VoidCallback? onPressed,
    bool isLoading = false,
    Color? backgroundColor,
    Color? foregroundColor,
    double size = 48,
  }) {
    return PrimaryButton(
      text: '',
      onPressed: onPressed,
      isLoading: isLoading,
      isExpanded: false,
      icon: icon,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      width: size,
      height: size,
      padding: EdgeInsets.zero,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Determine colors
    Color? bgColor = backgroundColor;
    Color? fgColor = foregroundColor;

    if (isDanger) {
      bgColor = theme.colorScheme.error;
      fgColor = theme.colorScheme.onError;
    }

    // Button content
    Widget content = _buildContent(theme, fgColor);

    // Button style
    final buttonPadding = padding ??
        EdgeInsets.symmetric(
          horizontal: icon != null || trailingIcon != null ? 20 : 24,
          vertical: 14,
        );

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius),
    );

    // Build button based on type
    Widget button;

    if (isText) {
      button = TextButton(
        onPressed: isLoading ? null : onPressed,
        style: TextButton.styleFrom(
          foregroundColor: fgColor ?? theme.colorScheme.primary,
          padding: buttonPadding,
          shape: shape,
        ),
        child: content,
      );
    } else if (isOutlined) {
      button = OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: fgColor ?? theme.colorScheme.primary,
          padding: buttonPadding,
          shape: shape,
          side: BorderSide(
            color: fgColor ?? theme.colorScheme.primary,
          ),
        ),
        child: content,
      );
    } else {
      button = ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor ?? theme.colorScheme.primary,
          foregroundColor: fgColor ?? theme.colorScheme.onPrimary,
          padding: buttonPadding,
          shape: shape,
          elevation: 0,
        ),
        child: content,
      );
    }

    // Apply size constraints
    if (width != null || height != null) {
      button = SizedBox(
        width: width,
        height: height,
        child: button,
      );
    }

    // Expand if needed
    if (isExpanded) {
      return SizedBox(
        width: double.infinity,
        child: button,
      );
    }

    return button;
  }

  Widget _buildContent(ThemeData theme, Color? fgColor) {
    if (isLoading) {
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            fgColor ?? (isOutlined || isText
                ? theme.colorScheme.primary
                : theme.colorScheme.onPrimary),
          ),
        ),
      );
    }

    final textWidget = text.isNotEmpty
        ? Text(
            text,
            style: textStyle ??
                const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
          )
        : null;

    if (icon != null && textWidget != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          textWidget,
          if (trailingIcon != null) ...[
            const SizedBox(width: 8),
            Icon(trailingIcon, size: 20),
          ],
        ],
      );
    }

    if (icon != null) {
      return Icon(icon, size: 24);
    }

    if (textWidget != null && trailingIcon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          textWidget,
          const SizedBox(width: 8),
          Icon(trailingIcon, size: 20),
        ],
      );
    }

    return textWidget ?? const SizedBox.shrink();
  }
}

/// Floating Action Button dengan loading state
class PrimaryFAB extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isExtended;
  final String? label;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final String? tooltip;

  const PrimaryFAB({
    super.key,
    required this.icon,
    this.onPressed,
    this.isLoading = false,
    this.isExtended = false,
    this.label,
    this.backgroundColor,
    this.foregroundColor,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isExtended && label != null) {
      return FloatingActionButton.extended(
        onPressed: isLoading ? null : onPressed,
        backgroundColor: backgroundColor ?? theme.colorScheme.primary,
        foregroundColor: foregroundColor ?? theme.colorScheme.onPrimary,
        tooltip: tooltip,
        icon: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    foregroundColor ?? theme.colorScheme.onPrimary,
                  ),
                ),
              )
            : Icon(icon),
        label: Text(label!),
      );
    }

    return FloatingActionButton(
      onPressed: isLoading ? null : onPressed,
      backgroundColor: backgroundColor ?? theme.colorScheme.primary,
      foregroundColor: foregroundColor ?? theme.colorScheme.onPrimary,
      tooltip: tooltip,
      child: isLoading
          ? SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  foregroundColor ?? theme.colorScheme.onPrimary,
                ),
              ),
            )
          : Icon(icon),
    );
  }
}
