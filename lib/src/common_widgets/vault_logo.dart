import 'package:flutter/material.dart';
import 'package:vault_os/src/constants/app_colors.dart';

class VaultLogo extends StatelessWidget {
  final double size;
  final double borderRadius;
  final double fontSize;
  final bool hasShadow;

  const VaultLogo({
    super.key,
    this.size = 36,
    this.borderRadius = 10,
    this.fontSize = 20,
    this.hasShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: hasShadow ? [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
      child: Center(
        child: Text(
          'V',
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            letterSpacing: -1,
          ),
        ),
      ),
    );
  }
}
