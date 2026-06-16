import 'package:http_certificate_pinning/http_certificate_pinning.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CertificatePinningService {
  static final String _baseUrl = dotenv.get('VITE_SUPABASE_URL').replaceAll('https://', '');
  
  // Note: In a production app, you should fetch the real SHA-256 fingerprint 
  // of your Supabase project's SSL certificate.
  // You can get it by running: 
  // openssl s_client -connect your-project.supabase.co:443 | openssl x509 -pubkey -noout | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | base64
  static const List<String> _allowedFingerprints = [
    'B9 B8 F4 CE 6C 86 1D 3D D1 67 87 08 FA 4A 40 62 10 7E E7 05 0B 52 82 0F 99 10 50 F1 2E B2 91 00',
  ];

  static Future<bool> checkCertificate() async {
    try {
      final String secure = await HttpCertificatePinning.check(
        serverURL: 'https://$_baseUrl',
        headerHttp: {},
        sha: SHA.SHA256,
        allowedSHAFingerprints: _allowedFingerprints,
        timeout: 30,
      );

      return secure == "CONNECTION_SECURE";
    } catch (e) {
      return false;
    }
  }
}
