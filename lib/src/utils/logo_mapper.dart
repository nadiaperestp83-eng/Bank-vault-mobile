import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../constants/app_colors.dart';

class LogoMapper {
  static Widget getLogo(String? method, String? description) {
    final desc = description?.toLowerCase() ?? '';
    final meth = method?.toLowerCase() ?? '';

    String? logoPath;
    Color? fallbackColor;

    if (meth.contains('mpesa') || desc.contains('mpesa')) {
      logoPath = 'assets/logos/mpesa.svg';
      fallbackColor = Colors.green;
    } else if (meth.contains('kcb') || desc.contains('kcb')) {
      logoPath = 'assets/logos/kcb.svg';
      fallbackColor = Colors.green.shade800;
    } else if (meth.contains('absa') || desc.contains('absa')) {
      logoPath = 'assets/logos/absa.svg';
      fallbackColor = Colors.red;
    } else if (meth.contains('equity') || desc.contains('equity')) {
      logoPath = 'assets/logos/equity.svg';
      fallbackColor = Colors.brown;
    } else if (meth.contains('co-op') || meth.contains('coop') || desc.contains('coop')) {
      logoPath = 'assets/logos/coop.svg';
      fallbackColor = Colors.green.shade900;
    } else if (meth.contains('chase') || desc.contains('chase')) {
      logoPath = 'assets/logos/chase.svg';
      fallbackColor = Colors.blue.shade900;
    } else if (meth.contains('stanbic') || desc.contains('stanbic')) {
      logoPath = 'assets/logos/stanbic.svg';
      fallbackColor = Colors.blue;
    } else if (meth.contains('standard chartered') || desc.contains('standard chartered')) {
      logoPath = 'assets/logos/standard-chartered.svg';
      fallbackColor = Colors.blue.shade700;
    } else if (meth.contains('ncba') || desc.contains('ncba')) {
      logoPath = 'assets/logos/ncba.svg';
      fallbackColor = Colors.red.shade900;
    } else if (meth.contains('dtb') || desc.contains('dtb')) {
      logoPath = 'assets/logos/dtb.svg';
      fallbackColor = Colors.red;
    } else if (meth.contains('family bank') || desc.contains('family bank')) {
      logoPath = 'assets/logos/family-bank.svg';
      fallbackColor = Colors.orange;
    } else if (meth.contains('im bank') || desc.contains('im bank')) {
      logoPath = 'assets/logos/im-bank.svg';
      fallbackColor = Colors.blue;
    } else if (meth.contains('airtel') || desc.contains('airtel')) {
      logoPath = 'assets/logos/airtel.svg';
      fallbackColor = Colors.red;
    } else if (meth.contains('tkash') || desc.contains('tkash')) {
      logoPath = 'assets/logos/tkash.svg';
      fallbackColor = Colors.green;
    } else if (meth.contains('bank of america') || desc.contains('bank of america')) {
      logoPath = 'assets/logos/bank-of-america.svg';
      fallbackColor = Colors.blue.shade800;
    } else if (meth.contains('stripe') || desc.contains('stripe') || meth.contains('card')) {
      logoPath = 'assets/logos/stripe.svg';
      fallbackColor = Colors.indigo;
    } else if (meth.contains('bank') || desc.contains('bank')) {
      logoPath = 'assets/logos/bank.svg';
      fallbackColor = Colors.blue;
    }

    if (logoPath != null) {
      return Container(
        width: 40,
        height: 40,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (fallbackColor ?? Colors.grey).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: SvgPicture.asset(
          logoPath,
          placeholderBuilder: (context) => Icon(LucideIcons.landmark, color: fallbackColor, size: 20),
        ),
      );
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
}
