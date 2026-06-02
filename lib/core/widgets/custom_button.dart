import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.leadingIcon,
    this.backgroundColor,
    this.foregroundColor,
    this.fullWidth = true,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? leadingIcon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveBackground = backgroundColor ?? colorScheme.primary;
    final effectiveForeground = foregroundColor ?? colorScheme.onPrimary;

    final buttonChild = AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: isLoading
          ? SizedBox(
              key: const ValueKey('loading'),
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                valueColor: AlwaysStoppedAnimation<Color>(effectiveForeground),
              ),
            )
          : Row(
              key: const ValueKey('content'),
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (leadingIcon != null) ...[
                  Icon(leadingIcon, size: 18),
                  const SizedBox(width: 8),
                ],
                Text(text),
              ],
            ),
    );

    final button = ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: effectiveBackground,
        foregroundColor: effectiveForeground,
        disabledBackgroundColor: colorScheme.primary.withValues(alpha: 0.45),
        disabledForegroundColor: effectiveForeground.withValues(alpha: 0.75),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: effectiveForeground,
        ),
      ),
      child: buttonChild,
    );

    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}
