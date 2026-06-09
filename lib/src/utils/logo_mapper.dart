import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class LogoMapper {
  static Widget getLogo(String? method, String? description) {
    final desc = description?.toLowerCase() ?? '';
    final meth = method?.toLowerCase() ?? '';

    if (meth.contains('mpesa') || desc.contains('mpesa')) {
      return _buildLogoBox(Colors.green, 'M');
    }
    if (meth.contains('stripe') || desc.contains('stripe') || meth.contains('card')) {
      return _buildLogoBox(Colors.indigo, 'S');
    }
    if (meth.contains('bank') || desc.contains('bank')) {
      return _buildLogoBox(Colors.blue, 'B');
    }
    if (desc.contains('kcb')) {
      return _buildLogoBox(Colors.green.shade800, 'K');
    }
    if (desc.contains('equity')) {
      return _buildLogoBox(Colors.brown, 'E');
    }
    
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(LucideIcons.arrowUpRight, size: 20, color: Colors.grey),
    );
  }

  static Widget _buildLogoBox(Color color, String letter) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }
}
