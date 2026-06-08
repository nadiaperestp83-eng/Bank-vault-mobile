import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:vault_os/src/constants/app_colors.dart';
import 'package:vault_os/src/constants/app_sizes.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;

  const GlassCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final blur = isDark ? 20.0 : 15.0;
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius ?? 32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: width,
          height: height,
          padding: padding ?? const EdgeInsets.all(AppSizes.p20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(borderRadius ?? 32),
            border: Border.all(
              color: isDark 
                  ? Colors.white.withOpacity(0.08) 
                  : theme.dividerTheme.color ?? theme.colorScheme.outline.withOpacity(0.1),
              width: isDark ? 1.0 : 0.5,
            ),
            boxShadow: isDark ? [
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.03),
                blurRadius: 20,
                spreadRadius: 2,
              )
            ] : [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
