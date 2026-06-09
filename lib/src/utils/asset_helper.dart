import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/material.dart';

class AssetHelper {
  static const String _logoPath = 'assets/logos/';
  static const String _defaultBankLogo = '${_logoPath}bank.svg';

  static const Map<String, String> providerLogos = {
    'absa': '${_logoPath}absa.svg',
    'airtel': '${_logoPath}airtel.svg',
    'bank-of-america': '${_logoPath}bank-of-america.svg',
    'bank': '${_logoPath}bank.svg',
    'chase': '${_logoPath}chase.svg',
    'coop': '${_logoPath}coop.svg',
    'dtb': '${_logoPath}dtb.svg',
    'equity': '${_logoPath}equity.svg',
    'family-bank': '${_logoPath}family-bank.svg',
    'im-bank': '${_logoPath}im-bank.svg',
    'kcb': '${_logoPath}kcb.svg',
    'mpesa': '${_logoPath}mpesa.svg',
    'ncba': '${_logoPath}ncba.svg',
    'stanbic': '${_logoPath}stanbic.svg',
    'standard-chartered': '${_logoPath}standard-chartered.svg',
    'stripe': '${_logoPath}stripe.svg',
    'tkash': '${_logoPath}tkash.svg',
  };

  /// Returns an SvgPicture.asset for the given [providerName].
  /// Defaults to 'assets/logos/bank.svg' if the provider name is not found.
  static SvgPicture getLogo(
    String providerName, {
    double? width,
    double? height,
    Color? color,
    BoxFit fit = BoxFit.contain,
  }) {
    final assetPath = providerLogos[providerName.toLowerCase()] ?? _defaultBankLogo;
    
    return SvgPicture.asset(
      assetPath,
      width: width,
      height: height,
      colorFilter: color != null ? ColorFilter.mode(color, BlendMode.srcIn) : null,
      fit: fit,
    );
  }
  
  /// Helper for the main V-Logo
  static SvgPicture getVLogo({
    double? width,
    double? height,
    Color? color,
  }) {
    return SvgPicture.asset(
      'assets/v-logo.svg',
      width: width,
      height: height,
      colorFilter: color != null ? ColorFilter.mode(color, BlendMode.srcIn) : null,
    );
  }
}
